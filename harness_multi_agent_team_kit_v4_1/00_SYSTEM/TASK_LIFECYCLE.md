# Task Lifecycle

모든 업무는 아래 생명주기를 따른다.

```txt
REQUESTED → TRIAGED → ASSIGNED → CHECKLIST_CREATED → IN_PROGRESS → REVIEW_READY → HANDOFF_READY → DONE
                       ↘ BLOCKED ↗
```

## Status Definition

| Status | Meaning |
|---|---|
| REQUESTED | 요청만 들어온 상태 |
| TRIAGED | CEO/PM이 업무 성격을 판단한 상태 |
| ASSIGNED | 특정 팀/에이전트에게 배정된 상태 |
| CHECKLIST_CREATED | 담당자가 작업 체크리스트를 작성한 상태 |
| IN_PROGRESS | 실제 작업 중 |
| BLOCKED | 입력, 권한, 의사결정, 의존성이 막힌 상태 |
| REVIEW_READY | 담당 팀 내부 검토가 가능한 상태 |
| HANDOFF_READY | 다음 팀에게 넘길 준비가 된 상태 |
| DONE | 완료 보고까지 끝난 상태 |

## Task ID Rule

```txt
TASK-{YYMMDD}-{team}-{sequence}
```

예시:

```txt
TASK-260517-ARCH-001
TASK-260517-DEV-003
TASK-260517-QA-002
```

## Job vs Task

- Job: 하나의 큰 목표 단위. 예: `YouTube Shorts 자동 편집 MVP 설계`
- Task: Job을 수행하기 위한 작은 작업 단위. 예: `API Spec 작성`, `Caption pipeline 설계`

## Required Task Fields

- Task ID
- Parent Job ID
- Owner Team
- Owner Agent
- Requested At
- Accepted At
- Started At
- Completed At
- Status
- Original Scope
- Current Scope
- Added Tasks
- Removed Tasks
- Modified Tasks
- Output Files
- Next Receiver
