# QA Release Flow

## 목표

기능이 릴리즈 가능한지 검증한다.

```txt
Development → QA → Development Fix Loop → QA Signoff → DevOps → CEO
```

## QA는 무엇을 보는가

- 요구사항 충족 여부
- 유저스토리별 동작
- 실패/예외 경로
- 회귀 가능성
- 브라우저/디바이스 이슈
- 보안/권한 이슈
- 성능 저하

## QA 결과 유형

| 결과 | 의미 |
|---|---|
| PASS | 릴리즈 가능 |
| PASS WITH NOTES | 릴리즈 가능하지만 후속 작업 필요 |
| BLOCKED | 검증 불가 |
| FAIL | 릴리즈 불가 |

## 버그 리포트 필수 항목

- 재현 단계
- 기대 결과
- 실제 결과
- 환경
- 스크린샷/로그
- 심각도
- 담당 추천 팀
