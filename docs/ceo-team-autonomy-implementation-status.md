# CEO 팀 자율작업 구현 진행 상태

작성일: 2026-05-23

## 이번 구현에서 완료한 항목

- Phase 0 안전 계약
  - `agentdock job --help` / `-h`가 실제 job을 만들지 않도록 수정했다.
  - snapshot report 계산을 selected 전체와 selected non-coordinator worker report로 분리했다.
  - `reports.selected_roles`를 추가하고 `required_selected_roles`는 worker report 필요 수로 고정했다.
  - `commands.allowed_actions`를 실제 통제 액션 후보 목록으로 확장했다.
  - `workspace-snapshot-ui-contract.md`를 read-only 95% 계약에서 controlled-actions 계약으로 갱신했다.
- TeamPlan/TFT 관찰 모델
  - snapshot에 `team_plan`, `tfts` 필드를 추가했다.
  - `src-ui/model/teamPlan.ts`에서 작업 텍스트/상태 기반 capability와 팀 추천 모델을 추가했다.
  - UI 개입 콘솔에 coordinator, selected roles, TFT, 추천 recruit/reuse 정보를 표시한다.
- Tauri 통제 액션
  - `agentdock_job_followup`
  - `agentdock_team_broadcast`
  - `agentdock_role_send`
  - `agentdock_recruit_preview`
  - `agentdock_recruit_role`
  - `agentdock_task_proposal`
  - `agentdock_finish_preview`
  - `agentdock_job_finish`
- UI 연결
  - `InterventionPanel`의 비활성 preview 버튼을 실제 form/action으로 교체했다.
  - action running/success/failure 결과를 audit log와 panel에 표시한다.
  - recruit는 preview와 execute를 분리했다.
  - task card 직접 수정은 하지 않고 coordinator에게 proposal 메시지로 보낸다.
  - finish는 snapshot final-ready가 true일 때만 execute 버튼을 활성화한다.
  - Scene inspector tabs가 실제 Tasks/Details/Files/Logs 패널을 전환한다.

## 아직 남은 항목

- 실제 native live-click으로 CEO job-create와 신규 controlled action GUI matrix를 검증했다.
- `job history` 전환 UI와 완료 job archive viewer.
- role heartbeat/stale 감지와 자동 재촉/재할당 제안.
- richer TFT 멤버/목표/상태 parser. 현재는 `TEAM.md`의 `TFT:` 라인을 최소 추출한다.
- task card writer는 아직 의도적으로 미구현이다. 현재는 proposal-only 안전 흐름이다.

## 검증 결과

- `bash -n bin/agentdock` 통과.
- `bin/agentdock job --help` 전후 JOB 디렉터리 수 동일: 31 → 31.
- `bin/agentdock workspace snapshot --json` JSON 계약 확인 통과.
- `cargo test --manifest-path src-tauri/Cargo.toml`: 11 passed.
- `npm run build`: 통과.

## 추가 구현 라운드 — 2026-05-23

완료:

- `history.recent_jobs` snapshot payload를 추가해 최근 `JOB-*` 기록, lifecycle, report count, final report, request preview를 bounded read-only로 제공한다.
- `JobHistoryPanel`을 UI에 추가했다. 이전 작업은 inspect-only로 표시하며 `CURRENT.md`를 변경하지 않는다.
- `stale_role` alert를 snapshot에 추가했다. selected worker role이 report 없이 오래 멈춰 있으면 follow-up/reassign next action을 노출한다.
- Top HUD에 heartbeat/stale count와 blocker count를 추가했다.
- TFT parser를 확장해 `TFT: <name> | members: a,b | goal: ... | status: ...` 형태를 `members`, `goal`, `status`로 표시할 수 있게 했다.
- `agentdock_job_report` Tauri 통제 액션과 UI report submit form을 연결했다.
- `tests/workspace_controlled_actions_contract.sh`를 추가해 Tauri/UI/CLI 통제 액션 계약을 고정했다.
- `tests/workspace_desktop_no_write.sh`를 controlled-actions 계약에 맞게 갱신하되, snapshot read가 `.agent-work`/`.agentdock`을 수정하지 않는 검증은 유지했다.

검증:

- `bash -n bin/agentdock`
- `bin/agentdock workspace snapshot --json` + `python3 -m json.tool`
- `bash tests/workspace_controlled_actions_contract.sh`
- `bash tests/workspace_desktop_no_write.sh`
- `cargo test --manifest-path src-tauri/Cargo.toml`
- `npm run build`

남은 항목:

- 신규 controlled action 전체 GUI matrix를 AT-SPI native click으로 확장했다. follow-up/broadcast/role-send/recruit/task-proposal/report/finish non-preview 7개 CLI command와 preview 2개 버튼이 sandbox에서 검증됐다.
- task card 직접 writer는 여전히 의도적으로 미구현이다. 안전 흐름은 proposal-only이다.

## Release proof 라운드 — 2026-05-23

완료:

- AT-SPI native live-click driver로 실제 Tauri UI의 `CEO TASK REQUEST` 입력과 `Send to CEO` 버튼 액션을 수행해 sandbox job 생성 증거를 갱신했다.
- native screenshot harness가 `AGENTDOCK_RELEASE_MATRIX_JOB_ID`/`AGENTDOCK_NATIVE_SCREENSHOT_JOB_ID`를 존중하도록 수정해 current-job release evidence와 output job id를 일치시켰다.
- `AGENTDOCK_REQUIRE_RELEASE_PROOF=1` 조건에서 native screenshot manifest `releaseProof=true`, 12/12 captured를 확인했다.
- full release matrix를 다시 실행해 21/21 gate PASS를 확보했다.

검증:

- `AGENTDOCK_RUN_LIVE_CLICK=1 AGENTDOCK_REQUIRE_RELEASE_PROOF=1 AGENTDOCK_NATIVE_RUNTIME_CONFIRMED=1 ... bash tests/workspace_release_matrix.sh ...`
- Final matrix: `.agent-work/07_JOBS/JOB-260522190004397678/OUTPUTS/release-matrix-final-proof-20260523/workspace-release-matrix.json`
- Live-click evidence: `.agent-work/07_JOBS/JOB-260522190004397678/OUTPUTS/live-click-evidence/live-click-evidence.json`
- Native manifest: `.agent-work/07_JOBS/JOB-260522190004397678/OUTPUTS/native-evidence/workspace-native-screenshot-manifest.json`

## Controlled action native matrix 라운드 — 2026-05-23

완료:

- `InterventionPanel`을 기본 펼침 상태로 두고 각 입력/버튼에 native automation용 명확한 accessible label을 부여했다.
- snapshot 로드 이후 selected role/recruit recommendation 상태가 빈 값으로 남아 버튼이 비활성화되는 문제를 useEffect 동기화로 수정했다.
- 사용자 편의를 위해 follow-up/broadcast/role-send/task-proposal/report에 editable preset 문구를 제공해, 무엇을 보낼지 바로 보고 수정할 수 있게 했다.
- `tests/workspace_controlled_actions_native_matrix.sh`를 추가해 release Tauri 앱에서 AT-SPI native button action으로 전체 controlled action 표면을 클릭한다.

검증:

- Controlled action native matrix: `.agent-work/07_JOBS/JOB-260522190004397678/OUTPUTS/controlled-actions-native-matrix/controlled-actions-native-matrix.json` (`status=pass`, `nativeClick=true`, observed CLI commands 7).
- `bash tests/workspace_controlled_actions_native_matrix.sh`
- `bash tests/workspace_controlled_actions_contract.sh`
- `bash tests/workspace_job_create_bridge.sh`
- `bash tests/workspace_reference_a11y.sh`
- `cargo test --manifest-path src-tauri/Cargo.toml`
- `npm run tauri:build`
