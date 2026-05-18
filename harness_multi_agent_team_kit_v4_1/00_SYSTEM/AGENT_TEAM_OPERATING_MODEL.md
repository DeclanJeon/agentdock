# Agent Team Operating Model

## 1. 운영 모델

멀티 에이전트 팀은 회사 조직처럼 움직인다. 단, 모든 팀이 직접 대화로 섞이면 소음이 폭발한다. 그래서 **CEO 에이전트가 허브**가 되고, 각 팀은 산출물 단위로 소통한다.

```txt
User
  ↓ 요구/피드백
CEO / Orchestrator
  ├─ Planning / PM
  ├─ Business
  ├─ Marketing
  ├─ Architecture
  ├─ Development
  ├─ Design
  ├─ QA
  ├─ DevOps
  └─ Legal / Risk
```

## 2. 기본 작업 흐름

1. User가 문제, 목표, 제약, 원하는 결과물을 제시한다.
2. CEO가 업무를 분해한다.
3. CEO가 필요한 팀과 에이전트 수를 결정한다.
4. 각 팀은 자기 역할의 산출물만 만든다.
5. 역할 밖 요청은 직접 처리하지 않고 위임한다.
6. 산출물은 handoff 형식으로 다음 팀에 전달한다.
7. QA가 검증하고, CEO가 최종 통합한다.

## 3. 하네스 구성요소

| 구성요소 | 목적 | 예시 |
|---|---|---|
| Role Prompt | 에이전트 정체성 고정 | `CEO_AGENT.md`, `QA_AGENT.md` |
| Skill File | 반복 업무 절차화 | `WRITE_PRD.md`, `RUN_QA.md` |
| Context File | 프로젝트 지식 저장 | `PROJECT_CONTEXT.md` |
| Tool Boundary | 권한 제한 | 개발팀은 코드 수정, QA는 검증만 |
| Handoff Protocol | 팀 간 인수인계 | `HANDOFF.md` |
| Quality Gate | 산출물 승인 기준 | 테스트 통과, 요구사항 충족 |
| Memory Rule | 기록/폐기 기준 | 결정은 ADR, 임시 생각은 scratch |

## 4. 에이전트별 금지 원칙

- CEO는 코드를 직접 짜지 않는다. 개발팀에 위임한다.
- 개발팀은 제품 방향을 임의로 바꾸지 않는다. PM/CEO에게 질문한다.
- 디자인팀은 백엔드 구조를 결정하지 않는다. 아키텍처팀에 위임한다.
- QA팀은 코드를 고치지 않는다. 버그를 재현하고 보고한다.
- 마케팅팀은 법적 효능을 단정하지 않는다. Legal/Risk에 검토를 요청한다.
- 유저 에이전트는 해결책을 설계하지 않는다. 불편함, 맥락, 기대 결과만 말한다.

## 5. 성공 기준

- 모든 작업에 owner가 있다.
- 모든 산출물에 다음 수신자가 있다.
- 모든 결정은 기록된다.
- 모든 코드 변경은 테스트 또는 QA 체크리스트를 통과한다.
- 모든 에이전트는 자기 역할 밖의 일에 대해 “위임”할 수 있다.
