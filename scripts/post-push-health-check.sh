#!/usr/bin/env bash
# post-push-health-check.sh
#
# Verify that both production hostnames for austinmcnair.com are serving the
# same fresh deployment after a `git push origin main`.
#
# Root of why this exists: on 2026-07-19 the Vercel alias for
# www.austinmcnair.com decoupled from the apex domain's alias. For ten days,
# every push updated the deployment that `austinmcnair.com` pointed at but
# left `www.austinmcnair.com` frozen on a stale deployment. Because www is
# the canonical URL (apex 308-redirects to www), users browsing to the site
# saw stale content for 10 days.
#
# This script curls both hostnames with -L (follow redirects) so both land
# on the actual served HTML, then compares last-modified. If they diverge,
# --auto-fix runs `vercel alias set <newest> www.austinmcnair.com` and
# re-verifies.
#
# Usage:
#   ./scripts/post-push-health-check.sh
#   ./scripts/post-push-health-check.sh --expect "austin@austinmcnair.com"
#   ./scripts/post-push-health-check.sh --path /writing/pm-dashboard
#   ./scripts/post-push-health-check.sh --auto-fix
#
# --auto-fix will re-run `vercel alias set <newest-deployment>
# www.austinmcnair.com` when the divergence check fails, then re-poll
# until both hostnames align. This is a workaround for a real Vercel
# project misconfig that should be fixed in the dashboard — see the
# 2026-07-28 memory entry for the diagnosis.
#
# Exit codes:
#   0  both hostnames fresh and (if given) contain expected string
#   1  one or both hostnames are stale (both frozen — no deploy happened)
#   2  expected string missing on one or both hostnames
#   3  network / curl failure
#   4  hostnames diverged (alias-drift bug: apex updated, www did not)
#
# When it fails, the fix is almost always:
#   vercel alias ls | grep austinmcnair
#   vercel alias set <newest-deployment-url> www.austinmcnair.com

set -euo pipefail

HOSTS=("austinmcnair.com" "www.austinmcnair.com")
PATH_TO_CHECK="/"
EXPECT_STRING=""
STALE_THRESHOLD_SECONDS=3600   # 1 hour; drift usually shows up as 10+ days
AUTO_FIX=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --path)   PATH_TO_CHECK="$2"; shift 2 ;;
    --expect) EXPECT_STRING="$2"; shift 2 ;;
    --stale-threshold) STALE_THRESHOLD_SECONDS="$2"; shift 2 ;;
    --auto-fix) AUTO_FIX=1; shift ;;
    -h|--help)
      grep -E '^# ' "$0" | sed 's/^# //'
      exit 0
      ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

CB="cb=$RANDOM$RANDOM"

# macOS ships bash 3.2, no associative arrays; use per-host state files.
STATE_DIR="$(mktemp -d -t austinmcnair-health.XXXXXX)"
trap 'rm -rf "$STATE_DIR"' EXIT

host_key() { echo "$1" | tr '.' '_'; }

echo "==> Post-push health check"
echo "    path=${PATH_TO_CHECK}"
[[ -n "$EXPECT_STRING" ]] && echo "    expect substring: ${EXPECT_STRING}"
echo

for h in "${HOSTS[@]}"; do
  url="https://${h}${PATH_TO_CHECK}?${CB}"
  key=$(host_key "$h")
  echo "--- ${h}"

  # Response headers. `-L` follows redirects so apex-→-www (308) still
  # lands on real HTML headers, not the redirect stub. We take the LAST
  # HTTP response block's headers via `--write-out` + reading the final
  # response body separately.
  if ! headers=$(curl -sSIL --max-time 15 "$url" 2>&1); then
    echo "    ERROR curl -I failed for ${h}"
    exit 3
  fi

  # When following redirects, curl prints headers for EVERY hop. Grab only
  # the last hop's headers (everything after the final HTTP/x status line).
  final_headers=$(echo "$headers" | awk '
    /^HTTP\// { block=""; next }
    { block = block $0 "\n" }
    END { print block }
  ')

  age=$(echo "$final_headers" | awk 'tolower($1)=="age:" { print $2 }' | tr -d '\r' | head -1)
  lastmod=$(echo "$final_headers" | awk 'tolower($1)=="last-modified:" { $1=""; print substr($0,2) }' | tr -d '\r' | head -1)
  vcache=$(echo "$final_headers" | awk 'tolower($1)=="x-vercel-cache:" { print $2 }' | tr -d '\r' | head -1)

  echo "${age:-0}"   > "${STATE_DIR}/age_${key}"
  printf '%s' "${lastmod:-unknown}" > "${STATE_DIR}/lastmod_${key}"

  echo "    age=${age:-0}s  cache=${vcache:-?}  last-modified=${lastmod:-unknown}"

  # Body check when --expect is provided.
  if [[ -n "$EXPECT_STRING" ]]; then
    if ! body=$(curl -sSL --max-time 15 "$url" 2>&1); then
      echo "    ERROR curl body failed for ${h}"
      exit 3
    fi
    printf '%s' "$body" > "${STATE_DIR}/body_${key}"
    if echo "$body" | grep -qF "$EXPECT_STRING"; then
      echo "    ✅ expected substring found"
    else
      echo "    ❌ expected substring MISSING"
    fi
  fi
  echo
done

# --- Verdicts ---
fail=0

echo "==> Verdict"

# Freshness: age must be under threshold on both hostnames.
for h in "${HOSTS[@]}"; do
  key=$(host_key "$h")
  age=$(cat "${STATE_DIR}/age_${key}")
  if (( age > STALE_THRESHOLD_SECONDS )); then
    echo "    ❌ ${h} is STALE (age=${age}s > ${STALE_THRESHOLD_SECONDS}s)"
    echo "       Alias likely drifted. Run:"
    echo "         vercel alias ls | grep austinmcnair"
    echo "         vercel alias set <newest-deployment>.vercel.app ${h}"
    fail=1
  else
    echo "    ✅ ${h} is fresh (age=${age}s)"
  fi
done

# Drift between hostnames: last-modified should match within a short window.
# The bug we're guarding against: apex updates on every push, www does not.
# When www stays pinned to a previous deployment, its last-modified will be
# minutes to days older than apex's. Fail hard when the gap exceeds the
# drift threshold. Two normal builds land within ~60s of each other on a push,
# so 90s is enough to tolerate real build variance without masking drift.
DRIFT_THRESHOLD_SECONDS=${DRIFT_THRESHOLD_SECONDS:-90}
lm_apex=$(cat "${STATE_DIR}/lastmod_$(host_key austinmcnair.com)")
lm_www=$(cat "${STATE_DIR}/lastmod_$(host_key www.austinmcnair.com)")
if [[ "$lm_apex" != "$lm_www" && "$lm_apex" != "unknown" && "$lm_www" != "unknown" ]]; then
  # Convert HTTP-date to epoch. `date -j -f` is BSD (macOS); `date -d` is GNU.
  if ts_apex=$(date -j -f "%a, %d %b %Y %H:%M:%S GMT" "$lm_apex" +%s 2>/dev/null) \
  && ts_www=$(date -j -f "%a, %d %b %Y %H:%M:%S GMT" "$lm_www" +%s 2>/dev/null); then
    :
  else
    ts_apex=$(date -d "$lm_apex" +%s 2>/dev/null || echo 0)
    ts_www=$(date -d "$lm_www" +%s 2>/dev/null || echo 0)
  fi
  diff=$(( ts_apex > ts_www ? ts_apex - ts_www : ts_www - ts_apex ))
  if (( diff > DRIFT_THRESHOLD_SECONDS )); then
    echo "    ❌ HOSTNAMES DIVERGED (last-modified gap: ${diff}s > ${DRIFT_THRESHOLD_SECONDS}s threshold)"
    echo "         apex: $lm_apex"
    echo "         www : $lm_www"
    echo "       Vercel alias-drift bug: apex updates on push, www does not."

    if (( AUTO_FIX == 1 )); then
      echo
      echo "==> --auto-fix engaged: re-aliasing www to newest production deploy"
      NEWEST=$(vercel list --yes 2>&1 | awk '/Ready.*Production/ && /austinmcnair-/ {print $3; exit}')
      if [[ -z "$NEWEST" ]]; then
        echo "    ❌ could not resolve newest deployment url — aborting auto-fix"
        fail=4
      else
        echo "    newest: $NEWEST"
        if vercel alias set "$NEWEST" www.austinmcnair.com 2>&1 | tail -3; then
          echo "    ✅ alias updated. Waiting 10s then re-checking..."
          sleep 10
          new_lm_www=$(curl -sSIL --max-time 15 "https://www.austinmcnair.com/?cb=$RANDOM$RANDOM" 2>/dev/null | \
                       awk 'tolower($1)=="last-modified:" { $1=""; print substr($0,2) }' | tr -d '\r' | tail -1)
          echo "    www last-modified now: $new_lm_www"
          if [[ "$new_lm_www" == "$lm_apex" ]]; then
            echo "    ✅ auto-fix succeeded — www now aligned with apex"
            # Don't set fail=4; drift is resolved.
          else
            echo "    ⚠️  auto-fix ran but www still doesn't match apex — investigate manually"
            fail=4
          fi
        else
          echo "    ❌ vercel alias set failed — investigate manually"
          fail=4
        fi
      fi
    else
      echo "       Fix:"
      echo "         NEWEST=\$(vercel list --yes 2>&1 | awk '/Ready.*Production/ && /austinmcnair-/ {print \$3; exit}')"
      echo "         vercel alias set \"\$NEWEST\" www.austinmcnair.com"
      echo "       Or re-run this script with --auto-fix."
      fail=4
    fi
  else
    echo "    ✅ hostnames aligned (last-modified gap: ${diff}s ≤ ${DRIFT_THRESHOLD_SECONDS}s)"
  fi
fi

# Expected substring on both.
if [[ -n "$EXPECT_STRING" ]]; then
  for h in "${HOSTS[@]}"; do
    key=$(host_key "$h")
    body_file="${STATE_DIR}/body_${key}"
    if [[ ! -s "$body_file" ]] || ! grep -qF "$EXPECT_STRING" "$body_file"; then
      echo "    ❌ expected substring \"${EXPECT_STRING}\" missing on ${h}"
      fail=2
    fi
  done
fi

echo
if (( fail == 0 )); then
  echo "==> ✅ PASS — both hostnames green"
  exit 0
else
  echo "==> ❌ FAIL (exit=$fail)"
  exit $fail
fi
