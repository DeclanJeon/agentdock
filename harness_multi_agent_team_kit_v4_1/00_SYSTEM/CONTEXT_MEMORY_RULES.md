# Context and Memory Rules

## 1. 저장해야 하는 것

- 제품 목표
- 사용자 페르소나
- 결정된 요구사항
- 아키텍처 결정
- API 계약
- 디자인 시스템 결정
- QA 결과
- 릴리즈 기록

## 2. 저장하지 않아도 되는 것

- 임시 추측
- 실패한 초안
- 단순 로그
- 중복 설명
- 이미 폐기된 아이디어

## 3. 파일 분리 원칙

| 정보 | 저장 위치 |
|---|---|
| 제품 전체 맥락 | `docs/PROJECT_CONTEXT.md` |
| 결정 기록 | `docs/decisions/ADR-0001-title.md` |
| 요구사항 | `docs/prd/` |
| 아키텍처 | `docs/architecture/` |
| 디자인 | `docs/design/` |
| QA | `docs/qa/` |
| 임시 사고 | `.agents/{role}/scratch.md` |

## 4. 컨텍스트 주입 원칙

에이전트에게 모든 문서를 다 먹이지 않는다. 필요한 파일만 준다.

### 예시

- 개발팀: PRD + API Spec + Architecture Decision + 관련 코드
- 디자인팀: PRD + User Flow + Design System + 브랜드 톤
- QA팀: PRD + Acceptance Criteria + Test Plan + 구현 결과
- 마케팅팀: Positioning + Persona + Feature List + 가격정책

## 5. 엔트로피 청소

매주 또는 큰 작업 종료 후 CEO는 다음을 수행한다.

- obsolete 문서 이동
- 중복 결정 병합
- 최신 결정만 `PROJECT_CONTEXT.md`에 반영
- stale task 닫기
- scratch 파일 비우기
