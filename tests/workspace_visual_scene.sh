#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { echo "workspace visual scene test failed: $*" >&2; exit 1; }

[[ -f src-ui/model/scene.ts ]] || fail "SceneModel derivation missing"
[[ -f src-ui/model/fixtures.ts ]] || fail "workspace fixtures helper missing"
[[ -f src-ui/scene/OfficeScene.tsx ]] || fail "OfficeScene missing"
[[ -f src-ui/scene/SceneViewport.tsx ]] || fail "SceneViewport missing"
[[ -f src-ui/scene/OfficeZone.tsx ]] || fail "OfficeZone missing"
[[ -f src-ui/scene/RoleStation.tsx ]] || fail "RoleStation missing"
[[ -f src-ui/scene/DenseRoleNavigator.tsx ]] || fail "DenseRoleNavigator missing"
[[ -f src-ui/scene/SceneInspector.tsx ]] || fail "SceneInspector missing"

grep -q 'deriveSceneModel' src-ui/model/scene.ts || fail "SceneModel must derive from snapshot"
grep -q 'readOnly: true' src-ui/model/scene.ts || fail "SceneModel must preserve read-only marker"
grep -q 'activityState' src-ui/model/scene.ts || fail "SceneModel activityState missing"
grep -q 'recentEventLabel' src-ui/model/scene.ts || fail "SceneModel recent event labels missing"
grep -q 'visualUrgency' src-ui/model/scene.ts || fail "SceneModel visual urgency missing"
grep -q 'denseMetadata' src-ui/model/scene.ts || fail "SceneModel dense metadata missing"
grep -q "type VisualWorkspaceMode = 'classic' | 'pixelOffice'" src-ui/model/scene.ts || fail "visual mode union missing"
grep -q 'OfficeScene' src-ui/App.tsx || fail "App must import/render OfficeScene"
grep -q "visualMode === 'pixelOffice'" src-ui/App.tsx || fail "App must mount OfficeScene in pixelOffice mode"
grep -q 'classic-workspace-layout' src-ui/App.tsx || fail "classic fallback path missing"
grep -q 'agentdock.visualWorkspaceMode' src-ui/App.tsx || fail "visual mode must be local UI state only"

grep -q '\.office-scene' src-ui/styles.css || fail "office scene styles missing"
grep -q '\.scene-viewport' src-ui/styles.css || fail "scene viewport styles missing"
grep -q '\.office-zone' src-ui/styles.css || fail "office zone styles missing"
grep -q '\.role-station' src-ui/styles.css || fail "role station styles missing"
grep -q '\.dense-role-navigator' src-ui/styles.css || fail "dense navigator styles missing"
grep -q '\.report-desk-scene' src-ui/styles.css || fail "report desk scene styles missing"
grep -q '\.blocker-desk-scene' src-ui/styles.css || fail "blocker desk scene styles missing"
grep -q '\.final-gate-scene' src-ui/styles.css || fail "final gate scene styles missing"
grep -q '\.reference-top-bar' src-ui/styles.css || fail "reference top status bar styles missing"
grep -q '\.reference-nav-rail' src-ui/styles.css || fail "reference left nav rail styles missing"
grep -q '\.bottom-trust-bar' src-ui/styles.css || fail "reference bottom trust bar styles missing"
grep -q 'Security Nook' src-ui/scene/OfficeScene.tsx || fail "Security Nook read-only surface missing"
grep -q 'BottomTrustBar' src-ui/scene/OfficeScene.tsx || fail "bottom trust bar component missing"
grep -q 'reference-inspector' src-ui/scene/SceneInspector.tsx || fail "reference right inspector missing"
grep -q 'AgentDock Visual Office' src-ui/components/TopHud.tsx || fail "reference product title missing"
grep -q 'write bridge disabled' src-ui/components/TopHud.tsx || fail "write bridge disabled top badge missing"
grep -q 'filterRolesForScene' src-ui/scene/OfficeScene.tsx || fail "OfficeScene must apply search/filter to visible roles"
grep -q 'activeFilter' src-ui/scene/DenseRoleNavigator.tsx || fail "DenseRoleNavigator active filter state missing"
grep -q 'filteredRoleIds' src-ui/scene/OfficeScene.tsx || fail "OfficeScene filtered role id set missing"
grep -q 'activity-' src-ui/scene/AgentSprite.tsx || fail "AgentSprite activity animation classes missing"

grep -q 'prefers-reduced-motion' src-ui/styles.css || fail "reduced motion CSS gate missing"
grep -q 'workspace-native-screenshot-manifest' tests/workspace_native_screenshots.sh || fail "native screenshot harness missing"
grep -q 'releaseProof' tests/workspace_native_screenshots.sh || fail "native screenshot harness must preserve releaseProof gate"
grep -q 'live-normal' tests/workspace_native_screenshots.sh || fail "native screenshot harness missing live-normal state"
grep -q 'dense-20' tests/workspace_native_screenshots.sh || fail "native screenshot harness missing dense-20 state"
grep -q 'dense-50-search-filter' tests/workspace_native_screenshots.sh || fail "native screenshot harness missing dense-50-search-filter state"
grep -q 'keyboard-focus' tests/workspace_native_screenshots.sh || fail "native screenshot harness missing keyboard-focus state"
grep -q 'read-only-security' tests/workspace_native_screenshots.sh || fail "native screenshot harness missing read-only-security state"

python3 tests/fixtures/workspace/validate_workspace_fixtures.py
[[ -f tests/fixtures/workspace/dense-20-roles.json ]] || fail "dense-20 fixture missing"
[[ -f tests/fixtures/workspace/blocker-present.json ]] || fail "blocker-present fixture missing"
[[ -f tests/fixtures/workspace/stale-last-good.json ]] || fail "stale-last-good fixture missing"
[[ -f tests/fixtures/workspace/error-state.json ]] || fail "error-state fixture missing"

if grep -R "invoke<\|@tauri-apps\|workspace_snapshot" src-ui/scene src-ui/model/scene.ts; then
  fail "scene layer must not call Tauri directly"
fi

npm run build

echo "workspace visual scene ok"
