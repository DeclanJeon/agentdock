# Visual Office UI Cleanup Work Order

작성: 2026-05-22 KST  
기반 체크리스트: `docs/visual-office-ui-cleanup-checklist.md`  
범위: AgentDock Visual Office UI cleanup only. 새로운 action bridge 구현 범위 아님.

## Mission

현재 AgentDock Visual Office는 release matrix는 통과했지만, native screenshot 기준 첫 화면에서 대형 composer/timeline/debug 패널이 Visual Office를 밀어내고 있다. 본 작업의 미션은 **Visual Office / Pixel Office를 화면의 주인공으로 복원하고, job create / timeline / audit / intervention 정보를 compact 보조 UI로 재배치**하는 것이다.

## Success criteria

1. 앱 첫 화면에서 OfficeScene이 fold 위의 주 영역을 차지한다.
2. CEO job create는 유지하되 full-width 대형 패널이 아니다.
3. Timeline은 8-card block이 아니라 compact progress strip이다.
4. Action Audit / Intervention은 기본 접힘 상태 또는 Inspector/drawer 내부에 있다.
5. TopHud는 Job/Lifecycle/Reports/Final 중심으로 단순화된다.
6. `write_bridge_enabled=false`와 no arbitrary shell boundary가 유지된다.
7. 기본 4장 screenshot contact sheet에서 visual review score 80점 이상을 받는다.
8. 지정 테스트와 build가 PASS한다.

## Non-goals

- `agentdock_job_create` 외 신규 Tauri action bridge 추가 금지.
- CEO follow-up, recruit, role-send, broadcast, finish, report, task-edit 구현 금지.
- `.agent-work` evidence 파일 커밋 금지.
- release matrix gate를 약화시키는 변경 금지.
- screenshot harness에서 fake/browser proof를 native release proof로 둔갑시키는 변경 금지.

## Primary files

- `src-ui/App.tsx` — render order와 panel placement.
- `src-ui/components/TopHud.tsx` — HUD chip 축소와 refresh 배치.
- `src-ui/components/CeoTaskComposer.tsx` — compact composer / expand UI.
- `src-ui/components/FacilitationTimeline.tsx` — compact progress strip.
- `src-ui/components/ActionAuditPanel.tsx` — drawer/tab 이동 후보.
- `src-ui/components/InterventionPanel.tsx` — drawer/tab 이동 후보.
- `src-ui/scene/OfficeScene.tsx` — 메인 Office UI 보존.
- `src-ui/scene/SceneInspector.tsx` or `src-ui/components/Inspector.tsx` — 보조 정보 이동 후보.
- `src-ui/styles.css` — layout, density, border/shadow/token cleanup.
- `tests/workspace_visual_scene.sh` — visual structure regression.
- `tests/workspace_reference_a11y.sh` — accessibility/static contract.
- `tests/workspace_timeline.sh` — timeline selector contract.
- `tests/workspace_action_audit.sh` — audit contract.
- `tests/workspace_desktop_no_write.sh` — no-write/safety contract.

## Execution plan

### Phase 0 — Baseline capture and guardrails

- [x] Read `docs/visual-office-ui-cleanup-checklist.md` and confirm no non-goal is included in implementation.
- [x] Preserve current state as before evidence.
  - [x] `live-normal`
  - [x] `final-ready`
  - [x] `dense-50-search-filter`
  - [x] `live-click-filled`
- [x] Record current layout issues in a short note or PR body draft.
- [x] Run static guard tests before editing when practical:
  - [x] `bash tests/workspace_desktop_no_write.sh`
  - [x] `bash tests/workspace_job_create_bridge.sh`

### Phase 1 — Shell order and first-screen hierarchy

- [x] Modify `App.tsx` so OfficeScene/classic workspace is the primary content above fold.
- [x] Move composer/timeline/audit/intervention out of the full-width pre-office stack.
- [x] Decide target placement:
  - Recommended: `TopHud` + compact command strip + `OfficeScene` + right/bottom drawer.
- [x] Remove or relocate floating `.refresh-row` overlay.
- [x] Confirm OfficeScene remains visible in `live-normal`, `final-ready`, and `dense-50-search-filter`.

### Phase 2 — Compact CEO composer

- [x] Convert default composer to compact mode.
  - [x] One-line input or short textarea.
  - [x] `Send to CEO` button remains visible.
  - [x] Expand control reveals longer textarea.
- [x] Keep validation, duplicate-submit lock, redacted error handling, and post-create refresh state.
- [x] Move verbose trust copy into tooltip, secondary line, or Security/Inspector area.
- [x] Ensure live-click driver can still target the composer reliably.
- [x] Update tests if they assert old full-width copy/structure.

### Phase 3 — Compact timeline

- [x] Replace card grid with progress strip.
- [x] Show short state/count only in the strip.
- [x] Move long notes to tooltip/drawer/Inspector.
- [x] Preserve blocked/done/active/pending semantics from `deriveFacilitationTimeline`.
- [x] Update `tests/workspace_timeline.sh` only for intended markup/copy changes, not selector logic weakening.

### Phase 4 — HUD and side information cleanup

- [x] Reduce HUD chips to Job, Lifecycle, Reports, Final.
- [x] Truncate long Job IDs.
- [x] Move Mode/read-only/Allowed action to Security Nook or Inspector.
- [x] Ensure read-only/write-disabled status remains unmistakable but not duplicated.
- [x] Keep refresh visible but not floating over content.

### Phase 5 — Visual polish

- [x] Reduce heavy 4px borders where panels are no longer primary.
- [x] Normalize radius, spacing, and shadow.
- [x] Align color roles: green/pass, amber/warn, red/blocker, cyan/focus-active.
- [x] Reduce Korean/English duplicate copy in high-density areas.
- [x] Confirm dense-50 does not overflow horizontally.

### Phase 6 — Screenshot evidence quality

- [x] Generate new native screenshots for the 4 required review states.
- [x] Create a contact sheet for visual review.
- [x] If OS chrome/dock still pollutes screenshots, add a follow-up task for window-only crop. Do not block UI cleanup on crop unless review is impossible.
- [x] Run visual-verdict/manual visual review against `[Image #1]` intent.

## Verification commands

Minimum after implementation:

```bash
npm run build
bash tests/workspace_visual_scene.sh
bash tests/workspace_visual_fixtures.sh
bash tests/workspace_reference_a11y.sh
bash tests/workspace_timeline.sh
bash tests/workspace_action_audit.sh
bash tests/workspace_desktop_no_write.sh
bash tests/workspace_job_create_bridge.sh
git diff --check
```

If native evidence or release wording is updated:

```bash
AGENTDOCK_REQUIRE_RELEASE_PROOF=1 bash tests/workspace_release_matrix.sh \
  .agent-work/07_JOBS/JOB-260522190004397678/OUTPUTS/ui-cleanup-release-matrix
```

Use the full release matrix only after the UI iteration is stable, because it is slower and includes native proof gates.

## Acceptance checklist

- [x] First-screen OfficeScene prominence is restored.
- [x] Composer is compact by default and expandable.
- [x] Timeline is compact by default and still accurately reflects snapshot state.
- [x] Audit/intervention no longer dominate first screen.
- [x] HUD is readable and does not overflow on normal desktop widths.
- [x] Read-only/write-disabled posture is still clear.
- [x] No new broad write/shell bridge exists.
- [x] Required tests pass.
- [x] Before/after screenshots are saved outside commit scope.
- [x] Checklist file is updated with completed items.

## Risk notes

- Moving composer markup may break the native live-click proof if the accessible labels or button name change. Preserve `CEO TASK REQUEST` and `Send to CEO`, or update the driver and rerun live-click proof.
- Hiding safety copy too aggressively can weaken the read-only trust contract. Move safety details, do not delete all safety signaling.
- Timeline compaction must not weaken blocked/missing report semantics. Keep selector tests intact.
- Reducing HUD chips must not remove status information entirely; relocate lower-priority chips to Security/Inspector.

## Suggested commit split

1. `Reshape Visual Office around the scene-first hierarchy`
2. `Compact job-create and timeline controls without widening bridges`
3. `Refresh visual evidence and cleanup checklist status`

Each commit should follow the Lore Commit Protocol from `AGENTS.md`.

## Completion record — 2026-05-23 KST

Status: completed.

Delivered:
- Scene-first Visual Office hierarchy.
- Compact/expandable CEO composer with original live-click selectors preserved.
- Compact facilitation progress strip.
- Collapsed secondary audit/intervention dock.
- Simplified HUD plus relocated security/read-only status.
- Native screenshot evidence, cropped review contact sheet, and release-matrix proof.

Final evidence:
- Contact sheet: `.agent-work/07_JOBS/JOB-260522190004397678/OUTPUTS/ui-cleanup-contact-sheet-2-cropped.png`
- Native manifest: `.agent-work/07_JOBS/JOB-260522190004397678/OUTPUTS/ui-cleanup-native-evidence-2/workspace-native-screenshot-manifest.json`
- Release matrix: `.agent-work/07_JOBS/JOB-260522190004397678/OUTPUTS/ui-cleanup-release-matrix-final2/workspace-release-matrix.json`

All required verification commands passed; no broad write/shell bridge was added.
