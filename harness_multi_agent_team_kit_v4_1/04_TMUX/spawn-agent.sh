#!/usr/bin/env bash
set -euo pipefail

SESSION="${SESSION:-product-war-room}"
CODEX_CMD="${CODEX_CMD:-codex}"
ROLE="${1:-}"
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"

if [[ -z "$ROLE" ]]; then
  echo "Usage: $0 <role-name>" >&2
  echo "Example: $0 researcher" >&2
  exit 1
fi

PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"
AGENT_SYSTEM_DIR="$PROJECT_ROOT/.agent-system"
AGENT_WORK_DIR="$PROJECT_ROOT/.agent-work"
WINDOW_NAME="$ROLE"

if ! tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux new-session -d -s "$SESSION" -n "$WINDOW_NAME" -c "$PROJECT_ROOT"
elif ! tmux list-windows -t "$SESSION" -F '#W' | grep -qx "$WINDOW_NAME"; then
  tmux new-window -t "$SESSION" -n "$WINDOW_NAME" -c "$PROJECT_ROOT"
fi

tmux send-keys -t "$SESSION:$WINDOW_NAME" "cd '$PROJECT_ROOT'" C-m
tmux send-keys -t "$SESSION:$WINDOW_NAME" "$CODEX_CMD" C-m
sleep 1
tmux send-keys -t "$SESSION:$WINDOW_NAME" "You are a temporary ${ROLE} Agent for this project. Read ${AGENT_SYSTEM_DIR}/00_SYSTEM/AGENT_TEAM_OPERATING_MODEL.md, ${AGENT_SYSTEM_DIR}/00_SYSTEM/DELEGATION_PROTOCOL.md, and use ${AGENT_WORK_DIR} for all task records. Say READY and wait for task assignment." C-m

echo "Spawned agent window: $WINDOW_NAME"
