#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { echo "workspace visual scene test failed: $*" >&2; exit 1; }

[[ -f src-ui/model/scene.ts ]] || fail "SceneModel derivation missing"
[[ -f src-ui/model/emptySnapshot.ts ]] || fail "workspace empty-state helper missing"
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

python3 - <<'PY'
from pathlib import Path
app = Path('src-ui/App.tsx').read_text(encoding='utf-8')
mainframe_idx = app.find('workspace-mainframe')
sidecar_idx = app.find('workspace-sidecar')
stage_idx = app.find('workspace-stage')
scene_idx = app.find('<OfficeScene')
classic_idx = app.find('classic-workspace-layout')
if scene_idx < 0:
    raise SystemExit('OfficeScene render call missing')
if mainframe_idx < 0 or sidecar_idx < 0 or stage_idx < 0:
    raise SystemExit('mainframe, sidecar, and stage layout landmarks are required')
if not (mainframe_idx < sidecar_idx < stage_idx < scene_idx):
    raise SystemExit('controls must live in a sidecar before the visual stage, not as overlays')
command_idx = app.find('ceo-command-center')
composer_idx = app.find('<CeoTaskComposer')
if command_idx < 0 or composer_idx < 0:
    raise SystemExit('primary CEO command center/composer missing')
if not (command_idx < mainframe_idx and command_idx < composer_idx < mainframe_idx):
    raise SystemExit('CEO task composer must stay in the primary command center above the workspace')
for marker in ['<WorkspaceStatusCard', '<OperatorGuidePanel', '<FacilitationTimeline', '<TeamActivityPanel', '<ActionAuditPanel', '<JobHistoryPanel', '<InterventionPanel']:
    idx = app.find(marker)
    if idx < 0:
        raise SystemExit(f'{marker} missing from sidecar')
    if not (sidecar_idx < idx < stage_idx):
        raise SystemExit(f'{marker} must stay inside the non-overlapping sidecar before workspace stage')
if classic_idx < 0 or not (stage_idx < classic_idx):
    raise SystemExit('classic fallback must stay inside the workspace stage')
if app.find('workspace-command-strip') >= 0:
    raise SystemExit('legacy command strip must not return; it caused scene crowding')
print('sidecar-stage render order contract ok')
PY

grep -q '\.workspace-mainframe' src-ui/styles.css || fail "workspace mainframe styles missing"
grep -q '\.workspace-sidecar' src-ui/styles.css || fail "workspace sidecar styles missing"
grep -q '\.snapshot-control-card' src-ui/styles.css || fail "snapshot control card styles missing"
grep -q '\.office-zone-grid' src-ui/styles.css || fail "non-overlapping office zone grid missing"
grep -q '\.office-status-grid' src-ui/styles.css || fail "non-overlapping office status grid missing"
for room_map in command-office-map mission-board-map product-bay-map engineering-bay-map quality-bay-map delivery-bay-map; do
  [[ -f "src-ui/assets/room-maps/${room_map}.png" ]] || fail "room map asset missing: ${room_map}"
  grep -q "${room_map}.png" src-ui/styles.css || fail "room map CSS binding missing: ${room_map}"
done
[[ -f src-ui/assets/source-tiles/opengameart-office-space-tileset.png ]] || fail "downloaded office space source tileset missing"
[[ -f src-ui/assets/source-tiles/opengameart-office-8x8-tileset.png ]] || fail "downloaded office 8x8 source tileset missing"
[[ -f docs/licenses/visual-office-room-map-assets.md ]] || fail "room map asset license notes missing"
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
grep -q '안전 구역' src-ui/scene/OfficeScene.tsx || fail "safe read-only surface missing"
grep -q 'BottomTrustBar' src-ui/scene/OfficeScene.tsx || fail "bottom trust bar component missing"
grep -q 'reference-inspector' src-ui/scene/SceneInspector.tsx || fail "reference right inspector missing"
grep -q 'AgentDock Visual Office' src-ui/components/TopHud.tsx || fail "reference product title missing"
grep -q '안전 모드' src-ui/components/TopHud.tsx || fail "safe mode top badge missing"
grep -q 'filterRolesForScene' src-ui/scene/OfficeScene.tsx || fail "OfficeScene must apply search/filter to visible roles"
grep -q 'activeFilter' src-ui/scene/DenseRoleNavigator.tsx || fail "DenseRoleNavigator active filter state missing"
grep -q 'onSectionChange' src-ui/scene/DenseRoleNavigator.tsx || fail "DenseRoleNavigator section click handler missing"
grep -q 'selectNavSection' src-ui/scene/OfficeScene.tsx || fail "OfficeScene section navigation mapping missing"
grep -q 'TeamActivityPanel' src-ui/App.tsx || fail "team activity panel missing from app"
grep -q 'WorkspaceStatusCard' src-ui/App.tsx || fail "user-facing workspace status card missing from app"
if grep -q 'LiveRefreshPanel\|Live sync\|감시 불가\|파일 변경 시 자동 갱신' src-ui/App.tsx src-ui/styles.css; then
  fail "technical live sync status must stay hidden from the user UI"
fi
grep -q 'OperatorGuidePanel' src-ui/App.tsx || fail "operator guide panel missing from app"
grep -q 'filteredRoleIds' src-ui/scene/OfficeScene.tsx || fail "OfficeScene filtered role id set missing"
grep -q 'activity-' src-ui/scene/AgentSprite.tsx || fail "AgentSprite activity animation classes missing"
grep -q 'work-tool' src-ui/scene/AgentSprite.tsx || fail "AgentSprite work tool overlay missing"
grep -q 'motion-trail' src-ui/scene/AgentSprite.tsx || fail "AgentSprite motion trail missing"
grep -q 'spritePace' src-ui/styles.css || fail "sprite movement keyframes missing"
grep -q 'workspace-status-card' src-ui/styles.css || fail "workspace status card styles missing"
grep -q 'operator-guide-panel' src-ui/styles.css || fail "operator guide styles missing"

grep -q 'prefers-reduced-motion' src-ui/styles.css || fail "reduced motion CSS gate missing"
grep -q 'workspace-native-screenshot-manifest' tests/workspace_native_screenshots.sh || fail "native screenshot harness missing"
grep -q 'releaseProof' tests/workspace_native_screenshots.sh || fail "native screenshot harness must preserve releaseProof gate"
grep -q 'live-normal' tests/workspace_native_screenshots.sh || fail "native screenshot harness missing live-normal state"
grep -q 'final-ready' tests/workspace_native_screenshots.sh || fail "native screenshot harness missing final-ready state"
grep -q 'dense-20' tests/workspace_native_screenshots.sh || fail "native screenshot harness missing dense-20 state"
grep -q 'dense-50-search-filter' tests/workspace_native_screenshots.sh || fail "native screenshot harness missing dense-50-search-filter state"
grep -q 'live-click-filled' tests/workspace_native_screenshots.sh || fail "native screenshot harness missing live-click-filled review state"
grep -q 'keyboard-focus' tests/workspace_native_screenshots.sh || fail "native screenshot harness missing keyboard-focus state"
grep -q 'read-only-security' tests/workspace_native_screenshots.sh || fail "native screenshot harness missing read-only-security state"
[[ -f tests/workspace_native_contact_sheet.sh ]] || fail "native screenshot contact sheet generator missing"

if python3 - <<'PY'
from pathlib import Path
css = Path('src-ui/styles.css').read_text(encoding='utf-8')
blocks = []
start = 0
while True:
    idx = css.find('.refresh-row', start)
    if idx < 0:
        break
    end = css.find('}', idx)
    blocks.append(css[idx:end])
    start = idx + 1
if not blocks:
    raise SystemExit(1)
raise SystemExit(0 if any('position: absolute' in block for block in blocks) else 1)
PY
then
  fail "refresh controls must not be a floating overlay over the office scene"
fi

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
