# Agent Count Decision Matrix

## 업무별 에이전트 수 결정표

| 업무 유형 | 최소 구성 | 권장 구성 | 비고 |
|---|---|---|---|
| 아이디어 검토 | CEO 1 + PM 1 | CEO + PM + Business + User | 시장성 판단 필요 시 Business 추가 |
| PRD 작성 | PM 1 | PM + User + CEO | 사용자 맥락이 부족하면 User Agent 추가 |
| 랜딩페이지 기획 | Marketing 1 + Design 1 | PM + Marketing + Design + User | 카피와 UX를 분리 |
| 기능 구현 | Dev 1 + QA 1 | Architect + Dev 2 + QA | 중간 이상 기능은 Architect 필수 |
| 대형 리팩토링 | Architect 1 + Dev 1 | Architect 2 + Dev 2 + QA | 구조 결정과 구현을 분리 |
| 버그 수정 | Dev 1 + QA 1 | QA + Dev + Architect | 원인 불명 버그는 Architect 추가 |
| 배포 | DevOps 1 + QA 1 | DevOps + QA + CEO | 롤백 계획 필요 |
| 가격정책 | Business 1 | Business + Marketing + CEO | 사용자 반응 검증 필요 |
| 법률/정책 | Legal 1 + CEO 1 | Legal + Business + PM | 단정 금지, 리스크 중심 |

## 판단 공식

```txt
필요 에이전트 수 = 역할 경계 수 + 병렬 검토 필요성 + 실패 비용
```

- 역할 경계가 많을수록 에이전트 수를 늘린다.
- 실패 비용이 크면 QA/Legal/Architect를 추가한다.
- 단순 반복 작업은 에이전트 수보다 템플릿 품질이 중요하다.
