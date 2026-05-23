#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { echo "workspace job create bridge failed: $*" >&2; exit 1; }

[[ -f src-ui/components/CeoTaskComposer.tsx ]] || fail "CEO task composer missing"
grep -q 'agentdock_job_create' src-ui/App.tsx || fail "App must call only the controlled job-create bridge for CEO task creation"
grep -q 'CEO TASK REQUEST' src-ui/components/CeoTaskComposer.tsx || fail "live-click selector label must remain CEO TASK REQUEST"
grep -q 'Send to CEO' src-ui/components/CeoTaskComposer.tsx || fail "live-click submit selector must remain Send to CEO"
grep -q 'aria-expanded' src-ui/components/CeoTaskComposer.tsx || fail "compact composer expand/collapse must expose aria-expanded"
grep -q 'aria-controls' src-ui/components/CeoTaskComposer.tsx || fail "compact composer expand/collapse must identify the controlled input"
grep -q 'duplicate submit locked' src-ui/components/CeoTaskComposer.tsx || fail "duplicate submit lock safety copy missing"
if grep -q 'rows={4}' src-ui/components/CeoTaskComposer.tsx; then
  fail "CEO task composer must be compact by default, not a 4-row textarea"
fi
python3 - <<'PY'
import re
from pathlib import Path
allowed = {
    'workspace_snapshot',
    'workspace_watch_start',
    'workspace_model',
    'workspace_model_set',
    'agentdock_job_create',
    'agentdock_job_followup',
    'agentdock_team_broadcast',
    'agentdock_role_send',
    'agentdock_recruit_preview',
    'agentdock_recruit_role',
    'agentdock_task_proposal',
    'agentdock_job_report',
    'agentdock_finish_preview',
    'agentdock_job_finish',
}
bad = []
for path in Path('src-ui').rglob('*'):
    if path.suffix not in {'.ts', '.tsx'}:
        continue
    text = path.read_text(encoding='utf-8')
    for match in re.finditer(r"invoke(?:<[^>]+>)?\(\s*['\"]([^'\"]+)['\"]", text):
        command = match.group(1)
        if command not in allowed:
            bad.append(f'{path}:{match.start()}: {command}')
if bad:
    print('unexpected Tauri invoke command(s):')
    print('\n'.join(bad))
    raise SystemExit(1)
print('job-create invoke allowlist ok')
PY

cargo test --manifest-path src-tauri/Cargo.toml fake_agentdock_job_create_uses_single_request_argv -- --nocapture

echo "workspace job create bridge ok"
