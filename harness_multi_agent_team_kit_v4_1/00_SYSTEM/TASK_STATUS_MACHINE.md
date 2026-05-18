# Task Status Machine

모든 팀과 에이전트는 task 상태를 아래 값 중 하나로만 기록한다.

## Status Values

| Status | Meaning | Owner Action |
|---|---|---|
| BACKLOG | 아직 착수 전 후보 작업 | CEO/PM이 우선순위 판단 |
| READY | 작업 가능한 수준으로 정의됨 | 담당 팀 배정 가능 |
| ASSIGNED | 담당 팀/에이전트가 지정됨 | 담당자는 체크리스트 작성 |
| IN_PROGRESS | 실제 작업 중 | TASK_LOG에 진행 기록 |
| BLOCKED | 외부 입력 없이는 진행 불가 | BLOCKER와 필요한 결정을 기록 |
| IN_REVIEW | 산출물 검토 중 | 수신 팀이 handoff review 수행 |
| REVISION_REQUIRED | 수정 필요 | 원 담당 팀이 재작업 |
| DELEGATED | 다른 팀으로 위임됨 | 위임 사유와 수신 팀 기록 |
| DONE | 완료 기준 충족 | COMPLETION_REPORT 작성 |
| CANCELLED | 작업 취소 | 취소 사유 기록 |

## Required Timestamp Format

```txt
YYMMDDHH:mm:ss
예: 26051714:32:09
```

## Required Fields in Every Task

- Task ID
- Job ID
- Status
- Owner Team
- Owner Agent
- Created At
- Updated At
- Scope
- Non-Scope
- Inputs
- Outputs
- Definition of Done
- Change Log Reference
- Completion Report Reference

## State Transition Rules

- BACKLOG → READY: 요구사항, 산출물, 완료 기준이 정의된 경우
- READY → ASSIGNED: 담당 팀과 담당 에이전트가 지정된 경우
- ASSIGNED → IN_PROGRESS: 담당자가 WORK_CHECKLIST를 작성한 경우
- IN_PROGRESS → IN_REVIEW: 산출물이 생성되고 self-check가 끝난 경우
- IN_REVIEW → DONE: 수신 팀 또는 CEO가 완료를 승인한 경우
- IN_REVIEW → REVISION_REQUIRED: 누락/모호성/품질 문제가 발견된 경우
- Any → BLOCKED: 입력 부족, 결정 필요, 충돌 발생
- Any → DELEGATED: 역할 경계 밖의 작업으로 판단된 경우
- Any → CANCELLED: 더 이상 필요하지 않은 작업인 경우
