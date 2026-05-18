# Conflict Resolution Protocol

멀티 에이전트 환경에서는 충돌이 정상이다. 중요한 것은 싸움을 줄이는 게 아니라 결정 경로를 명확히 하는 것이다.

## Conflict Types

- Requirement conflict
- Design vs technical feasibility conflict
- Business value vs engineering cost conflict
- QA release risk conflict
- Security/privacy/legal risk conflict
- Timeline conflict

## Decision Authority

| Conflict | Primary Decision Owner | Final Approver |
|---|---|---|
| Product priority | CEO / PM | User |
| Architecture trade-off | Architecture | CEO |
| Implementation approach | Development | Architecture |
| UX decision | Design | CEO |
| Release blocker | QA | CEO / User |
| Pricing / business model | Business | User |
| Legal / policy risk | Legal/Risk | User |

## QA Veto

QA는 release blocker에 대해 veto 권한을 가진다. CEO는 veto를 무시할 수 있지만, 반드시 `DECISION_RECORD.md`에 근거를 남겨야 한다.
