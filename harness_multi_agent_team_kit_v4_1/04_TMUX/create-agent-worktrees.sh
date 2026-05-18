#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-$(pwd)}"
PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"
WORKTREE_ROOT="${WORKTREE_ROOT:-$(cd "$PROJECT_ROOT/.." && pwd)/$(basename "$PROJECT_ROOT")-agent-worktrees}"

if ! git -C "$PROJECT_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: $PROJECT_ROOT is not a git repository. Worktrees require git." >&2
  exit 1
fi

mkdir -p "$WORKTREE_ROOT"

create_role_worktree() {
  local role="$1"
  local branch="agent/${role}/workspace"
  local path="$WORKTREE_ROOT/$role"

  if [[ -d "$path" ]]; then
    echo "Already exists: $path"
    return 0
  fi

  git -C "$PROJECT_ROOT" worktree add "$path" -b "$branch" || \
  git -C "$PROJECT_ROOT" worktree add "$path" "$branch"

  ln -sfn "$PROJECT_ROOT/.agent-system" "$path/.agent-system" 2>/dev/null || true
  ln -sfn "$PROJECT_ROOT/.agent-work" "$path/.agent-work" 2>/dev/null || true
  echo "Created: $path"
}

create_role_worktree architecture
create_role_worktree development
create_role_worktree qa
create_role_worktree design
create_role_worktree devops

echo "Worktrees root: $WORKTREE_ROOT"
