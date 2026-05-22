# Remaining Work Parallel Checklist

작성: 2026-05-22 KST
범위: AgentDock Visual Workspace / CEO Action Surface / 90%+ release hardening

## Global stop rules

- 90%+/release-ready를 주장하려면 다음이 모두 필요하다: native live-click PASS, current-job native `releaseProof=true`, final release matrix PASS, stale source 없음, QA GO.
- 앱 UI에는 broad shell bridge 또는 arbitrary `agentdock <anything>` runner를 추가하지 않는다.
- direct task-card edit은 구현하지 않는다. `finish`는 final-ready snapshot gate를 통과한 controlled action으로만 허용한다.
- `.agent-work/`, `.agentdock/`, `dist/`, `node_modules/`, `src-tauri/target/`, `tsconfig.tsbuildinfo`는 커밋 대상이 아니다.

## Lane A — Release proof / QA matrix (P0)

- [x] `tests/workspace_live_click_job_create.sh`를 실제 native UI driver와 연결하거나, driver 부재를 명시한 blocked evidence를 최신화한다.
  - Evidence: `.agent-work/07_JOBS/JOB-260522190004397678/OUTPUTS/live-click-evidence/live-click-evidence.json`.
- [x] sandbox job create가 실제 UI click으로 `sandbox CURRENT.md`를 변경하는지 검증한다.
  - Result: AT-SPI/native button action created `JOB-LIVECLICK1779454612977132338`.
- [x] main project `CURRENT.md` no-mutation proof를 저장한다.
- [x] native screenshot manifest가 current job id를 가리키는지 검증한다.
- [x] required native PNG states를 채우고 `releaseProof=true`가 되게 한다. 불가능하면 false/blocker를 명확히 남긴다.
  - Evidence: `.agent-work/07_JOBS/JOB-260522190004397678/OUTPUTS/native-evidence/workspace-native-screenshot-manifest.json`.
- [x] `tests/workspace_release_matrix.sh`를 stale 없이 full-duration으로 실행한다.
- [x] final JSON/MD/log artifact를 current job OUTPUTS에 남긴다.
  - Final matrix: `.agent-work/07_JOBS/JOB-260522190004397678/OUTPUTS/final-verification-fixed-20260522/workspace-release-matrix.json` (`overallPass=true`, 21/21 gates).
- [x] 2026-05-23 재검증: AT-SPI native live-click + `releaseProof=true` native manifest + full release matrix PASS.
  - Final matrix: `.agent-work/07_JOBS/JOB-260522190004397678/OUTPUTS/release-matrix-final-proof-20260523/workspace-release-matrix.json` (`overallPass=true`, stale=false, 21/21 gates).
  - Live-click: `.agent-work/07_JOBS/JOB-260522190004397678/OUTPUTS/live-click-evidence/live-click-evidence.json` (`status=pass`, nativeClick=true).
  - Native manifest: `.agent-work/07_JOBS/JOB-260522190004397678/OUTPUTS/native-evidence/workspace-native-screenshot-manifest.json` (`releaseProof=true`, 12/12 captured).
- [x] 2026-05-23 controlled action native matrix PASS.
  - Evidence: `.agent-work/07_JOBS/JOB-260522190004397678/OUTPUTS/controlled-actions-native-matrix/controlled-actions-native-matrix.json` (`status=pass`, nativeClick=true, observed non-preview CLI commands=7).

## Lane B — Monitoring UI / source stabilization (P1)

- [x] `FacilitationTimeline` source slice를 추적 대상 파일로 정리한다.
- [x] timeline selector가 missing reports/blockers/stale/demo/error를 정확히 표현하는지 테스트 보강한다.
- [x] `ActionAuditPanel` source slice를 추적 대상 파일로 정리한다.
- [x] audit event에 duration/result/redaction/session-local copy가 충분한지 검증한다.
- [x] `InterventionPanel` disabled-safe copy가 premature finish를 유도하지 않는지 false-ready 상태에서 확인한다.
- [x] `npm run build`, `tests/workspace_timeline.sh`, `tests/workspace_action_audit.sh` PASS를 확보한다.
  - Evidence: final matrix above plus direct reruns during 2026-05-23 cleanup.

## Lane C — CEO composer/concurrency hardening (P0/P1)

- [x] empty/overlong/in-flight/duplicate-submit 상태를 source/static test로 확인한다.
- [x] post-create snapshot refresh pending/succeeded/failed 상태가 result와 충돌하지 않는지 확인한다.
- [x] fake/slow job-create path에서 중복 submit과 refresh overlap을 검증한다.
- [x] failure message가 redacted/actionable한지 확인한다.
- [x] native screenshot evidence가 없으면 release blocker로 남긴다.
  - Evidence: `tests/workspace_job_create_bridge.sh`, `tests/workspace_ceo_composer_concurrency.sh`, `tests/workspace_release_matrix.sh`.

## Lane D — Read-only history / inspector clarity (P1)

- [x] `workspace history --json` 신규 CLI와 snapshot payload 확장 중 하나를 결정한다.
  - Decision: first extend the existing read-only snapshot payload with bounded history summaries; defer a separate `workspace history --json` command until the UI need exceeds that contract.
- [x] previous jobs read-only inspection 설계를 작성한다.
  - Artifact: `docs/visual-workspace-history-followup-release-hygiene.md`.
- [x] job 선택이 `CURRENT.md`를 변경하지 않는 no-mutation test를 정의한다.
  - Defined in the Lane D no-mutation contract and locked by `tests/workspace_history_followup_design.sh`.
- [x] role inspector의 task/report/running/configured/selected/bench/offline clarity gap을 점검한다.
  - Inspector contract now requires task/report path, running pane, selected/bench/offline, and live/stale/demo/error source clarity before implementation.
- [x] 구현 범위가 크면 design-only artifact와 후속 task card로 분리한다.
  - This slice is design/test-contract only; runtime implementation remains a follow-up task.

## Lane E — Controlled intervention next slice (P2)

- [x] 첫 enabled intervention은 CEO follow-up으로 제한한다.
- [x] `agentdock job followup` 신규 CLI 또는 fixed `send <ceo> <message>` bridge 중 하나를 architecture decision으로 고정한다.
  - Decision: dedicated `agentdock job followup --message <text>`; reject generic `send` as the UI bridge.
- [x] follow-up request/result DTO, validation, fixed argv, timeout, redaction, project validation을 설계한다.
  - Artifact: `docs/visual-workspace-history-followup-release-hygiene.md`.
- [x] UI compose → preview → confirm → result → audit flow를 설계한다.
- [x] fake-agentdock argv regression과 sandbox inbox mutation proof를 정의한다.
- [x] selected broadcast / role send / recruit / task proposal / report / finish를 controlled action UI와 native matrix로 확장한다.

## Lane F — Commit/release hygiene (cross-cutting)

- [x] `git status --short --untracked-files=all` 기준으로 source/test 변경과 generated output을 분리한다.
- [x] untracked source/test files를 commit 대상 후보로 분류한다.
- [x] generated output이 `.gitignore`에 의해 제외되는지 확인한다.
- [x] Lore commit protocol에 맞는 commit split 제안을 작성한다.
- [x] README/docs의 상태 문구가 source-level GO와 release NO-GO를 혼동하지 않게 정리한다.
  - Rule: docs may claim source-level progress only; release-ready/90%+/QA GO still requires native live-click PASS, current-job `releaseProof=true`, final matrix PASS, and leader QA approval.

## Parallel assignment

Current OMX run split:

- Worker 1: Lane A release proof / matrix plus P0 evidence blockers.
- Worker 2: Lane B monitoring UI stabilization plus Lane C CEO composer/concurrency hardening.
- Worker 3: Lane D history/inspector design/tests plus Lane E CEO follow-up controlled-action architecture and Lane F commit/release hygiene synthesis.

Historical six-worker split is superseded for this run; do not use stale owner rows as release evidence.
