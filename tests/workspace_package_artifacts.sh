#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { echo "workspace package artifact check failed: $*" >&2; exit 1; }

RELEASE_BIN="src-tauri/target/release/agentdock-workspace"
[[ -x "$RELEASE_BIN" ]] || fail "release binary missing or not executable: $RELEASE_BIN (run npm run tauri:build first)"

mapfile -t APPIMAGES < <(find src-tauri/target/release/bundle/appimage -maxdepth 1 -type f -name '*.AppImage' 2>/dev/null | sort)
mapfile -t DEBS < <(find src-tauri/target/release/bundle/deb -maxdepth 1 -type f -name '*.deb' 2>/dev/null | sort)

(( ${#APPIMAGES[@]} > 0 )) || fail "AppImage artifact missing under src-tauri/target/release/bundle/appimage"
(( ${#DEBS[@]} > 0 )) || fail "deb artifact missing under src-tauri/target/release/bundle/deb"

for artifact in "$RELEASE_BIN" "${APPIMAGES[@]}" "${DEBS[@]}"; do
  [[ -s "$artifact" ]] || fail "artifact is empty: $artifact"
  bytes=$(wc -c < "$artifact")
  if (( bytes < 100000 )); then
    fail "artifact suspiciously small ($bytes bytes): $artifact"
  fi
  printf 'artifact ok: %s (%s bytes)\n' "$artifact" "$bytes"
done

echo "workspace package artifacts ok"
