#!/usr/bin/env bash
# post-push-health-check.sh
#
# Verify that both production hostnames for austinmcnair.com are serving the
# same fresh deployment after a `git push origin main`.
#
# Root of why this exists: on 2026-07-19 the Vercel alias for
# www.austinmcnair.com decoupled from the apex domain's alias. For ten days,
# every push updated `austinmcnair.com` but left `www.austinmcnair.com` frozen
# on a stale deployment. If it drifts again, this script catches it in seconds
# instead of "the following Tuesday, when Austin notices the old email is
# still showing on the URL he actually browses to."
#
# Usage:
#   ./scripts/post-push-health-check.sh
#   ./scripts/post-push-health-check.sh --expect "austin@austinmcnair.com"
#   ./scripts/post-push-health-check.sh --path /writing/pm-dashboard
#
# Exit codes:
#   0  both hostnames fresh and (if given) contain expected string
#   1  one or both hostnames are stale (aliases have drifted)
#   2  expected string missing on one or both hostnames
#   3  network / curl failure
#
# When it fails, the fix is almost always:
#   vercel alias ls | grep austinmcnair
#   vercel alias set <newest-deployment-url> www.austinmcnair.com

set -euo pipefail

HOSTS=("austinmcnair.com" "www.austinmcnair.com")
PATH_TO_CHECK="/"
EXPECT_STRING=""
STALE_THRESHOLD_SECONDS=3600   # 1 hour; drift usually shows up as 10+ days

while [[ $# -gt 0 ]]; do
  case "$1" in
    --path)   PATH_TO_CHECK="$2"; shift 2 ;;
    --expect) EXPECT_STRING="$2"; shift 2 ;;
    --stale-threshold) STALE_THRESHOLD_SECONDS="$2"; shift 2 ;;
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

  # Response headers.
  if ! headers=$(curl -sSI --max-time 15 "$url" 2>&1); then
    echo "    ERROR curl -I failed for ${h}"
    exit 3
  fi

  age=$(echo "$headers" | awk 'tolower($1)=="age:" { print $2 }' | tr -d '\r' | head -1)
  lastmod=$(echo "$headers" | awk 'tolower($1)=="last-modified:" { $1=""; print substr($0,2) }' | tr -d '\r' | head -1)
  vcache=$(echo "$headers" | awk 'tolower($1)=="x-vercel-cache:" { print $2 }' | tr -d '\r' | head -1)

  echo "${age:-0}"   > "${STATE_DIR}/age_${key}"
  printf '%s' "${lastmod:-unknown}" > "${STATE_DIR}/lastmod_${key}"

  echo "    age=${age:-0}s  cache=${vcache:-?}  last-modified=${lastmod:-unknown}"

  # Body check when --expect is provided.
  if [[ -n "$EXPECT_STRING" ]]; then
    if ! body=$(curl -sS --max-time 15 "$url" 2>&1); then
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

# Drift between hostnames: last-modified should match within one build cycle.
lm_apex=$(cat "${STATE_DIR}/lastmod_$(host_key austinmcnair.com)")
lm_www=$(cat "${STATE_DIR}/lastmod_$(host_key www.austinmcnair.com)")
if [[ "$lm_apex" != "$lm_www" ]]; then
  # A one-line diff on last-modified is usually fine (two builds seconds apart);
  # a many-day diff is the exact bug we're guarding against.
  echo "    ⚠️  last-modified differs between hostnames:"
  echo "         apex: $lm_apex"
  echo "         www : $lm_www"
  echo "       If the dates are days apart, aliases have drifted."
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

if (( fail == 0 )); then
  echo "    ✅ both hostnames green"
  exit 0
fi
exit $fail
