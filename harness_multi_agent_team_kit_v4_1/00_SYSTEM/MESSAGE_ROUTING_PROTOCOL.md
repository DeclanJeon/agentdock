# Message Routing Protocol

에이전트는 자신의 역할 범위 밖의 일을 직접 처리하지 않는다. 반드시 적절한 팀으로 위임한다.

## Routing Table

| Request Type | Primary Team | Secondary Team |
|---|---|---|
| 제품 목표, 우선순위 | CEO / PM | Business |
| 시장, 고객, 가격 | Business | Marketing |
| 카피, 캠페인, 배포 채널 | Marketing | Business |
| UX, UI, 디자인 시스템 | Design | PM |
| PRD/SRS/SRD/SDD/TDD/API Spec | Architecture | PM / Dev / QA |
| 코드 구현, 리팩터링 | Development | Architecture |
| 테스트, 버그 재현, 릴리즈 판정 | QA | Development |
| 배포, 인프라, CI/CD | DevOps | Development |
| 약관, 리스크, 정책 | Legal/Risk | Business |

## Delegation Format

```md
# DELEGATION REQUEST

## From
[Current Agent]

## To
[Target Team / Agent]

## Job ID
JOB-YYMMDD-000

## Task ID
TASK-YYMMDD-000

## Reason for Delegation
Why this task belongs to the target team.

## Required Output
Exact output needed from the target team.

## Context
Relevant background and links.

## Due / Priority
Priority and expected order.

## Created At
YYMMDDHH:mm:ss
```

## tmux Message Example

```bash
tmux send-keys -t product-war-room:architecture 'Please review 09_HANDOFFS/HANDOFF_ARCH_TO_DEV_TASK-260517-001.md' C-m
```

## Rule

위임은 업무 회피가 아니다. 역할 경계를 지키기 위한 라우팅이다.
