# Work Logging Protocol

모든 팀과 에이전트는 작업을 말로만 끝내지 않는다. 반드시 체크리스트, 작업 로그, 변경 이력, 완료 보고서를 남긴다.

## Timestamp Standard

모든 로그는 아래 형식을 사용한다.

```txt
YYMMDDHH:mm:ss
```

예시:

```txt
26051714:32:09
```

사용자가 `yymmddSS:ss`라고 표현하더라도, 실무 기록에서는 날짜/시/분/초를 포함한 `YYMMDDHH:mm:ss`를 표준으로 삼는다.

## Required Files Per Task

각 task는 최소 다음 파일을 가진다.

```txt
tasks/{task-id}/
├── TASK_BRIEF.md
├── WORK_CHECKLIST.md
├── TASK_LOG.md
├── TASK_CHANGELOG.md
├── COMPLETION_REPORT.md
└── HANDOFF.md
```

## Required Logging Events

아래 이벤트는 반드시 `TASK_LOG.md`에 남긴다.

- task created
- task accepted
- checklist created
- work started
- assumption added
- dependency discovered
- delegation requested
- file created
- file modified
- task added
- task removed
- task changed
- blocked
- unblocked
- review requested
- review completed
- handoff created
- task completed

## Checklist Rule

작업 시작 전, 담당 팀은 `WORK_CHECKLIST.md`를 먼저 작성한다.

체크리스트는 다음을 포함한다.

- 작업 범위
- 하지 않을 일
- 산출물 목록
- 검증 방법
- 위임 조건
- 완료 기준

## Task Change Rule

작업 중 task가 추가, 삭제, 수정되면 `TASK_CHANGELOG.md`에 즉시 기록한다.

변경 기록에는 반드시 다음이 들어간다.

- timestamp
- changed by
- change type: ADDED / REMOVED / MODIFIED
- before
- after
- reason
- approval owner
- impact

## Completion Rule

작업 완료 시 `COMPLETION_REPORT.md`에 다음을 남긴다.

- 완료 timestamp
- 실제 수행한 일
- 최초 task 구성
- 최종 task 구성
- 추가된 task
- 삭제된 task
- 수정된 task
- 생성/수정 파일
- 미해결 이슈
- 다음 수신 팀
- 인수인계 링크

## CEO Audit Rule

CEO Agent는 각 팀의 완료 보고서를 검토하고 다음을 확인한다.

- 체크리스트가 존재하는가?
- 완료 시간이 기록되었는가?
- task 변경 이력이 기록되었는가?
- 산출물이 다음 팀이 바로 사용할 수 있는가?
- 역할 밖 작업을 무단 수행하지 않았는가?
