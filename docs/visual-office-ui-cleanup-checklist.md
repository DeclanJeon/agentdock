# Visual Office UI Cleanup Checklist

작성: 2026-05-22 KST  
범위: AgentDock Visual Office / Pixel Office first-screen cleanup  
상태: 작업 전 계획 문서. 구현 완료 또는 release-ready claim 아님.

## Goal

현재 native screenshot 기준 UI는 기능 검증은 통과했지만, `CeoTaskComposer`, `FacilitationTimeline`, `ActionAuditPanel`, `InterventionPanel`이 Visual Office보다 먼저 렌더링되어 첫 화면이 QA/debug console처럼 보인다. 이 체크리스트의 목표는 **Pixel/Visual Office를 첫 화면의 주 UI로 복원하고, 작업 입력/타임라인/감사/개입 기능을 보조 패널로 정리**하는 것이다.

## Non-negotiable constraints

- [x] `write_bridge_enabled=false`를 유지한다.
- [x] 앱 UI에는 broad shell bridge 또는 arbitrary `agentdock <anything>` runner를 추가하지 않는다.
- [x] `agentdock_job_create` 외 action bridge를 추가하지 않는다.
- [x] direct `finish`, direct task-card edit, direct report submit, direct recruit, direct broadcast, direct role-send 버튼을 새로 노출하지 않는다.
- [x] `.agent-work/`, `.agentdock/`, `dist/`, `node_modules/`, `src-tauri/target/`, `tsconfig.tsbuildinfo`는 커밋 대상에서 제외한다.
- [x] release-ready/QA GO를 다시 주장하려면 final matrix 21/21 PASS, native live-click PASS, current-job native `releaseProof=true`를 재확인한다.

## P0 — 기준과 합격선 고정

- [x] 기준 레퍼런스를 확정한다.
  - [x] 1차 기준: 사용자가 제시한 `[Image #1]` 형태의 “Pixel Office가 화면 대부분을 차지하는 UI”.
  - [x] 현재 native screenshot은 before 상태로 보관한다.
- [x] Before/After 비교 세트를 고정한다.
  - [x] `live-normal`
  - [x] `final-ready`
  - [x] `dense-50-search-filter`
  - [x] `live-click-filled`
- [x] visual score 합격선을 정한다.
  - [x] 1차 cleanup: 80점 이상.
  - [x] 최종 polish: 90점 이상.
- [x] 첫 화면 합격 기준을 정한다.
  - [x] 앱 진입 시 Visual Office / OfficeScene이 fold 위에서 최소 60~70% 보인다.
  - [x] composer/timeline/audit/intervention이 OfficeScene을 밀어내지 않는다.

## P0 — 화면 구조 재배치

- [x] `src-ui/App.tsx` render order를 재구성한다.
  - [x] `TopHud`
  - [x] compact command/status strip
  - [x] `OfficeScene` 또는 classic workspace
  - [x] drawer/sidebar/inspector 보조 패널
- [x] `OfficeScene`을 메인 화면 최상위 콘텐츠로 이동한다.
- [x] `CeoTaskComposer`를 full-width 대형 패널에서 compact command bar 또는 Command Office 내부 카드로 축소한다.
- [x] `FacilitationTimeline`을 8개 카드형 패널에서 얇은 progress strip으로 변경한다.
- [x] `ActionAuditPanel`은 기본 접힘 상태로 이동한다.
  - [x] 후보: Inspector tab, bottom drawer, Command Office drawer.
- [x] `InterventionPanel`은 기본 접힘 상태로 이동한다.
  - [x] 후보: Inspector tab, Security Nook, disabled action drawer.
- [x] `Refresh snapshot` floating overlay를 제거한다.
- [x] Refresh control을 TopHud 또는 Inspector 내부로 이동한다.

## P0 — 상태별 UI 회귀 검증

각 상태에서 composer/timeline/HUD가 OfficeScene을 가리지 않는지 확인한다.

- [x] `live-normal`
- [x] `final-ready`
- [x] `dense-50-search-filter`
- [x] `missing-reports`
- [x] `blocker-present`
- [x] `stale-last-good`
- [x] `demo-fallback`
- [x] `error-state`
- [x] `keyboard-focus`
- [x] `reduced-motion`
- [x] `read-only-security`

## P1 — Top HUD 단순화

- [x] `TopHud` chip 개수를 줄인다.
  - [x] 유지: Job, Lifecycle, Reports, Final.
  - [x] 이동: Mode, read-only, Allowed action.
- [x] 긴 Job ID는 truncate 처리한다.
- [x] `write bridge disabled` 문구는 한 번만 보여준다.
- [x] read-only/security copy는 Security Nook 또는 Inspector로 이동한다.
- [x] TopHud 높이가 과도하게 늘어나지 않게 한다.

## P1 — CEO composer UX 개선

- [x] 기본 상태는 1줄 입력 + `Send to CEO` 버튼으로 표시한다.
- [x] 긴 요청 입력은 `Expand` 버튼으로 textarea를 열게 한다.
- [x] `rows={4}` 기본 textarea를 제거하거나 `rows={1~2}`로 축소한다.
- [x] helper text / trust copy를 짧게 축약한다.
- [x] disabled 사유는 버튼 근처에 짧게 표시한다.
- [x] 성공/실패 결과는 compact toast 또는 audit drawer로 이동한다.
- [x] 입력 중/전송 중/전송 후 snapshot refresh 상태가 레이아웃을 밀어내지 않게 한다.

## P1 — Timeline UX 개선

- [x] `Intake → Planning → Team → Tasking → Reports → Final` 형태의 한 줄 strip으로 바꾼다.
- [x] 각 단계는 상태 색상과 count만 노출한다.
- [x] 상세 note는 hover, tooltip, Inspector, drawer 중 하나로 이동한다.
- [x] blocked 상태만 강한 시각 강조를 유지한다.
- [x] done/pending 상태의 border와 chip 노이즈를 줄인다.

## P1 — 접근성 / 키보드

- [x] nav rail focus 가능.
- [x] role station focus 가능.
- [x] report slot focus 가능.
- [x] blocker desk / final gate focus 가능.
- [x] inspector tab focus 가능.
- [x] compact composer expand/collapse가 키보드로 가능.
- [x] focus ring이 dark UI에서 명확히 보인다.
- [x] `prefers-reduced-motion`에서 반복 animation이 꺼진다.
- [x] read-only/security 상태가 색상만으로 전달되지 않는다.

## P1 — 반응형 / 창 크기

- [x] 1920x1080에서 OfficeScene이 첫 화면 주 영역을 차지한다.
- [x] 1440x900에서 OfficeScene이 fold 위에 충분히 보인다.
- [x] 1366x768에서 HUD/composer/timeline이 과도하게 누적되지 않는다.
- [x] 좁은 폭에서 nav / inspector / office가 깨지지 않는다.
- [x] dense-50 상태에서 horizontal overflow가 없다.
- [x] 세로 스크롤이 필요한 경우에도 OfficeScene이 composer보다 먼저 보인다.

## P2 — Visual style 정돈

- [x] 4px 두꺼운 border를 1~2px로 축소한다.
- [x] 큰 radius와 heavy shadow를 줄인다.
- [x] 카드 간 여백을 통일한다.
- [x] font size hierarchy를 재정리한다.
- [x] 색상 token 규칙을 정리한다.
  - [x] green: ready/pass.
  - [x] amber: warning.
  - [x] red: blocker/fail.
  - [x] cyan/blue: active/focus.
- [x] 한글/영문 혼용 규칙을 정한다.
- [x] Pixel Office 섹션 라벨과 HUD 스타일을 통일한다.
- [x] `styles.css`가 더 커질 경우 scene/layout/action CSS 섹션 분리를 검토한다.

## P2 — Inspector / Side panel 재배치

- [x] Mode, read-only, Allowed action을 Security Nook 또는 Inspector로 이동한다.
- [x] Action Audit을 Inspector tab 또는 drawer로 통합한다.
- [x] Intervention controls를 Inspector tab 또는 drawer로 통합한다.
- [x] selected role 정보와 task/report/detail을 우측 패널에 일관되게 배치한다.
- [x] “읽기 전용 / 보안 경계” 정보는 Security Nook 중심으로 표시한다.

## P2 — Screenshot / evidence 개선

- [x] native screenshot에서 OS top bar / Ubuntu dock을 제거하거나 crop한다.
- [x] window-only screenshot capture 방식을 검토한다.
- [x] UI review용 contact sheet 생성 스크립트를 추가한다.
- [x] before/after screenshot 비교 기준을 문서화한다.
- [x] 기본 리뷰 세트 4장을 고정한다.
  - [x] `live-normal`
  - [x] `final-ready`
  - [x] `dense-50-search-filter`
  - [x] `live-click-filled`

## Verification checklist

- [x] `npm run build`
- [x] `bash tests/workspace_visual_scene.sh`
- [x] `bash tests/workspace_visual_fixtures.sh`
- [x] `bash tests/workspace_reference_a11y.sh`
- [x] `bash tests/workspace_timeline.sh`
- [x] `bash tests/workspace_action_audit.sh`
- [x] `bash tests/workspace_desktop_no_write.sh`
- [x] `bash tests/workspace_job_create_bridge.sh`
- [x] native screenshot 4개 상태 재캡처.
- [x] UI contact sheet 생성.
- [x] visual review score 80점 이상.
- [x] 최종 UI 정리 후 release matrix 재실행.

## Completion evidence — 2026-05-23 KST

상태: 체크리스트 항목 구현 및 검증 완료.

Implemented evidence:
- Scene-first hierarchy: `src-ui/App.tsx` renders `TopHud` → compact `.workspace-command-strip` → `OfficeScene`/classic workspace → collapsed auxiliary dock.
- Compact composer: `src-ui/components/CeoTaskComposer.tsx` keeps `CEO TASK REQUEST`, `ceo-task-request`, `Send to CEO`, duplicate-submit lock, and adds keyboard-accessible expand/collapse.
- Compact timeline: `src-ui/components/FacilitationTimeline.tsx` uses `timeline-progress-strip` and preserves state/evidence/note semantics.
- Audit/intervention: `ActionAuditPanel` and `InterventionPanel` are default-collapsed `<details>` panels after the primary workspace.
- HUD/security: `TopHud` is simplified; mode/read-only/allowed action moved to the compact security status strip.
- Screenshot/evidence: native evidence captured under `.agent-work/07_JOBS/JOB-260522190004397678/OUTPUTS/ui-cleanup-native-evidence-2`; cropped review contact sheet generated at `.agent-work/07_JOBS/JOB-260522190004397678/OUTPUTS/ui-cleanup-contact-sheet-2-cropped.png`.
- Visual review: cropped contact sheet manually reviewed against the requested Pixel Office intent; score estimate 86/100, above the 80-point cleanup gate. Remaining polish is aesthetic, not a gate blocker.
- Release proof: `.agent-work/07_JOBS/JOB-260522190004397678/OUTPUTS/ui-cleanup-release-matrix-final2/workspace-release-matrix.json` reports overall PASS.

Verification run:
- `npm run build` — PASS
- `bash tests/workspace_visual_scene.sh` — PASS
- `bash tests/workspace_visual_fixtures.sh` — PASS
- `bash tests/workspace_reference_a11y.sh` — PASS
- `bash tests/workspace_timeline.sh` — PASS
- `bash tests/workspace_action_audit.sh` — PASS
- `bash tests/workspace_desktop_no_write.sh` — PASS
- `bash tests/workspace_job_create_bridge.sh` — PASS
- `npm run tauri:build` — PASS
- `AGENTDOCK_RUN_LIVE_CLICK=1 AGENTDOCK_LIVE_CLICK_DRIVER_CMD='python3 /tmp/agentdock_native_atspi_live_click_driver_no_capture.py' AGENTDOCK_REQUIRE_RELEASE_PROOF=1 ... bash tests/workspace_release_matrix.sh .../ui-cleanup-release-matrix-final2` — PASS
- `git diff --check` — PASS

Notes:
- Raw native screenshots remain uncommitted evidence under `.agent-work/`; contact sheet crops common OS top bar and Ubuntu dock for review while preserving raw release evidence.
- The live-click release gate uses a no-capture AT-SPI driver variant because xdg-desktop-portal screenshot capture opens a Remote Desktop permission dialog that can block the native button action. The live-click test still exercises the native Tauri UI button and sandbox mutation path.
