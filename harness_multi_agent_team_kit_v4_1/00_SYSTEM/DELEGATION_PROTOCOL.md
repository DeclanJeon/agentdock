# Delegation Protocol

## 목적

에이전트가 자기 역할 밖의 업무를 처리하지 않고, 적절한 팀에게 넘기도록 만드는 규칙이다. 이 문서는 멀티 에이전트 팀의 교통 신호등이다.

## 1. 위임 판단 기준

다음 중 하나라도 해당하면 위임한다.

| 상황 | 위임 대상 |
|---|---|
| 제품 목적, 우선순위, 요구사항 변경 | CEO 또는 PM |
| 사용자 페르소나, 사용 시나리오 불명확 | User Agent 또는 PM |
| 수익모델, 가격, 시장성 판단 | Business Team |
| 카피, 랜딩페이지 메시지, 채널 전략 | Marketing Team |
| 시스템 구조, DB, API 경계 | Architecture Team |
| 구현, 테스트 코드, 리팩토링 | Development Team |
| UI, UX, 디자인 시스템, 화면 흐름 | Design Team |
| 버그 재현, 테스트, 승인/반려 | QA Team |
| 배포, CI/CD, 모니터링 | DevOps Team |
| 약관, 개인정보, 정책 위험 | Legal/Risk Team |

## 2. 위임 메시지 포맷

```md
# Delegation Request

- From:
- To:
- Related Task:
- Reason for Delegation:
- Required Output:
- Constraints:
- Deadline / Priority:
- Context Files:
- Acceptance Criteria:
```

## 3. 위임 규칙

1. 문제를 던지지 말고 **필요한 산출물**을 요청한다.
2. “해줘”가 아니라 **맥락, 제약, 성공 기준**을 같이 준다.
3. 수신 팀은 수락/거절/재위임 중 하나를 선택한다.
4. 재위임 시 원 요청자와 CEO에게 알린다.
5. 막히면 추측하지 않고 `BLOCKED.md`를 작성한다.

## 4. 재위임 예시

### 잘못된 예

> 디자인팀: API 구조가 이상해서 제가 고쳤습니다.

### 올바른 예

> 디자인팀: 현재 UX 흐름상 회원가입 직후 온보딩 상태 API가 필요합니다. Architecture Team에 API 상태 모델 정의를 요청합니다.

## 5. CEO 승인 필요 상황

- 일정 변경
- 범위 확대
- 기능 삭제
- 비용 증가
- 보안/법률 리스크
- 사용자 경험에 큰 영향을 주는 정책 변경
- 팀 간 의견 충돌
