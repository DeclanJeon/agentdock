#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { echo "workspace timeline test failed: $*" >&2; exit 1; }

[[ -f src-ui/model/timeline.ts ]] || fail "timeline model missing"
[[ -f src-ui/components/FacilitationTimeline.tsx ]] || fail "FacilitationTimeline component missing"
grep -q 'deriveFacilitationTimeline' src-ui/model/timeline.ts || fail "timeline selector missing"
grep -q "missing reports" src-ui/model/timeline.ts || fail "missing report blocker note missing"
grep -q "확인 필요 항목이 작업을 막고 있음" src-ui/model/timeline.ts || fail "blocker override logic missing"
grep -q "mode === 'stale'" src-ui/model/timeline.ts || fail "stale fallback mode not handled"
grep -q "mode === 'error'" src-ui/model/timeline.ts || fail "error fallback mode not handled"
grep -q "작업 대기" src-ui/model/timeline.ts || fail "idle/not-connected mode not handled"
grep -q 'FacilitationTimeline' src-ui/App.tsx || fail "timeline not mounted"
grep -q 'aria-label="Facilitation timeline"' src-ui/components/FacilitationTimeline.tsx || fail "timeline aria label missing"
grep -q 'timeline-progress-strip' src-ui/components/FacilitationTimeline.tsx || fail "timeline must render as compact progress strip"
grep -q 'timeline-progress-strip' src-ui/styles.css || fail "compact timeline strip styles missing"
grep -q 'evidenceCount' src-ui/components/FacilitationTimeline.tsx || fail "compact timeline must preserve evidence counts"
grep -q 'step.note' src-ui/components/FacilitationTimeline.tsx || fail "compact timeline must preserve detailed notes in accessible text or disclosure"
if grep -q 'grid-template-columns: repeat(auto-fit, minmax(150px, 1fr))' src-ui/styles.css; then
  fail "timeline must not use the old auto-fit card grid"
fi

python3 - <<'PY'
from pathlib import Path
component = Path('src-ui/components/FacilitationTimeline.tsx').read_text(encoding='utf-8')
for state in ['done', 'active', 'blocked', 'pending']:
    if f'state-{state}' not in component and f'step.state' not in component:
        raise SystemExit(f'timeline component may not preserve {state} state class contract')
print('timeline compact semantic contract ok')
PY

echo "workspace timeline ok"
