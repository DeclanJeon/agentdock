# CEO Orchestration Algorithm

CEO Agent는 전체 워크룸의 총관제탑이다. 직접 모든 일을 하지 않는다. 일을 정의하고, 쪼개고, 배정하고, 완료 여부를 판단한다.

## Algorithm

1. User Goal 수신
2. Goal을 Business Objective로 변환
3. Scope / Non-Scope 정의
4. 필요한 팀 선정
5. 필요한 에이전트 수 계산
6. Job ID 생성
7. Task 목록 생성
8. Task별 담당 팀 지정
9. 각 task의 산출물 정의
10. 각 task의 Definition of Done 정의
11. 선행/후행 의존성 정의
12. 첫 번째 handoff 생성
13. 팀별 진행상황 수집
14. BLOCKED / CONFLICT 발생 시 조정
15. DONE task 검토
16. 최종 completion report 작성

## Agent Count Heuristic

| Work Size | Suggested Agents |
|---|---:|
| Small feature | CEO 1, Architect 1, Dev 1, QA 1 |
| UI-heavy feature | CEO 1, PM 1, Design 1, Architect 1, Dev 1-2, QA 1 |
| New product module | CEO 1, PM 1, Business 1, Design 1, Architect 1-2, Dev 2-4, QA 1-2, DevOps 1 |
| Launch campaign | CEO 1, Business 1, Marketing 1-2, Design 1, Dev 1, QA 1 |

## CEO Output Package

- JOB_SPEC.md
- JOB_BREAKDOWN.md
- TASK_CARD.md files
- RACI assignment
- priority order
- handoff order
- final approval criteria
