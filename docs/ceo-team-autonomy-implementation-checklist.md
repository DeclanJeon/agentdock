# CEO 팀 자율작업 완성 체크리스트

작성일: 2026-05-23  
목표: 사용자가 앱에서 작업명령을 내리면 CEO가 작업 성격을 판단하고, 적합한 팀/TFT를 구성하고, 역할별 지시·커뮤니케이션·보고·완료 판정을 유기적으로 진행하도록 부족한 구현을 정리한다.

## 현재 확인된 상태

- UI의 실제 실행 액션은 `Send to CEO` → Tauri `agentdock_job_create` → `agentdock job --no-attach <request>`에 집중되어 있다.
- 데스크톱 브리지는 현재 `workspace_snapshot`, `agentdock_job_create` 중심이다.
- CLI 런타임에는 `job`, `recruit`, `send`, `broadcast`, `inbox/watch`, `job report`, `job finish` 계열이 존재한다.
- UI의 개입 패널은 후속 지시, 브로드캐스트, 리포트, 완료 같은 흐름을 보여주지만 대부분 비활성/미연결 상태다.
- 팀/TFT 구성은 CEO/오케스트레이터 프롬프트와 CLI 명령을 통해 부분적으로 가능하지만, UI에서 결정·추적·재시도할 수 있는 제어면은 아직 부족하다.
- 스냅샷 계약 문서에는 `commands.mode: read-only`가 남아 있으나 현재 스냅샷은 `controlled-actions` 성격을 띤다. 계약과 구현을 맞춰야 한다.
- `agentdock job --help`가 도움말 대신 실제 작업을 생성할 수 있는 위험이 확인되었다.
- coordinator-only 작업에서 required report가 남아도 `final_ready`가 true가 될 수 있는 readiness/report 계약 불일치가 확인되었다.

## P0 — 계약·안전·정합성 먼저 고정

- [x] `agentdock job --help`, `agentdock job -h`, 최상위 `--help`가 실제 작업을 만들지 않도록 CLI help 파싱을 수정한다.
- [x] `workspace_snapshot`의 `commands.mode` 계약을 실제 의도에 맞게 정리한다.
  - [ ] 완전 읽기 전용이면 `read-only` 유지 및 UI 실행 액션 제거.
  - [x] 통제 액션 허용이면 `controlled-actions`와 `allowed_actions` 스키마를 문서화한다.
- [x] `job.final_ready`, `reports.required`, `reports.submitted`, `reports.missing_roles`, `selected_roles` 계산 규칙을 하나의 계약으로 통일한다.
- [x] coordinator/orchestrator 역할이 완료 리포트 의무에서 제외되는지 포함되는지 명시한다.
- [x] coordinator-only 작업의 완료 가능 조건을 정의한다.
- [ ] snapshot fixture 테스트로 readiness/report 모순을 고정한다.
- [x] 모든 UI→Tauri→CLI 액션은 고정 argv만 허용하고 arbitrary shell은 금지한다.
- [x] 프로젝트 루트 검증, 경로 검증, 타임아웃, 출력 길이 제한, 비밀정보 redaction을 각 액션 공통 규칙으로 적용한다.
- [ ] 샌드박스/테스트 작업이 실제 `CURRENT.md`를 덮어쓰지 않도록 격리 전략을 만든다.

## P1 — CEO 명령 이후의 최소 유기 작업 루프

### 작업 분석·팀 구성

- [x] 작업명령을 capability로 분류하는 `JobIntent` 모델을 만든다.
  - 예: product, ux, architecture, frontend, backend, qa, delivery, security, docs, research.
- [x] `JobIntent`를 기반으로 최소 유효 팀을 산출하는 `TeamPlan` 모델을 만든다.
- [ ] 실행 중인 역할, 설정된 역할 템플릿, 이미 선택된 역할을 반영해 재사용 우선 팀 구성을 구현한다.
- [ ] 필요한 역할이 없으면 recruit 후보와 이유를 제안한다.
- [x] 임시 TFT/서브팀 개념을 `TEAM.md`와 snapshot에 표현한다.
  - 예: `TFT: Visual UI`, `TFT: Runtime Safety`, `TFT: QA Gate`.
- [ ] 역할별 책임, 입력, 산출물, 완료 조건, 보고 명령을 task card로 생성한다.

### 커뮤니케이션

- [x] CEO 후속 지시를 오케스트레이터에게 보내는 안전 액션을 구현한다.
- [x] 선택된 팀 전체 브로드캐스트 액션을 구현한다.
- [x] 특정 역할에게 직접 메시지를 보내는 액션을 구현한다.
- [ ] 메시지 템플릿에 job id, 역할, 작업명령, acceptance criteria, report command를 자동 포함한다.
- [ ] inbox/event timeline에 발신자, 수신자, 액션 종류, 상태를 표시한다.
- [x] blocker/escalation 메시지를 감지해 UI에서 우선 표시한다.
- [x] stale role heartbeat를 감지하고 재촉/재할당 후보를 제안한다.

### 진행·보고·완료

- [x] 역할별 리포트 제출 여부를 selected team 기준으로 정확히 계산한다.
- [x] 누락 리포트가 있으면 완료 버튼을 비활성화하고 누락 역할을 명확히 보여준다.
- [x] `job report` 제출을 UI에서 안내하거나 통제 액션으로 연결한다.
- [x] `job finish`는 readiness preview를 먼저 보여주고, 조건 충족 시에만 실행한다.
- [x] 완료 후 job history에 결과 요약, 리포트, 주요 이벤트를 보존한다.

## P2 — UI 제어면 확장

- [x] `InterventionPanel`의 비활성 버튼을 실제 slice별 액션으로 연결한다.
- [x] 액션 버튼마다 상태를 구분한다: unavailable, preview, running, succeeded, failed.
- [ ] 버튼 내부 텍스트 정렬과 반응형 폭을 유지한다.
- [x] 후속 지시 입력창, 대상 선택, preview, 실행 결과 로그를 제공한다.
- [x] recruit 후보 카드와 역할별 이유를 표시한다.
- [ ] task card diff preview를 표시하고 직접 파일 mutation은 초기에는 금지한다.
- [x] inspector 탭을 실제 데이터에 연결한다: summary, team, tasks, inbox, reports, logs.
- [ ] timeline/job history에서 최근 작업과 현재 작업을 전환할 수 있게 한다.
- [ ] 액션 감사 로그를 세션 UI와 작업 artifact 양쪽에 남긴다.

## P2 — Tauri 브리지 액션 후보

각 액션은 별도 slice로 구현하고 테스트까지 끝낸 뒤 다음 액션으로 넘어간다.

- [x] `agentdock_job_followup(job_id, message)` → `agentdock send orchestrator <message>` 또는 전용 CLI.
- [x] `agentdock_team_broadcast(job_id, message)` → `agentdock broadcast <message>`.
- [x] `agentdock_role_send(job_id, role, message)` → `agentdock send <role> <message>`.
- [x] `agentdock_recruit_preview(job_id, role_or_capability)` → 변경 예정 역할/파일/명령 preview.
- [x] `agentdock_recruit_role(job_id, role, template, reason)` → `agentdock recruit ...`.
- [x] `agentdock_task_proposal(job_id, role, task_spec)` → task card diff preview 생성.
- [x] `agentdock_finish_preview(job_id)` → readiness/report/blocker preview.
- [x] `agentdock_job_finish(job_id)` → 조건 충족 시 `agentdock job finish`.

## P3 — 자율성 강화

- [ ] CEO가 작업 유형에 따라 팀 구성을 자동 제안하는 planner를 구현한다.
- [x] 오케스트레이터가 TFT를 만들 때 snapshot에 TFT 이름, 멤버, 목표, 상태가 드러나게 한다.
- [ ] 역할 간 의존성을 task card와 timeline에 표시한다.
- [ ] 보고서 내용을 합쳐 CEO final summary를 생성한다.
- [ ] 작업 실패/블로커 발생 시 재계획 또는 추가 recruit 후보를 제안한다.
- [ ] 반복 작업에서 이전 job history를 참고해 팀 구성을 개선한다.

## 필수 검증

- [x] `npm run build`
- [x] Rust/Tauri unit tests for fixed argv, timeout, redaction, path validation.
- [ ] fake `agentdock` 기반 UI invoke 테스트.
- [ ] snapshot fixture tests for readiness, reports, selected roles, TFTs.
- [ ] sandbox native live-click evidence for each new action slice.
- [x] no arbitrary shell / no broad write bridge 검증.
- [ ] browser fallback 상태에서도 UI가 깨지지 않는지 확인.
- [ ] 390px, 768px, 1024px, 1440px 반응형 스크린샷 확인.

## 완료 기준

- 사용자는 앱에서 작업명령을 보낸 뒤 현재 팀, 역할별 임무, TFT, 진행 상태, 누락 보고, 블로커, 완료 가능 여부를 한 화면에서 이해할 수 있다.
- CEO/오케스트레이터는 필요한 역할을 선택·모집하고, 역할별 지시와 팀 브로드캐스트를 수행하며, 보고를 수집하고, 완료 조건을 만족할 때만 작업을 종료한다.
- UI는 CLI의 자율작업 기능을 안전한 통제 액션으로 노출하되 arbitrary shell이나 무제한 파일 쓰기를 제공하지 않는다.
