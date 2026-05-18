# Architect To Development Contract

Architecture Team은 개발팀에게 애매한 아이디어를 넘기면 안 된다. 개발 가능한 단위의 문서 묶음으로 넘긴다.

## Architecture Team Required Deliverables

Architecture Team은 기능 또는 제품 단위 작업을 개발팀으로 넘기기 전에 아래 문서를 작성한다.

```txt
docs/
├── prd/{feature}/PRD.md
├── requirements/{feature}/SRD.md
├── requirements/{feature}/SRS.md
├── architecture/{feature}/SDD.md
├── architecture/{feature}/TDD.md
├── architecture/{feature}/API_SPEC.md
├── architecture/{feature}/SYSTEM_ARCHITECTURE.md
├── architecture/{feature}/FLOW_DIAGRAM.md
├── architecture/{feature}/SEQUENCE_DIAGRAM.md
└── architecture/{feature}/ARCHITECTURE_TO_DEV_HANDOFF.md
```

## Document Ownership

| Document | Primary Owner | Reviewer | Receiver |
|---|---|---|---|
| PRD | PM / Architect | CEO | Architecture / Dev |
| SRD | Architect | PM / Dev | Dev |
| SRS | Architect | QA / Dev | Dev / QA |
| SDD | Architect | Dev Lead | Dev |
| TDD | Architect / Dev Lead | QA | Dev |
| API Spec | Architect | Backend / Frontend | Dev |
| System Architecture | Architect | DevOps / Security | Dev / DevOps |
| Flow Diagram | Architect | PM / Design / Dev | Dev |
| Sequence Diagram | Architect | Backend / Frontend | Dev |
| Architecture To Dev Handoff | Architect | CEO | Dev |

## Definition of Ready For Development

개발팀에 넘길 수 있는 상태는 아래 조건을 모두 만족해야 한다.

- PRD가 문제, 목표, 사용자, 성공 기준을 설명한다.
- SRD가 비즈니스/운영 요구사항을 설명한다.
- SRS가 기능/비기능 요구사항을 검증 가능한 문장으로 설명한다.
- SDD가 모듈, 경계, 데이터 구조, 상태 관리, 에러 처리를 설명한다.
- TDD가 테스트 전략, 테스트 케이스, 통과 기준을 설명한다.
- API Spec이 엔드포인트, 요청/응답, 에러코드, 인증을 설명한다.
- System Architecture가 시스템 컴포넌트와 배포 구조를 설명한다.
- Flow Diagram이 사용자/시스템 흐름을 설명한다.
- Sequence Diagram이 주요 시나리오의 호출 순서를 설명한다.
- 미결정 사항이 `Open Questions`로 분리되어 있다.
- 개발 task가 frontend/backend/test/devops 단위로 분해되어 있다.

## Handoff Rule

Architecture Team은 개발팀에게 다음 형식으로 handoff한다.

```md
# Architecture To Development Handoff

- Handoff ID:
- Timestamp: YYMMDDHH:mm:ss
- From: Architecture Team
- To: Development Team
- Related Task:
- Feature:
- Documents:
- Implementation Tasks:
- Acceptance Criteria:
- Risks:
- Open Questions:
- Required Reviews:
```
