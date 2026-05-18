#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="product-war-room"
ROOT_DIR="${1:-$PWD}"

mkdir -p "$ROOT_DIR/.agents"/{ceo,pm,user,business,marketing,architecture,development,design,qa,devops,legal-risk}
mkdir -p "$ROOT_DIR/docs"/{prd,requirements,architecture,design,qa,marketing,business,decisions}
mkdir -p "$ROOT_DIR/jobs" "$ROOT_DIR/tasks" "$ROOT_DIR/handoffs" "$ROOT_DIR/reports"/{daily,completion} "$ROOT_DIR/scripts"
touch "$ROOT_DIR/tasks/backlog.md" "$ROOT_DIR/tasks/doing.md" "$ROOT_DIR/tasks/blocked.md" "$ROOT_DIR/tasks/done.md"

for role in ceo pm user business marketing architecture development design qa devops legal-risk; do
  touch "$ROOT_DIR/.agents/$role/inbox.md" "$ROOT_DIR/.agents/$role/outbox.md" "$ROOT_DIR/.agents/$role/scratch.md"
done

if tmux has-session -t "$PROJECT_NAME" 2>/dev/null; then
  echo "tmux session already exists: $PROJECT_NAME"
  tmux attach -t "$PROJECT_NAME"
  exit 0
fi

tmux new-session -d -s "$PROJECT_NAME" -n ceo -c "$ROOT_DIR"
tmux send-keys -t "$PROJECT_NAME:ceo.0" 'echo "CEO Agent pane"; echo "Read: 02_AGENT_PROMPTS/CEO_PROMPT.md"' C-m

tmux split-window -h -t "$PROJECT_NAME:ceo" -c "$ROOT_DIR"
tmux send-keys -t "$PROJECT_NAME:ceo.1" 'watch -n 2 "find tasks handoffs reports -maxdepth 2 -type f | sort | tail -40"' C-m

tmux new-window -t "$PROJECT_NAME" -n planning -c "$ROOT_DIR"
tmux split-window -h -t "$PROJECT_NAME:planning" -c "$ROOT_DIR"
tmux send-keys -t "$PROJECT_NAME:planning.0" 'echo "PM Agent pane"; echo "Read: 02_AGENT_PROMPTS/PLANNING_PM_PROMPT.md"' C-m
tmux send-keys -t "$PROJECT_NAME:planning.1" 'echo "User Voice Agent pane"; echo "Read: 02_AGENT_PROMPTS/USER_PROMPT.md"' C-m

tmux new-window -t "$PROJECT_NAME" -n business-marketing -c "$ROOT_DIR"
tmux split-window -h -t "$PROJECT_NAME:business-marketing" -c "$ROOT_DIR"
tmux send-keys -t "$PROJECT_NAME:business-marketing.0" 'echo "Business Agent pane"; echo "Read: 02_AGENT_PROMPTS/BUSINESS_PROMPT.md"' C-m
tmux send-keys -t "$PROJECT_NAME:business-marketing.1" 'echo "Marketing Agent pane"; echo "Read: 02_AGENT_PROMPTS/MARKETING_PROMPT.md"' C-m

tmux new-window -t "$PROJECT_NAME" -n design -c "$ROOT_DIR"
tmux split-window -h -t "$PROJECT_NAME:design" -c "$ROOT_DIR"
tmux send-keys -t "$PROJECT_NAME:design.0" 'echo "Design Agent pane"; echo "Read: 02_AGENT_PROMPTS/DESIGN_PROMPT.md"' C-m
tmux send-keys -t "$PROJECT_NAME:design.1" 'echo "UX Review pane"' C-m

tmux new-window -t "$PROJECT_NAME" -n architecture -c "$ROOT_DIR"
tmux split-window -h -t "$PROJECT_NAME:architecture" -c "$ROOT_DIR"
tmux send-keys -t "$PROJECT_NAME:architecture.0" 'echo "Architecture Agent pane"; echo "Read: 02_AGENT_PROMPTS/ARCHITECTURE_PROMPT.md"; echo "Required: PRD/SRD/SRS/SDD/TDD/API/SYSTEM/FLOW/SEQUENCE/HANDOFF"' C-m
tmux send-keys -t "$PROJECT_NAME:architecture.1" 'echo "Architecture Review / Security Review pane"; echo "Check ARCHITECT_TO_DEV_CONTRACT.md"' C-m

tmux new-window -t "$PROJECT_NAME" -n development -c "$ROOT_DIR"
tmux split-window -h -t "$PROJECT_NAME:development" -c "$ROOT_DIR"
tmux split-window -v -t "$PROJECT_NAME:development.1" -c "$ROOT_DIR"
tmux send-keys -t "$PROJECT_NAME:development.0" 'echo "Frontend Dev Agent pane"; echo "Read: 02_AGENT_PROMPTS/DEVELOPMENT_PROMPT.md"' C-m
tmux send-keys -t "$PROJECT_NAME:development.1" 'echo "Backend Dev Agent pane"; echo "Read: 02_AGENT_PROMPTS/DEVELOPMENT_PROMPT.md"' C-m
tmux send-keys -t "$PROJECT_NAME:development.2" 'echo "Test Writer Agent pane"; echo "Read: 05_TEMPLATES/TDD.md and QA_PLAN.md"' C-m

tmux new-window -t "$PROJECT_NAME" -n qa -c "$ROOT_DIR"
tmux split-window -h -t "$PROJECT_NAME:qa" -c "$ROOT_DIR"
tmux send-keys -t "$PROJECT_NAME:qa.0" 'echo "QA Agent pane"; echo "Read: 02_AGENT_PROMPTS/QA_PROMPT.md"' C-m
tmux send-keys -t "$PROJECT_NAME:qa.1" 'echo "Test Runner pane"' C-m

tmux select-window -t "$PROJECT_NAME:ceo"
tmux attach -t "$PROJECT_NAME"
