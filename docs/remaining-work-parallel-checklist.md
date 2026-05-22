# Remaining Work Parallel Checklist

작성: 2026-05-22 KST
범위: AgentDock Visual Workspace / CEO Action Surface / 90%+ release hardening

## Global stop rules

- 90%+/release-ready를 주장하려면 다음이 모두 필요하다: native live-click PASS, current-job native `releaseProof=true`, final release matrix PASS, stale source 없음, QA GO.
- 앱 UI에는 broad shell bridge 또는 arbitrary `agentdock <anything>` runner를 추가하지 않는다.
- direct `finish` / direct task-card edit은 P3 이후 별도 승인 전까지 구현하지 않는다.
- `.agent-work/`, `.agentdock/`, `dist/`, `node_modules/`, `src-tauri/target/`, `tsconfig.tsbuildinfo`는 커밋 대상이 아니다.

## Lane A — Release proof / QA matrix (P0)

- [ ] `tests/workspace_live_click_job_create.sh`를 실제 native UI driver와 연결하거나, driver 부재를 명시한 blocked evidence를 최신화한다.
- [ ] sandbox job create가 실제 UI click으로 `sandbox CURRENT.md`를 변경하는지 검증한다.
- [ ] main project `CURRENT.md` no-mutation proof를 저장한다.
- [ ] native screenshot manifest가 current job id를 가리키는지 검증한다.
- [ ] required native PNG states를 채우고 `releaseProof=true`가 되게 한다. 불가능하면 false/blocker를 명확히 남긴다.
- [ ] `tests/workspace_release_matrix.sh`를 stale 없이 full-duration으로 실행한다.
- [ ] final JSON/MD/log artifact를 current job OUTPUTS에 남긴다.

## Lane B — Monitoring UI / source stabilization (P1)

- [ ] `FacilitationTimeline` source slice를 추적 대상 파일로 정리한다.
- [ ] timeline selector가 missing reports/blockers/stale/demo/error를 정확히 표현하는지 테스트 보강한다.
- [ ] `ActionAuditPanel` source slice를 추적 대상 파일로 정리한다.
- [ ] audit event에 duration/result/redaction/session-local copy가 충분한지 검증한다.
- [ ] `InterventionPanel` disabled-safe copy가 premature finish를 유도하지 않는지 false-ready 상태에서 확인한다.
- [ ] `npm run build`, `tests/workspace_timeline.sh`, `tests/workspace_action_audit.sh` PASS를 확보한다.

## Lane C — CEO composer/concurrency hardening (P0/P1)

- [ ] empty/overlong/in-flight/duplicate-submit 상태를 source/static test로 확인한다.
- [ ] post-create snapshot refresh pending/succeeded/failed 상태가 result와 충돌하지 않는지 확인한다.
- [ ] fake/slow job-create path에서 중복 submit과 refresh overlap을 검증한다.
- [ ] failure message가 redacted/actionable한지 확인한다.
- [ ] native screenshot evidence가 없으면 release blocker로 남긴다.

## Lane D — Read-only history / inspector clarity (P1)

- [ ] `workspace history --json` 신규 CLI와 snapshot payload 확장 중 하나를 결정한다.
- [ ] previous jobs read-only inspection 설계를 작성한다.
- [ ] job 선택이 `CURRENT.md`를 변경하지 않는 no-mutation test를 정의한다.
- [ ] role inspector의 task/report/running/configured/selected/bench/offline clarity gap을 점검한다.
- [ ] 구현 범위가 크면 design-only artifact와 후속 task card로 분리한다.

## Lane E — Controlled intervention next slice (P2)

- [ ] 첫 enabled intervention은 CEO follow-up으로 제한한다.
- [ ] `agentdock job followup` 신규 CLI 또는 fixed `send <ceo> <message>` bridge 중 하나를 architecture decision으로 고정한다.
- [ ] follow-up request/result DTO, validation, fixed argv, timeout, redaction, project validation을 설계한다.
- [ ] UI compose → preview → confirm → result → audit flow를 설계한다.
- [ ] fake-agentdock argv regression과 sandbox inbox mutation proof를 정의한다.
- [ ] selected broadcast / role send / recruit / task proposal은 follow-up 이후 별도 slice로 남긴다.

## Lane F — Commit/release hygiene (cross-cutting)

- [ ] `git status --short --untracked-files=all` 기준으로 source/test 변경과 generated output을 분리한다.
- [ ] untracked source/test files를 commit 대상 후보로 분류한다.
- [ ] generated output이 `.gitignore`에 의해 제외되는지 확인한다.
- [ ] Lore commit protocol에 맞는 commit split 제안을 작성한다.
- [ ] README/docs의 상태 문구가 source-level GO와 release NO-GO를 혼동하지 않게 정리한다.

## Parallel assignment

- Worker 1: Lane A release proof / matrix.
- Worker 2: Lane B monitoring UI stabilization.
- Worker 3: Lane C composer/concurrency hardening.
- Worker 4: Lane D history/inspector design and low-risk tests.
- Worker 5: Lane E controlled intervention architecture for CEO follow-up.
- Worker 6: Lane F commit/release hygiene and final synthesis.
