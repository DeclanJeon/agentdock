# Branch Strategy

멀티 에이전트가 같은 파일을 동시에 수정하면 충돌이 폭발한다. 각 에이전트는 별도 branch/worktree를 사용한다.

## Branch Naming

```txt
agent/{team}/{task-id}-{short-name}
```

Examples:

```txt
agent/architecture/TASK-260517-001-auth-spec
agent/development/TASK-260517-002-auth-api
agent/qa/TASK-260517-003-auth-test
```

## Commit Message Format

```txt
[TASK-ID][TEAM] summary
```

Example:

```txt
[TASK-260517-002][DEV] implement auth callback endpoint
```

## Rule

- CEO/PM 문서 변경은 main docs branch에서 관리한다.
- 개발/QA/디자인 변경은 task branch에서 관리한다.
- architecture 문서 변경은 dev 작업 전에 merge/review되어야 한다.
