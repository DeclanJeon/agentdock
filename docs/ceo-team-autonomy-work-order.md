# CEO 팀 자율작업 완성 작업지시서

작성일: 2026-05-23  
대상: AgentDock visual workspace / Tauri bridge / `bin/agentdock` runtime  
목표: “앱에서 작업명령 입력 → CEO가 팀/TFT 구성 → 역할별 지시 → 팀 커뮤니케이션 → 보고 수집 → 완료 판정” 흐름을 안전하고 검증 가능한 제품 기능으로 완성한다.

## 작업 원칙

1. 한 번에 하나의 통제 액션만 추가한다.
2. UI는 arbitrary shell을 절대 열지 않는다.
3. Tauri 명령은 고정 argv, 검증된 role/job id, timeout, redaction을 기본값으로 한다.
4. CLI 런타임이 이미 가진 기능을 재사용하고, UI는 안전한 제어면과 관찰면을 제공한다.
5. 각 단계는 테스트와 native evidence를 남긴 뒤 다음 단계로 넘어간다.
6. 실제 사용자 작업의 `CURRENT.md`를 테스트가 오염시키지 않도록 sandbox job 또는 fixture를 사용한다.

## 관련 파일

- `bin/agentdock` — job/recruit/send/broadcast/report/finish CLI 런타임.
- `src-tauri/src/lib.rs` — Tauri invoke command와 CLI 실행 브리지.
- `src-ui/App.tsx` — job 생성, snapshot 수신, 전체 상태 조립.
- `src-ui/components/CeoTaskComposer.tsx` — CEO 작업명령 입력.
- `src-ui/components/InterventionPanel.tsx` — 후속 지시/브로드캐스트/완료 제어면.
- `src-ui/model/snapshot.ts` — workspace snapshot 타입/계약.
- `src-ui/model/actions.ts` — UI action 타입 후보.
- `src-ui/model/scene.ts` — 역할/팀/상태 표시 모델.
- `docs/workspace-snapshot-ui-contract.md` — snapshot 계약 문서.
- `docs/ceo-team-autonomy-implementation-checklist.md` — 구현 체크리스트.

## Phase 0 — 기준선 정합성 복구

### 작업

- `agentdock job --help`가 job을 만들지 않도록 CLI help 처리 수정.
- snapshot의 `commands.mode` 계약과 실제 구현을 일치시킴.
- `final_ready`와 report 계산 규칙을 재정의하고 구현/문서/테스트를 맞춤.
- coordinator/orchestrator 리포트 의무 포함 여부를 명시.

### 산출물

- CLI help regression test.
- snapshot readiness/report fixture test.
- 갱신된 `docs/workspace-snapshot-ui-contract.md`.

### 승인 기준

- `agentdock job --help` 실행 후 새 job 디렉터리가 생성되지 않는다.
- required report가 남아 있으면 `final_ready`가 true로 표시되지 않는다.
- 계약 문서와 snapshot payload가 같은 용어를 사용한다.

## Phase 1 — JobIntent / TeamPlan 설계 모델

### 작업

- 작업명령을 capability 목록으로 분류하는 `JobIntent` 타입을 정의한다.
- capability를 role/TFT 후보로 변환하는 `TeamPlan` 타입을 정의한다.
- role template, running roles, selected roles를 반영해 “재사용 우선, 부족하면 recruit” 규칙을 만든다.
- TEAM/task card에 들어갈 필드와 snapshot 확장 필드를 정의한다.

### 산출물

- 타입/계약 문서 또는 TS/Rust 모델 초안.
- fixture: UI 리디자인 요청, 백엔드 버그 요청, QA 요청, 릴리즈 요청에 대한 TeamPlan 예시.

### 승인 기준

- 같은 요청에서 항상 재현 가능한 최소 팀 후보가 나온다.
- 역할 선택 이유와 TFT 목적이 UI에 표시 가능한 구조로 나온다.

## Phase 2 — CEO 후속 지시 액션

### 작업

- Tauri `agentdock_job_followup(job_id, message)` 구현.
- 고정 argv로 오케스트레이터에게 후속 지시 전송.
- `InterventionPanel`에 후속 지시 입력, preview, running/success/failure 상태 연결.
- action audit log를 snapshot/timeline에 노출.

### 산출물

- Rust command test.
- fake CLI invoke test.
- UI 상태 테스트 또는 수동 native evidence.

### 승인 기준

- 사용자가 현재 job에 후속 지시를 보내면 오케스트레이터 inbox/event에 기록된다.
- 잘못된 job id, 빈 메시지, 과도한 길이, 비밀정보 포함 출력이 안전하게 처리된다.

## Phase 3 — 팀 브로드캐스트와 역할 직접 메시지

### 작업

- `agentdock_team_broadcast(job_id, message)` 구현.
- `agentdock_role_send(job_id, role, message)` 구현.
- UI에서 대상 선택: selected team 전체 또는 특정 역할.
- blocker/escalation 메시지를 timeline 상단에 강조.

### 산출물

- role allowlist 검증 테스트.
- selected team이 없을 때 비활성 상태 테스트.
- 메시지 audit log.

### 승인 기준

- 선택된 팀 전체에 브로드캐스트가 전달된다.
- 특정 역할에게 직접 지시가 전달된다.
- 존재하지 않는 role이나 현재 job 밖의 role은 실행되지 않는다.

## Phase 4 — Recruit / TFT 형성

### 작업

- `agentdock_recruit_preview`로 역할 모집 변경사항을 먼저 보여준다.
- `agentdock_recruit_role`로 검증된 template/role만 모집한다.
- CEO/오케스트레이터가 제안한 TFT를 `TEAM.md`와 snapshot에 기록한다.
- UI에 recruit 후보 카드와 TFT 멤버십을 표시한다.

### 산출물

- template allowlist.
- recruit preview fixture.
- TFT snapshot fixture.

### 승인 기준

- 작업 성격에 필요한 미실행 역할을 안전하게 모집할 수 있다.
- 모집된 역할은 selected team/TFT/task card에 연결된다.
- UI는 “왜 이 역할이 필요한지”를 보여준다.

## Phase 5 — Task card 생성/수정 제어면

### 작업

- 역할별 task card 스키마를 정리한다: owner, mission, inputs, steps, acceptance criteria, report command.
- UI에서 task proposal diff preview를 제공한다.
- 초기 버전은 직접 파일 쓰기보다 오케스트레이터에게 task proposal을 보내는 방식으로 구현한다.
- 이후 안전성이 확보되면 제한된 task card writer를 별도 slice로 검토한다.

### 산출물

- task card fixture.
- proposal diff preview UI.
- task proposal audit event.

### 승인 기준

- 사용자는 역할별 해야 할 일과 완료 조건을 UI에서 확인할 수 있다.
- task 변경은 preview 없이 조용히 파일을 바꾸지 않는다.

## Phase 6 — Report / Finish gate

### 작업

- `agentdock_finish_preview(job_id)` 구현.
- readiness 조건을 UI에 상세 표시: missing reports, blockers, stale roles, incomplete tasks.
- 조건 충족 시 `agentdock_job_finish(job_id)` 활성화.
- 완료 후 job history와 final summary를 표시한다.

### 산출물

- finish preview fixture.
- finish blocked/allowed 테스트.
- final summary UI.

### 승인 기준

- 누락 리포트나 blocker가 있으면 완료할 수 없다.
- 완료 가능한 상태에서는 사용자가 안전하게 finish를 실행할 수 있다.
- 완료 후 결과가 timeline/history에 남는다.

## Phase 7 — 관찰성·반응형·제품 품질 마감

### 작업

- inspector 탭을 실제 team/tasks/inbox/reports/logs 데이터에 연결한다.
- job history 전환과 현재 job 복귀를 제공한다.
- stale heartbeat, missing report, blocker badge를 HUD와 캐릭터 상태에 연결한다.
- 반응형 레이아웃과 버튼 텍스트 정렬을 재검증한다.
- 브라우저 fallback에서도 Tauri 없음 오류가 제품 UI를 깨지 않도록 처리한다.

### 산출물

- responsive screenshots: 390px, 768px, 1024px, 1440px.
- native live-click screenshots per action.
- build/test 로그.

### 승인 기준

- 작은 화면에서도 버튼 텍스트가 잘리지 않고 주요 액션이 접근 가능하다.
- 사용자는 현재 작업 상태와 다음으로 필요한 액션을 명확히 이해한다.

## 작업 순서 요약

1. P0 계약 버그 수정: help/job 생성, readiness/report, snapshot contract.
2. JobIntent/TeamPlan/TFT 모델 확정.
3. 후속 지시 액션 연결.
4. 브로드캐스트/역할 직접 메시지 연결.
5. recruit preview/execute와 TFT 표시 연결.
6. task proposal/diff preview 연결.
7. finish preview/execute와 final summary 연결.
8. inspector/history/badge/responsive QA 마감.

## 테스트 명령 후보

```bash
npm run build
cargo test --manifest-path src-tauri/Cargo.toml
bin/agentdock job --help
bin/agentdock workspace snapshot --json
```

프로젝트에 테스트 스크립트가 추가되면 각 phase별 fake CLI / fixture / native live-click 검증 명령을 이 섹션에 갱신한다.

## 리스크와 대응

- 리스크: UI에서 너무 많은 CLI 기능을 한 번에 열면 안전 경계가 흐려진다.  
  대응: 한 slice에 한 액션, fixed argv, allowlist, preview 우선.
- 리스크: 실제 작업 디렉터리를 테스트가 오염시킨다.  
  대응: sandbox job root 또는 fixture snapshot을 사용한다.
- 리스크: CEO 자동 팀 구성이 과도하거나 불안정하다.  
  대응: deterministic TeamPlan과 “왜 이 역할인지” 설명을 필수화한다.
- 리스크: 완료 조건이 역할/리포트 정책과 충돌한다.  
  대응: P0에서 readiness/report 계약을 먼저 고정한다.
