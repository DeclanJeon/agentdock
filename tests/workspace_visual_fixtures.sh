#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { echo "workspace visual fixtures test failed: $*" >&2; exit 1; }

[[ -f src-ui/model/scene.ts ]] || fail "SceneModel selector module missing"
[[ -f src-ui/model/fixtures.ts ]] || fail "demo/fixture module missing"
[[ -f src-ui/scene/OfficeScene.tsx ]] || fail "OfficeScene missing"
[[ -f src-ui/scene/OfficeZone.tsx ]] || fail "OfficeZone missing"
[[ -f src-ui/scene/RoleStation.tsx ]] || fail "RoleStation missing"
[[ -f src-ui/scene/AgentSprite.tsx ]] || fail "AgentSprite missing"
[[ -f src-ui/scene/MissionBoard.tsx ]] || fail "MissionBoard missing"
[[ -f src-ui/scene/ReportDeskScene.tsx ]] || fail "ReportDeskScene missing"
[[ -f src-ui/scene/BlockerDeskScene.tsx ]] || fail "BlockerDeskScene missing"
[[ -f src-ui/scene/FinalGateScene.tsx ]] || fail "FinalGateScene missing"
[[ -f src-ui/scene/DenseRoleNavigator.tsx ]] || fail "DenseRoleNavigator missing"
[[ -f src-ui/scene/SceneInspector.tsx ]] || fail "SceneInspector missing"
[[ -f src-ui/assets/pixelOfficeManifest.ts ]] || fail "typed pixel office manifest missing"

grep -q 'export interface SceneModel' src-ui/model/scene.ts || fail "SceneModel interface missing"
grep -q 'deriveSceneModel' src-ui/model/scene.ts || fail "deriveSceneModel selector missing"
grep -q 'deriveRoleArchetype' src-ui/model/scene.ts || fail "role archetype selector missing"
grep -q 'deriveRoleZone' src-ui/model/scene.ts || fail "role zone selector missing"
grep -q 'deriveAccessibleName' src-ui/model/scene.ts || fail "accessible-name selector missing"
grep -q "'command'.*'mission'.*'build'.*'design'.*'qa'.*'report'.*'blocker'.*'bench'.*'utility'" src-ui/model/scene.ts || fail "required zone ids missing from scene model"
grep -q 'reportDesk:.*slots' src-ui/model/scene.ts || fail "report desk slots missing from scene model"
grep -q 'blockerDesk:.*cards' src-ui/model/scene.ts || fail "blocker desk cards missing from scene model"
grep -q 'finalGate:' src-ui/model/scene.ts || fail "final gate state missing from scene model"
grep -q 'readOnly: true' src-ui/model/scene.ts || fail "scene meta must preserve read-only flag"

grep -q 'visualWorkspaceMode' src-ui/App.tsx || fail "App missing URL/local visual workspace mode switch"
grep -q 'agentdock.visualWorkspaceMode' src-ui/App.tsx || fail "App mode switch must be localStorage-only local UI state"
grep -q '<OfficeScene' src-ui/App.tsx || fail "OfficeScene not wired into App"
grep -q '<PixelOffice' src-ui/App.tsx || fail "classic fallback not wired into App"

grep -q 'office-scene' src-ui/styles.css || fail "OfficeScene CSS missing"
grep -q 'scene-viewport' src-ui/styles.css || fail "SceneViewport CSS missing"
grep -q 'office-zone' src-ui/styles.css || fail "OfficeZone CSS missing"
grep -q 'role-station' src-ui/styles.css || fail "RoleStation CSS missing"
grep -q 'prefers-reduced-motion' src-ui/styles.css || fail "reduced-motion CSS missing"

if grep -R "\[object Object\]\|{ type\|{&#x27;type&#x27;" src-ui/scene src-ui/model/scene.ts src-ui/styles.css >/tmp/agentdock-visual-raw-scan.txt; then
  fail "normal scene UI appears to contain raw object rendering patterns"
fi

if grep -R "recruit\|send message\|job report\|job finish\|write bridge\|arbitrary shell" src-ui/scene src-ui/model/scene.ts | grep -vi 'read-only\|No role\|report needed' >/tmp/agentdock-visual-control-scan.txt; then
  fail "scene appears to expose mutation/control vocabulary"
fi

echo "workspace visual fixtures ok"
