# Visual Workspace 90%+ 완성 체크리스트

작성: 2026-05-22 18:47 KST
대상: AgentDock Visual Workspace / CEO Action Surface / 유저 개입형 운영 콘솔
목표:

1. Visual Workspace 앱 + CEO job create slice를 90% 이상으로 끌어올린다.
2. Release-ready 기준을 90% 이상으로 끌어올린다.
3. 유저 개입형 운영 콘솔 목표 제품도 90% 수준까지 끌어올린다.

현재 기준점:

- Visual Workspace 앱/CEO job create slice: 80~85%
- Source/test 기준 controlled-action safety: PASS
- Release-ready 기준: 65~70%
- 유저 개입형 운영 콘솔 포함 목표 제품: 45~55%

핵심 판단:

- 90%+를 만들려면 단순 버그픽스가 아니라 “증거 자동화 + 관찰성 + 안전한 개입 제어면”이 모두 필요하다.
- 현재 가장 큰 빈칸은 real native/sandbox proof와 앱 내 개입 기능이다.
- 아무 제어나 다 열면 빠르게 90%처럼 보일 수 있지만, AgentDock 특성상 잘못 열면 보안/무결성 점수가 떨어진다. 따라서 controlled action을 순서대로 열어야 한다.

---

## 0. 완료율 산정 기준

### A. CEO job create slice 90% 기준

90% 이상으로 인정하려면 다음이 모두 필요하다.

- [ ] 앱에서 실제 버튼 클릭으로 sandbox job 생성이 입증됨.
- [ ] main project `.agent-work/07_JOBS/CURRENT.md`가 오염되지 않음.
- [ ] sandbox project `CURRENT.md`가 새 `JOB-*`로 바뀜.
- [ ] UI 성공/실패/진행중 상태가 native screenshot으로 남음.
- [ ] job id/path/message가 redaction 처리된 상태로 UI에 표시됨.
- [ ] 실패 시 actionable error가 표시됨.
- [ ] 2회 이상 연속 클릭/중복 submit이 막힘.
- [ ] source/test/fake proof와 real native proof가 분리되어 문서화됨.
- [ ] 전체 safety gates 재실행 PASS.

### B. Release-ready 90% 기준

90% 이상으로 인정하려면 다음이 필요하다.

- [ ] native Tauri screenshot pack이 현재 job 기준으로 생성됨.
- [ ] primary manifest가 current job id와 일치함.
- [ ] `releaseProof=true`가 manifest에 존재함.
- [ ] live / missing reports / blockers / final-ready / dense-50 / stale-error / demo / focus-reduced-motion 상태가 캡처됨.
- [ ] `npm run tauri:build` PASS.
- [ ] package artifact verification PASS.
- [ ] `tests/smoke.sh` PASS.
- [ ] quiet-window no-write/security gate PASS.
- [ ] QA final matrix가 변경 이후 한 번에 PASS.
- [ ] stale evidence / duplicate evidence / false manifest가 없음.

### C. 유저 개입형 운영 콘솔 90% 기준

90% 이상으로 인정하려면 다음이 필요하다.

- [ ] 작업 생성: CEO job create.
- [ ] 관찰: timeline, role state, report state, blockers, logs/history.
- [ ] 개입: CEO follow-up, role send, selected-team broadcast.
- [ ] 조정: task card update/diff/approval.
- [ ] 팀 관리: recruit controlled action.
- [ ] 종료 보조: finish readiness guidance; finish 실행은 마지막에 별도 gated action.
- [ ] 모든 action이 typed request/result, fixed argv, no shell, timeout, redaction, project validation을 통과.
- [ ] 앱 내 action audit log가 모든 시도/성공/실패를 보여줌.
- [ ] 사용자가 “지금 누르면 무엇이 바뀌는지” 미리 볼 수 있음.
- [ ] destructive/externally visible action은 confirmation 필요.

---

## 1. P0 — CEO job create slice를 90%+로 올리는 작업

### P0-1. Real sandbox live-click mutation proof 자동화

목표: fake bridge가 아니라 실제 Tauri UI 클릭으로 job 생성 입증.

체크리스트:

- [ ] `tests/workspace_live_click_job_create.sh` 추가.
- [ ] `/tmp/agentdock-live-click-*` sandbox project 생성.
- [ ] sandbox에 `.agentdock/`, `.agent-work/` fixture 생성 또는 `agentdock init` 실행.
- [ ] fake Hermes/tmux 환경으로 외부 영향 최소화.
- [ ] main project `CURRENT.md` before hash 저장.
- [ ] sandbox `CURRENT.md` before hash 저장.
- [ ] Tauri 앱을 sandbox `--project <path>`로 실행.
- [ ] UI automation으로 CEO textarea에 request 입력.
- [ ] Send to CEO 버튼 클릭.
- [ ] UI success state에서 `JOB-*` id 읽기.
- [ ] sandbox `CURRENT.md`가 해당 `JOB-*`로 변경됐는지 확인.
- [ ] main project `CURRENT.md` hash가 동일한지 확인.
- [ ] screenshot + json evidence 저장.
- [ ] 실패 시 stdout/stderr/log를 redacted artifact로 저장.

Acceptance:

- [ ] sandbox mutation PASS.
- [ ] main no-mutation PASS.
- [ ] UI success PASS.
- [ ] redaction PASS.
- [ ] script exits nonzero on any mismatch.

예상 작업량: M/L
예상 완료율 상승:

- CEO job create slice: +5~8%
- release-ready: +10~15%

### P0-2. CEO composer UX edge states 보강

목표: 실사용자가 실패/중복/진행 상태를 오해하지 않게 함.

체크리스트:

- [ ] empty input disabled 상태 명확화.
- [ ] overlong input counter/limit 표시.
- [ ] in-flight 중 textarea/button disabled.
- [ ] 2회 연속 submit 방지.
- [ ] timeout/failure 메시지에 다음 조치 표시.
- [ ] 성공 후 `Refresh snapshot` 상태와 last refreshed 표시.
- [ ] created job id/path copy affordance 또는 selectable text.
- [ ] “이 액션은 새 CEO-led job만 생성한다. send/recruit/finish는 하지 않는다” copy 유지.

Acceptance:

- [ ] source test 또는 static grep gate.
- [ ] native screenshot: empty/valid/in-flight/success/failure.

예상 작업량: S/M
예상 완료율 상승:

- CEO job create slice: +3~5%

### P0-3. Concurrent snapshot/job-create 안전성

목표: snapshot refresh와 job-create가 겹칠 때 UI/bridge 상태 꼬임 방지.

체크리스트:

- [ ] job-create in-flight 동안 create action 중복 방지.
- [ ] snapshot refresh가 실패해도 created job result는 사라지지 않음.
- [ ] stale last-good snapshot과 newly-created job banner가 충돌하지 않음.
- [ ] result panel에 “snapshot refresh pending/failed/succeeded” 상태 표시.
- [ ] Rust command timeout/kill behavior 검증.

Acceptance:

- [ ] unit/static test.
- [ ] fake-agentdock slow response regression.

예상 작업량: M
예상 완료율 상승:

- CEO job create slice: +2~4%
- release-ready: +2~3%

---

## 2. P0 — Release-ready 90%+ 작업

### P0-4. Native screenshot manifest를 진짜 releaseProof로 만들기

체크리스트:

- [ ] 현재 active job id를 manifest에 기록.
- [ ] `releaseProof=true` 조건을 명확히 정의.
- [ ] 12/12 또는 최신 required states 전부 captured.
- [ ] screenshot path가 실제 PNG이고 magic bytes 검증됨.
- [ ] blank/black/low-information screenshot reject.
- [ ] stale manifest와 duplicate evidence directory 감지.
- [ ] manifest readback test 추가.
- [ ] 실패 시 release matrix가 반드시 FAIL.

Acceptance:

- [ ] `tests/workspace_native_screenshots.sh`가 current job manifest를 생성.
- [ ] `tests/workspace_package_artifacts.sh`와 final matrix가 manifest를 검증.

예상 작업량: M/L
예상 완료율 상승:

- release-ready: +10~12%

### P0-5. Final release matrix runner 추가

목표: 사람이 여러 command를 기억하지 않게 단일 runner 제공.

체크리스트:

- [ ] `tests/workspace_release_matrix.sh` 추가.
- [ ] 각 gate 결과를 JSON으로 저장.
- [ ] full log 저장.
- [ ] source changed timestamp가 matrix 실행 중 바뀌면 stale 표시.
- [ ] smoke hang/timeout을 FAIL로 기록.
- [ ] native releaseProof가 false면 전체 FAIL.
- [ ] summary table 출력.

필수 gates:

- [ ] bash syntax.
- [ ] version check.
- [ ] workspace job create bridge.
- [ ] desktop no-write.
- [ ] security redaction.
- [ ] desktop app build/static checks.
- [ ] reference a11y.
- [ ] visual fixtures.
- [ ] visual scene.
- [ ] workspace p0.5.
- [ ] smoke.
- [ ] npm build.
- [ ] cargo check.
- [ ] cargo test.
- [ ] tauri build.
- [ ] package artifacts.
- [ ] native screenshots/releaseProof.

Acceptance:

- [ ] one command produces pass/fail JSON and markdown report.
- [ ] release-ready claim only reads from this report.

예상 작업량: M
예상 완료율 상승:

- release-ready: +5~8%

### P0-6. Quiet-window no-write proof

체크리스트:

- [ ] test start 전에 `.agent-work` and `.agentdock` file hash inventory 생성.
- [ ] read-only interactions 수행.
- [ ] allowed mutation 목록은 job-create sandbox에만 한정.
- [ ] main project mutation zero proof.
- [ ] no-write report artifact 저장.

Acceptance:

- [ ] read-only app launch/refresh는 main coordination files를 바꾸지 않음.
- [ ] job-create는 sandbox에만 mutation.

예상 작업량: M
예상 완료율 상승:

- release-ready: +4~6%

---

## 3. P1 — 모니터링/관찰성을 90% 제품 수준으로 올리는 작업

### P1-1. Facilitation Timeline

목표: 유저가 CEO/team 진행 단계를 한눈에 봄.

체크리스트:

- [ ] `src-ui/model/timeline.ts` 추가.
- [ ] snapshot에서 pure selector로 단계 계산.
- [ ] 단계: Intake, CEO Planning, Team Selection, Tasking, Execution, Reports, Final Ready, Complete.
- [ ] 단계별 evidence count 표시.
- [ ] missing report/blocker가 final-ready를 덮어씀.
- [ ] stale/demo/error mode에서도 안전한 fallback.
- [ ] `src-ui/components/FacilitationTimeline.tsx` 또는 scene component 추가.
- [ ] fixture별 timeline expectation 추가.

Acceptance:

- [ ] active-normal fixture: Execution/Reports 상태 정확.
- [ ] missing-reports fixture: Reports blocked.
- [ ] final-ready fixture: Final Ready.
- [ ] blocker fixture: Blocked overlay.
- [ ] dense-50에서도 layout 깨지지 않음.

예상 작업량: M
예상 완료율 상승:

- 운영 콘솔 목표 제품: +6~8%

### P1-2. Action Audit Panel

목표: 사용자가 앱에서 한 모든 action을 추적.

체크리스트:

- [ ] session-local action log state 추가.
- [ ] job-create attempt/success/failure 기록.
- [ ] timestamp, duration, action type, request preview, result job id/path 표시.
- [ ] redacted stdout/stderr summary 표시.
- [ ] failed action 재시도는 같은 action만, shell fallback 금지.
- [ ] audit panel에 “session local only” 명시.
- [ ] future controlled actions도 같은 log model 사용.

Acceptance:

- [ ] job-create success/failure가 panel에 남음.
- [ ] secret-looking string이 redacted됨.
- [ ] reload하면 사라지는 session-local 동작이 copy와 일치.

예상 작업량: M
예상 완료율 상승:

- 운영 콘솔 목표 제품: +5~7%
- release confidence: +2~3%

### P1-3. Job History / Read-only inspection

체크리스트:

- [ ] CLI snapshot/history contract 설계.
- [ ] `agentdock workspace history --json` 또는 snapshot payload 확장 결정.
- [ ] UI에서 previous jobs list 표시.
- [ ] inspect-only mode 명시.
- [ ] job 선택이 `CURRENT.md`를 바꾸지 않음을 test.
- [ ] active job과 inspected job 시각 구분.

Acceptance:

- [ ] history inspect no-mutation proof.
- [ ] active/current confusion 없음.

예상 작업량: M/L
예상 완료율 상승:

- 운영 콘솔 목표 제품: +5~7%

### P1-4. Role detail / report preview 강화

체크리스트:

- [ ] role inspector에 task path, report path, running pane, configured 상태 정리.
- [ ] latest report preview를 안전하게 표시하거나 path-only 유지 결정.
- [ ] selected/bench/blocked/offline 구분 강화.
- [ ] role별 next action guidance 제공.
- [ ] raw object rendering 방지.

Acceptance:

- [ ] selected role 10초 clarity PASS.
- [ ] blocker/report/missing 상태를 사용자가 오해하지 않음.

예상 작업량: S/M
예상 완료율 상승:

- 운영 콘솔 목표 제품: +3~5%

---

## 4. P2 — 유저 개입형 controlled action console

중요 원칙:

- 한 slice에 action 하나만 연다.
- CLI에 이미 있는 기능이라도 UI bridge는 별도 보안 설계가 필요하다.
- 모든 action은 typed request/result, fixed argv, no shell, timeout, redaction, project validation, audit logging을 가져야 한다.
- destructive/externally visible action은 preview + confirmation 필수.

### P2-1. CEO follow-up controlled action

권장 첫 개입 기능. role 직접 send보다 안전하다.

의도:

- 유저가 “현재 job의 CEO에게 추가 지시/변경 요청”을 보냄.
- CEO가 팀 조정 여부를 판단하게 함.

가능 argv 후보:

- `agentdock send ceo-orchestrator <message>`
- 또는 전용 CLI: `agentdock job followup --to-ceo <message>` 신규 구현 권장.

체크리스트:

- [ ] CLI에 `job followup` 추가 여부 결정.
- [ ] active job id validation.
- [ ] message validation empty/overlong.
- [ ] command argv fixed/no-shell.
- [ ] UI: Follow-up to CEO panel.
- [ ] UI: preview + confirmation.
- [ ] action audit 기록.
- [ ] fake-agentdock argv regression.
- [ ] no-write gate 업데이트: 허용 action 목록에만 추가.
- [ ] live sandbox proof.

Acceptance:

- [ ] CEO inbox에 follow-up이 들어감.
- [ ] role/team 직접 지시는 하지 않음.
- [ ] active job 없는 상태에서 disabled.

예상 작업량: M/L
예상 완료율 상승:

- 운영 콘솔 목표 제품: +8~10%

### P2-2. Selected-team broadcast controlled action

의도:

- 현재 selected roles 전체에 변경 알림/우선순위 안내.

가능 argv:

- `agentdock broadcast --selected <message>`

체크리스트:

- [ ] active job required.
- [ ] selected roles count preview.
- [ ] affected roles list 표시.
- [ ] confirmation mandatory.
- [ ] fixed argv/no shell.
- [ ] output redaction.
- [ ] audit log.
- [ ] broadcast log mutation proof.
- [ ] selected team만 수신했는지 fixture/sandbox 검증.

Acceptance:

- [ ] selected roles inbox에만 기록.
- [ ] all-team accidental broadcast 없음.

예상 작업량: M/L
예상 완료율 상승:

- 운영 콘솔 목표 제품: +7~9%

### P2-3. Role direct send controlled action

의도:

- 특정 role에게만 지시/질문 전달.

가능 argv:

- `agentdock send <role> <message>`

체크리스트:

- [ ] role allowlist는 snapshot roles에서만.
- [ ] selected role / bench role 구분 표시.
- [ ] running pane 여부 표시.
- [ ] message preview.
- [ ] confirmation mandatory.
- [ ] fixed argv/no shell.
- [ ] fake-agentdock role/message argv test.
- [ ] audit log.
- [ ] target role inbox mutation proof.
- [ ] non-target role no-mutation proof.

Acceptance:

- [ ] 지정 role만 수신.
- [ ] role id injection 불가.

예상 작업량: M/L
예상 완료율 상승:

- 운영 콘솔 목표 제품: +7~9%

### P2-4. Recruit controlled action

의도:

- 유저가 앱에서 새 role을 추가하게 함.

가능 argv:

- `agentdock recruit <role> --template <template> --mission <mission>`

체크리스트:

- [ ] role id validation/normalization.
- [ ] template allowlist.
- [ ] mission validation.
- [ ] existing role conflict preview.
- [ ] running tmux side effect warning.
- [ ] confirmation mandatory.
- [ ] fixed argv/no shell.
- [ ] audit log.
- [ ] fake-agentdock regression.
- [ ] sandbox proof: new role config/pane state.

Acceptance:

- [ ] approved template만 사용.
- [ ] arbitrary command/template path 주입 불가.
- [ ] recruit 후 snapshot에 role 반영.

예상 작업량: L
예상 완료율 상승:

- 운영 콘솔 목표 제품: +8~10%

### P2-5. Task card change request / patch proposal

권장 방식:

- 앱이 직접 TASKS/*.md를 수정하지 않는다.
- 먼저 CEO에게 “task change proposal”을 보내고, CEO가 적용하게 한다.
- 직접 edit 기능은 더 뒤로 미룬다.

체크리스트:

- [ ] task list read-only 표시.
- [ ] change proposal composer.
- [ ] affected task/role preview.
- [ ] CEO approval route.
- [ ] diff generation은 UI local only 또는 CLI dry-run.
- [ ] direct file write 금지.
- [ ] audit log.

Acceptance:

- [ ] UI에서 task card가 직접 변경되지 않음.
- [ ] proposal은 CEO inbox/follow-up으로 전달됨.

예상 작업량: M/L
예상 완료율 상승:

- 운영 콘솔 목표 제품: +5~7%

### P2-6. Finish readiness assist, not direct finish first

의도:

- 처음부터 finish 버튼을 열지 않는다.
- 먼저 “왜 finish 가능한/불가능한지”와 “CLI에서 실행할 command”를 안내.

체크리스트:

- [ ] final readiness reason 강화.
- [ ] missing report blockers clickable detail.
- [ ] suggested CLI command copy.
- [ ] direct finish button은 disabled/hidden.
- [ ] direct finish controlled action은 별도 P3로 분리.

Acceptance:

- [ ] 유저가 finish 가능 여부를 오해하지 않음.
- [ ] 앱이 lifecycle을 조기 종료하지 않음.

예상 작업량: S/M
예상 완료율 상승:

- 운영 콘솔 목표 제품: +3~5%

---

## 5. P3 — 직접 lifecycle control, 90% 이후

90% 목표에 꼭 필요하지 않거나 위험도가 높은 항목이다.

### P3-1. Direct `job finish` controlled action

체크리스트:

- [ ] all selected reports present 조건 강제.
- [ ] final summary preview.
- [ ] irreversible confirmation.
- [ ] `--keep-team` 옵션 선택 여부.
- [ ] final report path proof.
- [ ] worker teardown proof.
- [ ] failure rollback 없음 명시.

권장: P2 완료 후 별도 job에서 진행.

### P3-2. Direct task card edit

체크리스트:

- [ ] file lock.
- [ ] diff preview.
- [ ] approval.
- [ ] conflict detection.
- [ ] backup/restore.
- [ ] audit.

권장: CEO proposal route를 먼저 구현한 뒤 진행.

---

## 6. 파일/모듈별 작업 지도

### React UI

- [ ] `src-ui/App.tsx`
  - action state orchestration 확장.
  - action audit state 추가.
  - controlled action panels 배치.

- [ ] `src-ui/components/CeoTaskComposer.tsx`
  - edge state 강화.
  - success/failure native evidence marker.

- [ ] `src-ui/components/ActionAuditPanel.tsx` 신규.

- [ ] `src-ui/components/FacilitationTimeline.tsx` 신규.

- [ ] `src-ui/components/InterventionPanel.tsx` 신규.

- [ ] `src-ui/model/actions.ts`
  - 공통 action result/error/redaction type 추가.
  - followup/broadcast/send/recruit validators 추가.

- [ ] `src-ui/model/timeline.ts` 신규.

- [ ] `src-ui/model/snapshot.ts`
  - allowed_actions / action capabilities type 정리.

- [ ] `src-ui/scene/*`
  - timeline/audit/intervention 상태를 OfficeScene에 안전하게 통합.

### Tauri/Rust

- [ ] `src-tauri/src/lib.rs`
  - 공통 `run_agentdock_action` helper 추출.
  - action별 fixed argv builder.
  - timeout/redaction/project validation 재사용.
  - no-shell invariant tests.
  - new commands는 한 slice씩 추가.

예상 future commands:

- [ ] `agentdock_job_followup`
- [ ] `agentdock_broadcast_selected`
- [ ] `agentdock_role_send`
- [ ] `agentdock_recruit_role`

주의:

- [ ] `agentdock_job_finish`는 P3까지 열지 않는다.
- [ ] `task_edit`은 직접 파일쓰기보다 CEO proposal 먼저.

### CLI / bin/agentdock

- [ ] `agentdock job followup` 신규 command 검토.
- [ ] `workspace history --json` 신규 command 검토.
- [ ] snapshot에 action capabilities 명시.
- [ ] selected roles preview를 안정적으로 제공.
- [ ] broadcast/send/recruit 결과를 parse-friendly하게 출력.

### Tests

- [ ] `tests/workspace_live_click_job_create.sh` 신규.
- [ ] `tests/workspace_release_matrix.sh` 신규.
- [ ] `tests/workspace_action_audit.sh` 신규.
- [ ] `tests/workspace_timeline.sh` 신규.
- [ ] `tests/workspace_followup_bridge.sh` 신규.
- [ ] `tests/workspace_broadcast_selected_bridge.sh` 신규.
- [ ] `tests/workspace_role_send_bridge.sh` 신규.
- [ ] `tests/workspace_recruit_bridge.sh` 신규.
- [ ] `tests/workspace_quiet_no_write.sh` 신규.

---

## 7. 구현 순서 / 마일스톤

### M1 — CEO job create + release-ready 90%

목표:

- CEO job create slice 90%+
- release-ready 85~90%

작업:

- [ ] P0-1 real sandbox live-click proof.
- [ ] P0-2 CEO composer edge states.
- [ ] P0-3 concurrent safety.
- [ ] P0-4 native releaseProof manifest.
- [ ] P0-5 release matrix runner.
- [ ] P0-6 quiet-window no-write proof.

Exit criteria:

- [ ] CEO job create slice >= 90%.
- [ ] release-ready >= 90% or explicit remaining gap <= 5%.
- [ ] final matrix PASS.

### M2 — Monitoring console 90%

목표:

- 유저가 “무슨 일이 진행 중인지” 10초 안에 이해.

작업:

- [ ] P1-1 Facilitation Timeline.
- [ ] P1-2 Action Audit Panel.
- [ ] P1-3 Job History / read-only inspection.
- [ ] P1-4 Role detail/report preview 강화.

Exit criteria:

- [ ] 모니터링/관찰성 >= 90%.
- [ ] dense-50에서도 usable.
- [ ] stale/error/demo/live 상태 혼동 없음.

### M3 — Safe intervention console 80~90%

목표:

- 유저가 앱에서 안전하게 개입 가능.

작업:

- [ ] P2-1 CEO follow-up.
- [ ] P2-2 selected-team broadcast.
- [ ] P2-3 role direct send.
- [ ] P2-5 task change proposal.
- [ ] P2-6 finish readiness assist.

Exit criteria:

- [ ] 운영 콘솔 목표 제품 >= 85~90%.
- [ ] 모든 intervention이 audit에 남음.
- [ ] no-shell/no-arbitrary-write 유지.

### M4 — Team management 90%+

작업:

- [ ] P2-4 recruit controlled action.
- [ ] role/template allowlist.
- [ ] recruit sandbox proof.
- [ ] post-recruit snapshot refresh.

Exit criteria:

- [ ] 목표 제품 >= 90%.
- [ ] 유저가 생성/관찰/개입/팀확장까지 앱에서 수행 가능.

### M5 — Lifecycle control, optional post-90

작업:

- [ ] direct finish controlled action 검토.
- [ ] direct task-card edit 검토.

Exit criteria:

- [ ] 95%+ 목표일 때만 진행.

---

## 8. 위험도와 순서 판단

바로 하면 안 되는 것:

- [ ] broad shell bridge.
- [ ] arbitrary `agentdock <anything>` runner.
- [ ] UI 직접 `.agent-work` file edit.
- [ ] finish button 선구현.
- [ ] task card direct edit 선구현.
- [ ] role id/template free text without allowlist.

먼저 해야 하는 것:

- [ ] native live-click proof.
- [ ] releaseProof manifest correctness.
- [ ] action audit foundation.
- [ ] CEO follow-up route.

가장 효율적인 순서:

1. live-click proof.
2. release matrix runner.
3. CEO composer edge polish.
4. timeline.
5. action audit.
6. CEO follow-up.
7. selected broadcast.
8. role direct send.
9. recruit.
10. task-change proposal.

---

## 9. 90% 도달 예상

### CEO job create slice

현재: 80~85%

- live-click proof + edge states + concurrency safety 후: 90~93%

### Release-ready

현재: 65~70%

- live-click proof: +10~15%
- native releaseProof manifest: +10~12%
- final matrix runner/quiet-window proof: +8~12%

예상: 90~94%

### 유저 개입형 운영 콘솔

현재: 45~55%

- monitoring P1 완료 후: 60~70%
- CEO follow-up + action audit 완료 후: 70~78%
- selected broadcast + role send 완료 후: 80~86%
- recruit + task proposal 완료 후: 88~92%

90% 도달 조건:

- [ ] P1 전체 완료.
- [ ] P2-1, P2-2, P2-3 완료.
- [ ] P2-4 또는 P2-5 중 최소 하나 완료.
- [ ] 모든 intervention action에 native/sandbox proof 존재.

---

## 10. 다음 AgentDock 작업 카드 추천

다음 구현 job은 하나로 너무 크게 잡지 말고 3개로 나눈다.

### Job A — Release-ready 90% hardening

역할:

- system-architect
- developer
- agentdock-qa
- delivery-planner

범위:

- live-click proof
- release matrix runner
- native releaseProof manifest
- quiet-window no-write proof

완료 조건:

- release-ready 90%+ 또는 정확한 remaining blocker <= 1개.

### Job B — Monitoring console 90%

역할:

- product-manager
- ux-designer
- developer
- agentdock-qa

범위:

- facilitation timeline
- action audit panel
- job history/read-only inspection
- role detail/report preview

완료 조건:

- 사용자가 앱만 보고 진행상황을 10초 안에 파악.

### Job C — Safe intervention console

역할:

- product-manager
- system-architect
- developer
- agentdock-qa
- delivery-planner

범위:

- CEO follow-up
- selected-team broadcast
- role direct send
- task change proposal
- recruit controlled action

완료 조건:

- 유저가 앱에서 작업 중 변경지시를 안전하게 전달.
- 모든 action이 audit/proof/no-shell/no-write gates 통과.

---

## 11. 최종 체크박스 요약

90%+로 가기 위한 필수 항목만 압축하면 다음이다.

- [ ] Real native sandbox click으로 CEO job create 증명.
- [ ] main project no-mutation 증명.
- [ ] native screenshot releaseProof manifest current job 기준 PASS.
- [ ] final release matrix runner PASS.
- [ ] quiet-window no-write/security proof PASS.
- [ ] CEO composer 실패/중복/진행중 UX 보강.
- [ ] Facilitation Timeline 구현.
- [ ] Action Audit Panel 구현.
- [ ] Job History read-only inspection 구현.
- [ ] CEO follow-up controlled action 구현.
- [ ] Selected-team broadcast controlled action 구현.
- [ ] Role direct send controlled action 구현.
- [ ] Recruit controlled action 구현.
- [ ] Task change proposal route 구현.
- [ ] 모든 controlled action에 fixed argv/no shell/redaction/timeout/project validation/fake bridge/sandbox proof 적용.

