#!/usr/bin/env bash
set -euo pipefail

SESSION="${SESSION:-product-war-room}"
AGENT="${1:-}"
TASK_FILE="${2:-}"

if [[ -z "$AGENT" || -z "$TASK_FILE" ]]; then
  echo "Usage: $0 <agent-window-name> <task-file-path>" >&2
  echo "Example: $0 architecture .agent-work/07_JOBS/JOB-260517-001/TASKS/TASK-001.md" >&2
  exit 1
fi

ABS_TASK_FILE="$(cd "$(dirname "$TASK_FILE")" && pwd)/$(basename "$TASK_FILE")"

if [[ ! -f "$ABS_TASK_FILE" ]]; then
  echo "Task file not found: $ABS_TASK_FILE" >&2
  exit 1
fi

MESSAGE="New task assigned.

Read this task file:
${ABS_TASK_FILE}

Then:
1. Confirm whether this belongs to your role.
2. If yes, update task status and begin work.
3. If no, create a handoff file in .agent-work/09_HANDOFFS and notify CEO.
4. Record all work in .agent-work logs/reports using YYMMDDHH:mm:ss timestamps."

tmux send-keys -t "$SESSION:$AGENT" "$MESSAGE" C-m

echo "Sent task to $SESSION:$AGENT -> $ABS_TASK_FILE"
