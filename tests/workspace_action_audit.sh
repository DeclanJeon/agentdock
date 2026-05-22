#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { echo "workspace action audit test failed: $*" >&2; exit 1; }

[[ -f src-ui/model/actionAudit.ts ]] || fail "action audit model missing"
[[ -f src-ui/components/ActionAuditPanel.tsx ]] || fail "ActionAuditPanel missing"
grep -q 'session-local' src-ui/components/ActionAuditPanel.tsx || fail "session-local audit copy missing"
grep -q 'redactText' src-ui/model/actionAudit.ts || fail "audit model must redact previews"
grep -q 'completeJobCreateAudit' src-ui/model/actionAudit.ts || fail "job create audit completion helper missing"
grep -q 'durationMs' src-ui/model/actionAudit.ts || fail "audit model must capture action duration"
grep -q 'durationMs' src-ui/components/ActionAuditPanel.tsx || fail "audit panel must display action duration"
grep -q 'redacted before display' src-ui/components/ActionAuditPanel.tsx || fail "audit panel missing redaction copy"
grep -q 'newAuditAttempt' src-ui/App.tsx || fail "App does not create audit attempts"
grep -q 'completeJobCreateAudit' src-ui/App.tsx || fail "App does not complete audit events"
grep -q 'ActionAuditPanel' src-ui/App.tsx || fail "audit panel not mounted"
grep -q 'InterventionPanel' src-ui/App.tsx || fail "intervention panel not mounted"
if grep -R --line-number -E 'localStorage\.setItem\([^)]*audit|sessionStorage\.setItem\([^)]*audit' src-ui 2>/dev/null; then
  fail "session-local audit must not persist to browser storage"
fi

python3 - <<'PY'
from pathlib import Path
app = Path('src-ui/App.tsx').read_text(encoding='utf-8')
scene_idx = app.find('<OfficeScene')
classic_idx = app.find('classic-workspace-layout')
if scene_idx < 0:
    raise SystemExit('OfficeScene render call missing')
for marker in ['<ActionAuditPanel', '<InterventionPanel']:
    idx = app.find(marker)
    if idx < 0:
        raise SystemExit(f'{marker} render call missing')
    if idx < scene_idx:
        raise SystemExit(f'{marker} renders before OfficeScene; auxiliary panels must not dominate first screen')
    if classic_idx >= 0 and idx < classic_idx:
        raise SystemExit(f'{marker} renders before classic workspace; auxiliary panels must remain secondary')
print('audit/intervention secondary placement contract ok')
PY

python3 - <<'PY'
from pathlib import Path
for name in ['ActionAuditPanel.tsx', 'InterventionPanel.tsx']:
    text = Path('src-ui/components', name).read_text(encoding='utf-8')
    collapsed = '<details' in text or 'aria-expanded' in text
    if not collapsed:
        raise SystemExit(f'{name} must be default-collapsed or expose an accessible collapse control')
print('auxiliary panel collapse contract ok')
PY

python3 - <<'PY'
from pathlib import Path
text = Path('src-ui/components/InterventionPanel.tsx').read_text(encoding='utf-8')
for forbidden in ['agentdock job finish', 'agentdock role send', 'agentdock recruit', 'agentdock broadcast']:
    if forbidden in text:
        raise SystemExit(f'intervention panel exposes forbidden direct command copy: {forbidden}')
print('intervention panel forbidden command copy absent')
PY

echo "workspace action audit ok"
