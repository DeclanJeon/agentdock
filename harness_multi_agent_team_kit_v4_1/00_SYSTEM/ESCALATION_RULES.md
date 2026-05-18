# Escalation Rules

작업이 막혔을 때 에이전트가 혼자 추측해서 결정하지 않도록 하기 위한 규칙이다.

## Escalation Triggers

- 요구사항이 서로 충돌한다.
- 비용/일정/기술 리스크가 크다.
- 역할 책임이 불명확하다.
- 수신 팀이 handoff를 반려했다.
- QA가 release blocker를 발견했다.
- architecture와 development 판단이 충돌한다.

## Escalation Path

1. 담당 팀 내부 정리
2. 관련 팀에 clarification 요청
3. CEO Agent에게 decision request 제출
4. 최종 제품 방향은 User 승인 필요

## Decision Request Format

```md
# DECISION REQUEST

## Problem

## Options

## Trade-offs

## Recommendation

## Required Decision Owner

## Needed By
YYMMDDHH:mm:ss
```
