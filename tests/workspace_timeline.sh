#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { echo "workspace timeline test failed: $*" >&2; exit 1; }

[[ -f src-ui/model/timeline.ts ]] || fail "timeline model missing"
[[ -f src-ui/components/FacilitationTimeline.tsx ]] || fail "FacilitationTimeline component missing"
grep -q 'deriveFacilitationTimeline' src-ui/model/timeline.ts || fail "timeline selector missing"
grep -q "missing reports" src-ui/model/timeline.ts || fail "missing report blocker note missing"
grep -q "Blocked overlay\|Blocker overrides" src-ui/model/timeline.ts || fail "blocker override logic missing"
grep -q "mode === 'stale'" src-ui/model/timeline.ts || fail "stale fallback mode not handled"
grep -q 'FacilitationTimeline' src-ui/App.tsx || fail "timeline not mounted"
grep -q 'aria-label="Facilitation timeline"' src-ui/components/FacilitationTimeline.tsx || fail "timeline aria label missing"

echo "workspace timeline ok"
