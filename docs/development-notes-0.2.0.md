# AgentDock 개발 노트 — Visual Workspace 0.2.0

작성: 2026-05-22 18:29 KST
대상 버전: 0.2.0
범위: 지금까지 작업된 Visual Workspace / CEO Action Surface / 안전 검증 / 릴리스 문서화

## 1. 결론

0.2.0은 기존 CLI 중심 AgentDock에 React + Tauri 기반 Visual Workspace 앱과 첫 번째 controlled action surface를 추가한 버전이다.

현재 앱에서 가능한 것:

- 사용자가 Visual Workspace 앱에서 CEO에게 작업 요청을 입력할 수 있다.
- `Send to CEO`는 Tauri 명령 `agentdock_job_create`를 호출한다.
- Rust/Tauri 쪽은 `agentdock job --no-attach <request>`를 `Command::new(...).args(...)`로 실행한다. shell 문자열 실행은 없다.
- 성공 시 job id/path를 표시하고 `workspace_snapshot`을 다시 읽어 화면을 갱신한다.
- 사용자는 기존 workspace snapshot UI로 active job, selected roles, missing reports, blockers, final readiness, role status를 모니터링할 수 있다.

현재 앱에서 아직 안 되는 것:

- 유저가 앱 안에서 작업 중인 팀에게 변경 지시를 직접 보내는 기능은 없다.
- 앱 안에서 recruit/send/broadcast/finish/report/task-edit 버튼은 없다. 의도적으로 금지되어 있다.
- real sandbox live-click mutation proof는 아직 없다. 현재 증거는 source/test/fake bridge/browser-mocked 수준이며 release-ready proof로는 부족하다.
- action audit panel, facilitation timeline, job history/switcher는 설계/작업카드 수준이며 아직 구현되지 않았다.

따라서 안전한 표현은 다음과 같다:

> Visual Workspace 0.2.0은 앱에서 CEO-led job을 생성하고, snapshot 기반으로 진행 상황을 관찰할 수 있는 첫 controlled-action slice다. 다만 앱에서 작업 중 변경지시를 내리는 제어면은 아직 없으며, release-ready claim에는 real sandbox live-click proof가 추가로 필요하다.

## 2. 내부 로직 변경

### 2.1 CLI / workspace snapshot

- `bin/agentdock`의 workspace snapshot/export 경로가 Visual Workspace 앱에서 소비 가능한 `workspace.snapshot.v1` 계약을 강화했다.
- snapshot metadata에 controlled action 관련 상태를 표현한다.
  - `commands.write_bridge_enabled=false` 유지
  - allowed read commands와 allowed action을 분리해서 표현
- 기존 `.agent-work`를 source of truth로 유지한다. UI local state가 job/report readiness를 임의로 확정하지 않는다.
- adapter/config 처리와 timeout/redaction 관련 안전장치가 강화되었다.

### 2.2 Tauri bridge

신규/변경 파일 중심:

- `src-tauri/src/lib.rs`
- `src-tauri/tauri.conf.json`
- `src-tauri/Cargo.toml`, `Cargo.lock`, `build.rs`, `main.rs`

핵심 변경:

- `workspace_snapshot(project_root)` 명령:
  - 프로젝트 루트를 canonicalize한다.
  - `.agentdock/`, `.agent-work/` 존재를 검증한다.
  - `agentdock workspace snapshot --json --project <root>`를 timeout과 함께 실행한다.
  - stdout/stderr를 redaction 처리한다.
  - schema/JSON 실패 시 error kind를 구조화한다.

- `agentdock_job_create(project_root, request)` 명령:
  - 요청 empty/overlong을 거부한다. 최대 길이: 8000 chars.
  - 프로젝트 루트를 검증한다.
  - 실행 argv는 정확히 `job`, `--no-attach`, `<request>`다.
  - shell bridge를 쓰지 않는다.
  - 성공 출력에서 `JOB-*` id/path를 파싱한다.
  - stdout/stderr/message에 secret redaction을 적용한다.
  - timeout: 30초.

노출된 Tauri invoke handler는 현재 두 개뿐이다:

- `workspace_snapshot`
- `agentdock_job_create`

금지 상태 유지:

- arbitrary shell
- broad write bridge
- direct `.agent-work` mutation from UI/Tauri
- recruit/send/broadcast/finish/report/task-edit UI

### 2.3 React UI

신규/변경 영역:

- `src-ui/App.tsx`
- `src-ui/components/CeoTaskComposer.tsx`
- `src-ui/model/actions.ts`
- `src-ui/model/snapshot.ts`
- `src-ui/model/scene.ts`
- `src-ui/scene/*`
- `src-ui/components/*`
- `src-ui/styles.css`

핵심 변경:

- 앱 진입 시 `workspace_snapshot`을 읽고 5초 간격으로 refresh한다.
- live snapshot 실패 시 last-good snapshot을 유지하고 stale/error 상태를 표시한다.
- unsupported schema는 명확한 오류로 처리한다.
- Visual mode는 Pixel Office / Classic을 제공한다.
- `CeoTaskComposer`가 추가되어 작업 요청을 입력하고 CEO job create를 트리거한다.
- 성공 시 job id/path와 메시지를 보여주고 snapshot refresh를 수행한다.
- Pixel Office 씬에서 role/room/status/report/blocker/final readiness를 시각화한다.
- Dense role navigator로 20/50 role 상황을 필터/검색할 수 있다.

### 2.4 테스트/검증 하네스

추가/강화된 테스트 축:

- `tests/workspace_job_create_bridge.sh`
  - fake agentdock으로 argv shape 검증
  - request가 하나의 argv로 전달되는지 확인
  - shell injection 방지 회귀 테스트

- `tests/workspace_desktop_no_write.sh`
  - 허용 handler가 `workspace_snapshot` + `agentdock_job_create`뿐인지 확인
  - forbidden controls/source tokens를 차단
  - `write_bridge_enabled=false` 유지 확인

- `tests/workspace_security_redaction.sh`
  - API key/secret redaction 확인

- `tests/workspace_desktop_app.sh`, `workspace_reference_a11y.sh`
  - React build output, UI copy, a11y marker, forbidden controls absence 확인

- `tests/workspace_visual_fixtures.sh`, `workspace_visual_scene.sh`
  - workspace fixture schema와 visual scene derivation 검증

- `tests/workspace_native_*`, `workspace_package_artifacts.sh`
  - native screenshot/package evidence 생성과 검증용 하네스

## 3. 기능별 현재 상태 체크

| 기능 | 상태 | 근거 | 남은 점검 |
|---|---|---|---|
| 앱에서 CEO에게 업무 요청 입력 | 구현됨 | `CeoTaskComposer`, `App.createCeoJob` | real sandbox click proof 필요 |
| CEO가 필요한 팀을 생성/작업 수행 | 엔진은 가능, 앱은 job create까지만 트리거 | `agentdock job --no-attach`가 CEO-led job 생성; 이후 CEO pane이 team selection/recruit/tasking 수행 | 실제 앱 클릭으로 sandbox job 생성 증거 필요 |
| 유저의 진행 모니터링 | 부분 구현됨 | snapshot UI가 roles/reports/blockers/final readiness 표시, 5초 refresh | facilitation timeline/action audit/job history는 미구현 |
| 유저의 작업 중 변경지시 | 앱에서는 미구현 | send/broadcast/task-edit controls 의도적으로 금지 | 별도 controlled action slice 필요 |
| 안전 경계 | 구현/검증됨 | no-write, job-create bridge, redaction, build/smoke PASS | release-ready 전 live-click proof 필요 |

## 4. 왜 변경지시는 아직 막아둬야 하나

작업 중 변경지시는 `send`, `broadcast`, `task-card edit`, 혹은 새 controlled action queue가 필요하다. 이들은 현재 `agentdock_job_create`보다 위험도가 높다.

- running pane에 직접 주입되어 작업자를 interrupt할 수 있다.
- 역할별 지시/전체 broadcast는 외부효과가 크다.
- task card edit은 evidence/final report 신뢰성을 흔들 수 있다.
- finish/report 버튼은 lifecycle을 잘못 종료하거나 허위 보고를 만들 수 있다.

따라서 0.2.0은 job create까지만 열고, 변경지시 기능은 별도 slice에서 typed request/result, preview, confirmation, audit, redaction, fake-agentdock regression, no-write/security gate를 갖춘 후 여는 것이 맞다.

## 5. 버전 변경

- `VERSION`: 0.1.8 -> 0.2.0
- `bin/agentdock`: `AGENTDOCK_VERSION=0.2.0`
- `README.md`: badge/status/release example/What's New 갱신
- `package.json`: 0.2.0
- `package-lock.json`: root package 0.2.0
- `src-tauri/tauri.conf.json`: bundle/app version 0.2.0
- `tests/smoke.sh`: version assertion 0.2.0

## 6. Release claim 주의

현재 통과한 것은 source/test controlled-action gate다. 아래가 없으면 release-ready로 쓰면 안 된다.

- real sandbox live-click mutation proof
- main/sandbox `CURRENT.md` before/after proof
- current-job native/releaseProof evidence가 필요한 release claim일 경우 해당 manifest 재생성/readback
- commit/drop 결정 완료

