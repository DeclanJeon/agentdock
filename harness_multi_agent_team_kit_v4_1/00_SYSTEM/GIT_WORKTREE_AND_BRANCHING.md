# Git Worktree and Branching Rules

## 목적

여러 개발 에이전트가 같은 저장소에서 동시에 작업할 때 충돌을 줄이기 위한 규칙이다.

## 기본 전략

```bash
git worktree add ../worktrees/feature-auth feature/auth
git worktree add ../worktrees/feature-dashboard feature/dashboard
git worktree add ../worktrees/qa-review qa/review
```

## 브랜치 네이밍

| 유형 | 예시 |
|---|---|
| 기능 | `feature/shorts-stt-pipeline` |
| 버그 | `fix/caption-timing-drift` |
| 리팩토링 | `refactor/video-cut-service` |
| 문서 | `docs/agent-operating-model` |
| QA | `qa/release-2026-05-17` |

## 에이전트별 권한

| 역할 | 브랜치 생성 | 코드 수정 | 머지 | 태그/릴리즈 |
|---|---:|---:|---:|---:|
| CEO | 가능 | 금지 | 승인만 | 승인만 |
| Architect | 가능 | 제한적 | 금지 | 금지 |
| Developer | 가능 | 가능 | PR 요청 | 금지 |
| QA | 가능 | 금지 | 금지 | 금지 |
| DevOps | 가능 | CI/CD만 | PR 요청 | 승인 후 가능 |

## 병합 규칙

1. 개발 에이전트는 직접 main에 머지하지 않는다.
2. PR 설명에는 요구사항, 변경 내용, 테스트 결과가 있어야 한다.
3. QA 반려 시 개발팀은 새 커밋으로 수정한다.
4. CEO가 범위 변경을 승인하지 않은 코드는 병합하지 않는다.
5. 충돌이 나면 Architect가 구조 판단, Developer가 수정한다.
