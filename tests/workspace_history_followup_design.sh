#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { echo "workspace history/followup design check failed: $*" >&2; exit 1; }

DOC="docs/visual-workspace-history-followup-release-hygiene.md"
CHECKLIST="docs/remaining-work-parallel-checklist.md"

[[ -f "$DOC" ]] || fail "design artifact missing"
[[ -f "$CHECKLIST" ]] || fail "parallel checklist missing"

grep -q 'snapshot payload extension' "$DOC" || fail "Lane D decision missing"
grep -q 'No direct mutation of `.agent-work/07_JOBS/CURRENT.md`' "$DOC" || fail "CURRENT.md no-mutation invariant missing"
grep -q 'agentdock job followup --message <text>' "$DOC" || fail "Lane E dedicated followup command missing"
grep -q 'Rejected:' "$DOC" || fail "rejected alternatives missing"
grep -q 'No arbitrary shell UI bridge' "$DOC" || fail "arbitrary shell safety constraint missing"
grep -q 'releaseProof=true' "$DOC" || fail "releaseProof release gate missing"
grep -q 'Commit candidates for this slice are source docs and tests only' "$DOC" || fail "Lane F commit hygiene split missing"
grep -q 'history` must be optional and backward-compatible' "$DOC" || fail "optional history compatibility rule missing"
grep -q 'Disabled states must be explicit' "$DOC" || fail "follow-up disabled-state contract missing"

grep -q 'Decision: first extend the existing read-only snapshot payload' "$CHECKLIST" || fail "checklist missing Lane D decision"
grep -q 'Decision: dedicated `agentdock job followup --message <text>`' "$CHECKLIST" || fail "checklist missing Lane E decision"
grep -q 'release-ready/90%+/QA GO still requires native live-click PASS' "$CHECKLIST" || fail "checklist missing release wording rule"
grep -q 'Worker 3: Lane D history/inspector design/tests plus Lane E CEO follow-up controlled-action architecture and Lane F commit/release hygiene synthesis' "$CHECKLIST" || fail "current Worker 3 ownership row missing"

# Source bridge must remain narrow while this design-only slice is pending runtime implementation.
python3 - <<'PY'
from pathlib import Path
src = Path('src-tauri/src/lib.rs').read_text(encoding='utf-8')
prod = src.split('#[cfg(test)]', 1)[0]
compact = ''.join(prod.split())
expected = 'tauri::generate_handler![workspace_snapshot,agentdock_job_create]'
if expected not in compact:
    raise SystemExit('Tauri handler is no longer limited to snapshot + job_create')
for forbidden in ['job_followup', 'job_finish', 'job_report', 'broadcast', 'recruit', 'write_file', 'remove_file']:
    if forbidden in prod:
        raise SystemExit(f'forbidden production bridge token found: {forbidden}')
PY

echo "workspace history/followup design ok"
