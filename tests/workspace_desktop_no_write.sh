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

# Static safety boundary: desktop app is snapshot plus fixed-argv controlled actions; no broad shell/write bridge.
# Scan production adapter code, not Rust #[cfg(test)] helper setup that legitimately creates temp dirs.
python3 - <<'PY' > "$TMP/lib.production.rs"
from pathlib import Path
src = Path('src-tauri/src/lib.rs').read_text(errors='replace')
marker = '#[cfg(test)]'
if marker in src:
    src = src[:src.index(marker)]
print(src)
PY

compact_lib="$(tr -d '[:space:]' < "$TMP/lib.production.rs")"
grep -q 'workspace_snapshot' "$TMP/lib.production.rs" || fail "workspace_snapshot command missing"
for handler in workspace_watch_start workspace_model workspace_model_set agentdock_job_create agentdock_job_followup agentdock_team_broadcast agentdock_role_send agentdock_recruit_preview agentdock_recruit_role agentdock_task_proposal agentdock_job_report agentdock_finish_preview agentdock_job_finish; do
  grep -q "$handler" "$TMP/lib.production.rs" || fail "$handler command missing"
done
for handler in workspace_snapshot workspace_watch_start workspace_model workspace_model_set agentdock_job_create agentdock_job_followup agentdock_team_broadcast agentdock_role_send agentdock_recruit_preview agentdock_recruit_role agentdock_task_proposal agentdock_job_report agentdock_finish_preview agentdock_job_finish; do
  [[ "$compact_lib" == *"$handler"* ]] || fail "Tauri invoke handler missing $handler"
done
if grep -Eq 'generate_handler!\[[^]]*(write_file|remove_file|OpenOptions|File::create|std::fs::write)' "$TMP/lib.production.rs"; then
  fail "Tauri invoke handler exposes forbidden broad write command"
fi
if grep -Eq 'sh -c|bash -c|/bin/sh|/bin/bash' "$TMP/lib.production.rs"; then
  fail "adapter must not invoke a shell"
fi
if grep -Eq 'sh -c|bash -c|/bin/sh|/bin/bash|write_file|remove_file|OpenOptions|File::create|std::fs::write' "$TMP/lib.production.rs"; then
  fail "adapter appears to expose shell or broad write capability"
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
