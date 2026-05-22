#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { echo "workspace no-write regression failed: $*" >&2; exit 1; }
TMP="$(mktemp -d)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

manifest() {
  local base="$1" out="$2"
  (cd "$base" && find .agentdock .agent-work \
    -path './.agentdock/state/panes.lock' -prune -o \
    -type f -print0 | sort -z | xargs -0 sha256sum) > "$out"
}

[[ -d .agentdock ]] || fail ".agentdock missing"
[[ -d .agent-work ]] || fail ".agent-work missing"
[[ -f src-tauri/src/lib.rs ]] || fail "src-tauri/src/lib.rs missing"

# Static safety boundary: desktop app is snapshot plus one controlled job-create action.
# Scan production adapter code, not Rust #[cfg(test)] helper setup that legitimately creates temp dirs.
python3 - <<'PY' > "$TMP/lib.production.rs"
from pathlib import Path
src = Path('src-tauri/src/lib.rs').read_text()
marker = '#[cfg(test)]'
if marker in src:
    src = src[:src.index(marker)]
print(src)
PY

compact_lib="$(tr -d '[:space:]' < "$TMP/lib.production.rs")"
grep -q 'workspace_snapshot' "$TMP/lib.production.rs" || fail "workspace_snapshot command missing"
grep -q 'agentdock_job_create' "$TMP/lib.production.rs" || fail "agentdock_job_create command missing"
[[ "$compact_lib" == *'tauri::generate_handler![workspace_snapshot,agentdock_job_create]'* ]] || fail "Tauri invoke handler must expose exactly workspace_snapshot and agentdock_job_create"
if grep -Eq 'generate_handler!\[[^]]*(finish|send|recruit|broadcast|report|task|inbox|write_file|remove_file|control)' "$TMP/lib.production.rs"; then
  fail "Tauri invoke handler exposes forbidden action command"
fi
if grep -Eq 'sh -c|bash -c|/bin/sh|/bin/bash' "$TMP/lib.production.rs"; then
  fail "adapter must not invoke a shell"
fi
if grep -Eq 'job_report|job_finish|job_send|broadcast|recruit|inbox|write_bridge|write_file|remove_file|OpenOptions|File::create|std::fs::write' "$TMP/lib.production.rs"; then
  fail "adapter appears to expose write/control capability"
fi
if grep -R --line-number --exclude-dir=node_modules --exclude-dir=dist --exclude-dir=target -E 'write_bridge_enabled[[:space:]]*[:=][[:space:]]*true|writeBridgeEnabled[[:space:]]*[:=][[:space:]]*true' src-ui src-tauri/src 2>/dev/null; then
  fail "write bridge enabled flag found"
fi

manifest "$ROOT" "$TMP/before.sha256"
./bin/agentdock workspace snapshot --json --project "$ROOT" > "$TMP/snapshot.json"
python3 -m json.tool "$TMP/snapshot.json" >/dev/null
manifest "$ROOT" "$TMP/after.sha256"
if ! diff -u "$TMP/before.sha256" "$TMP/after.sha256" > "$TMP/no-write.diff"; then
  cat "$TMP/no-write.diff" >&2
  fail "snapshot/view operation modified .agentdock or .agent-work"
fi

echo "workspace desktop no-write ok"
