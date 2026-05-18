# Feature Delivery Flow

## 목표

새 기능 하나를 기획에서 배포까지 통과시키는 표준 플로우다.

## 단계

```txt
User → CEO → PM → Architecture → Design → Development → QA → DevOps → CEO → Release
```

## 에이전트 수

| 규모 | 필요 에이전트 |
|---|---|
| 작은 기능 | CEO 1, PM 1, Architect 1, Dev 1, QA 1 |
| 중간 기능 | CEO 1, PM 1, Architect 1, Designer 1, Dev 2, QA 1 |
| 큰 기능 | CEO 1, PM 2, Architect 2, Designer 2, Dev 3~4, QA 2, DevOps 1 |

## 체크리스트

1. CEO: task brief 작성
2. PM: PRD + Acceptance Criteria 작성
3. Architect: API/DB/모듈 설계
4. Design: UX flow + 화면 명세
5. Dev: 구현 + 테스트
6. QA: 테스트 + 반려/승인
7. DevOps: 배포 준비
8. CEO: 릴리즈 승인
