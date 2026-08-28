#!/usr/bin/env bash
# Rebuild Ari's Communication Device and drop it into public/ari/.
#
# Usage: ./scripts/build-ari.sh
#
# What this does:
#   1. Ensures ~/dev/ari-communication-device/ exists (clones if missing).
#   2. Pulls latest main and installs deps.
#   3. Builds with `--base=/ari/` so asset URLs are subpath-correct.
#   4. Wipes and repopulates austinmcnair.com/public/ari/ with the new dist/.
#
# Ari is a Vite + React SPA. Astro serves public/ verbatim, so
# austinmcnair.com/ari/ resolves to public/ari/index.html.
#
# If Ari ever grows a runtime Gemini API call, that key would need to
# come from either an api/ proxy route on this site or a referrer-locked
# public key -- flag before shipping.
set -euo pipefail

ARI_SRC="${ARI_SRC:-$HOME/dev/ari-communication-device}"
ARI_REPO="https://github.com/almcnair/Ari-s-Communication-Device-.git"
SITE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="$SITE_ROOT/public/ari"

echo "[build-ari] source: $ARI_SRC"
echo "[build-ari] target: $TARGET"

if [ ! -d "$ARI_SRC" ]; then
  echo "[build-ari] cloning $ARI_REPO -> $ARI_SRC"
  git clone "$ARI_REPO" "$ARI_SRC"
else
  echo "[build-ari] pulling latest in $ARI_SRC"
  git -C "$ARI_SRC" pull --ff-only
fi

cd "$ARI_SRC"

# Use npm install (not ci) because the repo doesn't ship a package-lock.json.
echo "[build-ari] installing deps"
npm install --no-audit --no-fund

echo "[build-ari] building with base=/ari/"
npx vite build --base=/ari/

echo "[build-ari] syncing dist -> $TARGET"
rm -rf "$TARGET"
mkdir -p "$TARGET"
cp -R "$ARI_SRC/dist/" "$TARGET/"

echo "[build-ari] done. Files in $TARGET:"
ls -la "$TARGET"
