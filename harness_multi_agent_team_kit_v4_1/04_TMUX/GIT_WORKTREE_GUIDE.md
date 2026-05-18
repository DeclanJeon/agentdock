# Git Worktree Guide for Multi-Agent tmux

## Why

각 에이전트가 같은 repository working tree를 동시에 수정하면 파일 충돌이 발생한다. worktree는 에이전트별 독립 작업실을 제공한다.

## Suggested Structure

```txt
worktrees/
├── ceo-main/
├── architect-feature-auth/
├── dev-feature-auth/
├── qa-feature-auth/
└── design-feature-auth/
```

## Commands

```bash
git worktree add worktrees/architect-feature-auth -b agent/architecture/TASK-260517-001-auth-spec
git worktree add worktrees/dev-feature-auth -b agent/development/TASK-260517-002-auth-api
git worktree add worktrees/qa-feature-auth -b agent/qa/TASK-260517-003-auth-test
```

## Cleanup

```bash
git worktree remove worktrees/dev-feature-auth
git branch -d agent/development/TASK-260517-002-auth-api
```
