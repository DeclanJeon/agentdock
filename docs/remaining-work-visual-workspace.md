# Visual Workspace 남은 작업량 / 실행 체크리스트

작성: 2026-05-22 18:29 KST
대상 버전: 0.2.0 이후

## 현재 결론

- Source/test controlled-action slice는 GO with constraints.
- Release proof gates는 GO: final matrix 21/21 PASS, native live-click PASS, current-job native `releaseProof=true`.
- 이전 최대 P0였던 real sandbox live-click mutation proof는 `JOB-260522190004397678` 기준 완료됐다.
- 앱 내 변경지시/개입 기능은 아직 없다. 별도 controlled action slices로 설계/검증해야 한다.

## P0 — release-ready 전에 필요

### P0-1 Real sandbox live-click proof

작업량: M/L
우선순위: 최고

해야 할 일:

1. `/tmp/<sandbox>` 형태의 독립 AgentDock fixture project 생성.
2. main project `.agent-work/07_JOBS/CURRENT.md` before hash/read 저장.
3. sandbox `.agent-work/07_JOBS/CURRENT.md` before hash/read 저장.
4. Tauri app을 sandbox project root로 실행.
5. 실제 `CeoTaskComposer` textarea/button을 UI driver로 조작.
6. `agentdock_job_create`가 sandbox에서 새 `JOB-*`를 만들었는지 확인.
7. main `CURRENT.md` after가 before와 byte-identical인지 확인.
8. sandbox `CURRENT.md` after가 새 sandbox job을 가리키는지 확인.
9. UI success state, job id/path, timestamp, stdout/stderr redaction 결과 저장.
10. evidence를 current job 또는 후속 job `OUTPUTS/sandbox-live-click-*`에 저장.
11. QA final matrix rerun.

Acceptance:

- main `CURRENT.md` unchanged PASS.
- sandbox `CURRENT.md` changed to created sandbox `JOB-*` PASS.
- browser-mocked/fake bridge proof와 real sandbox proof가 문서에서 명확히 구분됨.

### P0-2 Commit/drop decision

작업량: S
우선순위: 높음

결정 필요:

- `src-tauri/gen/schemas/*.json`
  - 권장: Tauri app source/config review 편의를 위해 이번 commit에는 포함 가능. 이후 regenerate policy를 docs에 적는다.
- `docs/reference_ui_workspace.png`, `docs/reference_ui_workspace2.png`
  - 현재 `docs/visual-workspace-reference-ui-design.md`가 `reference_ui_workspace.png`를 참조한다.
  - 권장: 참조되는 PNG는 docs asset으로 유지. 참조되지 않는 두 번째 PNG는 비교/reference asset으로 유지하거나 후속 cleanup에서 제거.

### P0-3 Generated output cleanup

작업량: S
우선순위: 높음

Commit 금지:

- `src-tauri/target/`
- `node_modules/`
- `dist/`
- `tsconfig.tsbuildinfo`
- `.agent-work/**`

확인:

- `.gitignore`가 위 항목을 막는지 확인.
- `git status --short --untracked-files=all`에서 generated output이 staged되지 않았는지 확인.

### P0-4 Final QA rerun

작업량: M
우선순위: 높음

최소 command matrix:

```bash
bash -n bin/agentdock install.sh tests/smoke.sh scripts/check-version.sh
bash scripts/check-version.sh
bash tests/workspace_job_create_bridge.sh
bash tests/workspace_desktop_no_write.sh
bash tests/workspace_security_redaction.sh
bash tests/workspace_desktop_app.sh
bash tests/workspace_reference_a11y.sh
bash tests/workspace_visual_fixtures.sh
bash tests/workspace_visual_scene.sh
bash tests/workspace_p05.sh
bash tests/smoke.sh
npm run build
cargo check --manifest-path src-tauri/Cargo.toml
cargo test --manifest-path src-tauri/Cargo.toml
```

Native/release wording을 쓸 경우 추가:

```bash
npm run tauri:build
bash tests/workspace_package_artifacts.sh
# native screenshot/releaseProof harness with current-job manifest
```

## P1 — 제품 완성도 향상

### P1-1 Action Audit Panel

작업량: M

목표:

- 현재 앱 세션에서 실행한 `agentdock_job_create` 시도/성공/실패를 리스트로 표시.
- job id/path, timestamp, duration, redacted summary 표시.
- snapshot이 source of truth라는 copy 표시.

금지:

- durable write bridge 추가 금지.
- retry-as-shell/recruit/send/finish/report/task-edit 버튼 금지.

### P1-2 Facilitation Timeline

작업량: M

목표:

- Planning / Recruiting / Tasking / Executing / Verifying / Complete 단계 표시.
- snapshot/lifecycle/report fields에서 pure selector로 계산.
- missing report/blocker가 optimistic complete를 덮어써야 함.

### P1-3 Read-only Job History / Inspection-only switcher

작업량: M/L

목표:

- 이전 job을 inspect-only로 조회.
- 선택은 `CURRENT.md`를 바꾸지 않는다는 copy를 명시.

선행조건:

- snapshot/history payload contract architecture 승인.

## P2 — 별도 CEO-approved controlled action slices

각 항목 작업량: M/L, 위험도 높음

- 앱에서 role에게 변경지시 보내기: `send` controlled action.
- 앱에서 selected team broadcast 보내기: `broadcast` controlled action.
- 앱에서 task card 수정하기: diff preview + lock + approval 필요.
- 앱에서 recruit 실행하기: role/template allowlist + preview 필요.
- 앱에서 finish/report 실행하기: lifecycle/report integrity risk가 커서 마지막 단계로 미룬다.

각 slice 공통 acceptance:

- one action per slice.
- typed request/result.
- fixed argv, no shell.
- fake-agentdock regression.
- timeout/redaction/project validation.
- confirmation/preview for externally visible or irreversible effects.
- no direct arbitrary file write.
- QA native/manual evidence.

## 앱 기능 질문별 답

### Q1. 앱을 켜서 CEO에게 업무내용을 전달하면 CEO가 필요한 팀을 생성해서 작업 수행하도록 되어 있나?

답: 부분적으로 YES.

- 앱에는 `CEO에게 작업 주기 / Send work to CEO` composer가 있다.
- submit 시 `agentdock job --no-attach <request>`를 호출하므로 AgentDock 엔진 기준으로는 CEO-led job 생성 플로우가 시작된다.
- AgentDock CLI/CEO workflow는 job 생성 후 CEO가 팀을 선택/recruit/task card 작성/보고 수집/finish하는 구조다.
- 단, real app live-click으로 sandbox에서 이 전체 시작점이 입증된 증거는 아직 없다. 현재 release-ready 관점에서는 NO-GO.

### Q2. 팀이 일하는 도중 유저가 모니터링할 수 있나?

답: YES, 하지만 snapshot 기반 관찰이다.

- 앱은 5초 refresh로 workspace snapshot을 다시 읽는다.
- 역할 상태, selected roles, missing reports, blockers, final readiness, inspector를 볼 수 있다.
- Dense role navigator/filter로 많은 role도 일부 모니터링 가능하다.
- 하지만 facilitation timeline/action audit/job history는 아직 미구현이다.

### Q3. 유저가 직접 개입해서 업무 수행 중 변경지시를 내릴 수 있나?

답: 앱에서는 NO.

- 현재 앱의 유일한 write-like action은 새 CEO-led job 생성이다.
- 작업 중 role에게 지시를 보내는 `send`, 전체 알림 `broadcast`, task card edit, recruit, finish, report UI는 없다.
- 이는 보안/운영 리스크 때문에 의도적으로 금지되어 있다.
- CLI에서는 trusted operator가 `adock send`, `adock broadcast` 등을 직접 실행할 수 있지만, Visual Workspace 앱 UI에는 아직 노출하지 않았다.

## 남은 작업량 요약

| 구분 | 항목 수 | 예상 크기 | 릴리스 영향 |
|---|---:|---|---|
| P0 | 4 | S~L | release-ready blocker |
| P1 | 3 | M~L | UX/관찰성 향상 |
| P2 | 5+ | M~L each | 고위험 제어면 확장 |

현실적 다음 실행 순서:

1. real sandbox live-click proof job 생성.
2. QA final matrix rerun.
3. Action Audit Panel.
4. Facilitation Timeline.
5. Read-only Job History.
6. 그 다음에야 send/broadcast 같은 변경지시 controlled action 설계.
