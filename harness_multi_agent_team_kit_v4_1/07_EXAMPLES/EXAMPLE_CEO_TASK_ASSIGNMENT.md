# Example: CEO Task Assignment

## User Request

“유튜브 링크를 분석해서 1분 이내 쇼츠로 자동 컷편집하고 자막을 붙이는 프로그램을 만들고 싶다.”

## CEO Breakdown

| Team | Assignment | Output |
|---|---|---|
| PM | 사용자 흐름과 요구사항 정의 | PRD.md |
| Business | 무료/유료 플랜과 비용 구조 검토 | PRICING_STRATEGY.md |
| Marketing | 포지셔닝과 런칭 콘텐츠 작성 | POSITIONING.md |
| Architecture | STT, 컷 탐지, 렌더링 파이프라인 설계 | ARCHITECTURE.md |
| Design | 업로드/분석/편집/업로드 화면 흐름 설계 | USER_FLOW.md |
| Development | MVP 구현 | IMPLEMENTATION_NOTES.md |
| QA | 영상 유형별 테스트 플랜 작성 | QA_PLAN.md |
| Legal/Risk | YouTube 저작권/업로드 정책 리스크 검토 | RISK_REVIEW.md |

## CEO Instruction to PM

```md
# Task Brief

- Task ID: YTS-001
- Owner: PM Agent
- Priority: P1

## Goal

YouTube 링크 기반 쇼츠 자동 제작 프로그램의 MVP 요구사항을 정의한다.

## Deliverables

- PRD.md
- USER_STORIES.md
- ACCEPTANCE_CRITERIA.md

## Constraints

- TTS는 MVP에서 제외한다.
- Whisper 기반 STT는 포함한다.
- 한국어/영어/일본어를 고려한다.
- 자동 업로드는 정책 리스크 검토 후 범위를 확정한다.
```
