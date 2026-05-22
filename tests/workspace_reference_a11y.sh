#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { echo "workspace reference a11y test failed: $*" >&2; exit 1; }

[[ -f src-ui/scene/DenseRoleNavigator.tsx ]] || fail "dense navigator missing"
[[ -f src-ui/scene/RoleStation.tsx ]] || fail "role station missing"
[[ -f src-ui/scene/SceneInspector.tsx ]] || fail "scene inspector missing"
[[ -f tests/fixtures/workspace/dense-20-roles.json ]] || fail "dense-20 fixture missing"
[[ -f tests/fixtures/workspace/dense-50-roles.json ]] || fail "dense-50 fixture missing"

python3 tests/fixtures/workspace/validate_workspace_fixtures.py

grep -q 'aria-label="Search roles' src-ui/scene/DenseRoleNavigator.tsx || fail "role search must have explicit aria-label"
grep -q 'placeholder="Search roles' src-ui/scene/DenseRoleNavigator.tsx || fail "role search placeholder missing"
grep -q 'aria-pressed' src-ui/scene/DenseRoleNavigator.tsx || fail "filter buttons must expose pressed state"
grep -q 'aria-label={`Show' src-ui/scene/DenseRoleNavigator.tsx || fail "filter buttons need descriptive aria-label"
grep -q 'visibleCount' src-ui/scene/DenseRoleNavigator.tsx || fail "dense navigator must expose visible role count"

grep -q 'type="button"' src-ui/scene/RoleStation.tsx || fail "role station must be keyboard button"
grep -q 'aria-label={role.accessibleName}' src-ui/scene/RoleStation.tsx || fail "role station must expose derived accessible name"
grep -q 'aria-pressed={selected}' src-ui/scene/RoleStation.tsx || fail "role station must expose selected state"
grep -q 'tabIndex=' src-ui/scene/RoleStation.tsx || fail "role station focus order must be explicit for dense scenes"

grep -q 'role="tablist"' src-ui/scene/SceneInspector.tsx || fail "inspector tabs must expose tablist role"
grep -q 'aria-selected={activeTab ===' src-ui/scene/SceneInspector.tsx || fail "inspector selected tab missing"
grep -q 'aria-label="Read-only task cards"' src-ui/scene/SceneInspector.tsx || fail "task list a11y label missing"

grep -q ':focus-visible' src-ui/styles.css || fail "visible keyboard focus CSS missing"
grep -q 'prefers-reduced-motion' src-ui/styles.css || fail "reduced motion CSS missing"
grep -q 'dense-role-navigator' src-ui/styles.css || fail "dense navigator styles missing"
grep -q 'role-station' src-ui/styles.css || fail "role station styles missing"

if grep -R "\[object Object\]\|{ type\|{&#x27;type&#x27;" src-ui/scene src-ui/model src-ui/components >/tmp/agentdock-a11y-raw-object-scan.txt; then
  fail "raw object rendering pattern found in UI source"
fi

python3 - <<'PY'
import json
from pathlib import Path
for name, expected in [('dense-20-roles.json', 20), ('dense-50-roles.json', 50)]:
    data=json.loads(Path('tests/fixtures/workspace', name).read_text())
    assert len(data['roles']) == expected, name
    assert data['layout']['density'] in {'dense','crowded'}, name
    assert data['commands']['mode'] == 'read-only', name
    assert data['commands']['write_bridge_enabled'] is False, name
print('fixture density/a11y contracts ok')
PY

echo "workspace reference a11y ok"
