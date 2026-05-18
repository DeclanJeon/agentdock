# Handoff Review Protocol

수신 팀은 handoff를 받으면 바로 작업하지 않는다. 먼저 작업 가능한 수준인지 검토한다.

## Review Checklist

- 필요한 입력 문서가 모두 있는가?
- 완료 기준이 명확한가?
- 모호한 요구사항이 있는가?
- 역할 경계에 맞는 요청인가?
- API/데이터/상태/예외 조건이 충분한가?
- 디자인/개발/QA에 필요한 참고자료가 있는가?
- 작업량이 task 단위로 충분히 쪼개졌는가?

## Review Decision

- ACCEPTED: 작업 가능
- NEEDS_CLARIFICATION: 질문 필요
- REVISION_REQUIRED: 원 담당 팀 수정 필요
- REJECTED_WRONG_TEAM: 다른 팀으로 라우팅 필요

## Rule

모호한 handoff를 받은 에이전트는 추측해서 구현하지 않는다.
