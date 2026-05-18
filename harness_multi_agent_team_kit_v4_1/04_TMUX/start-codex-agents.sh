#!/usr/bin/env bash
set -euo pipefail

SESSION="${SESSION:-product-war-room}"
CODEX_CMD="${CODEX_CMD:-codex}"
CREATE_WORKTREES="${CREATE_WORKTREES:-1}"
LAYOUT="${LAYOUT:-hybrid}"
FRESH="${FRESH:-0}"
PROJECT_ROOT=""

usage() {
  cat <<'USAGE'
Start tmux/Codex multi-agent war-room for a real project.

Recommended usage from project root:
  .agent-system/04_TMUX/start-codex-agents.sh

Explicit project path:
  .agent-system/04_TMUX/start-codex-agents.sh --project /path/to/project

Layout options:
  --layout hybrid   # default: 3 windows with readable pane grids
  --layout grid     # all agents in one tiled window
  --layout windows  # one tmux window per agent

Useful options:
  --fresh           # kill existing session before booting
  --no-worktrees    # run all agents in the project root

Environment variables:
  SESSION=product-war-room
  CODEX_CMD=codex
  CREATE_WORKTREES=1
  LAYOUT=hybrid
  FRESH=0
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      PROJECT_ROOT="${2:-}"
      shift 2
      ;;
    --layout)
      LAYOUT="${2:-}"
      shift 2
      ;;
    --fresh)
      FRESH="1"
      shift
      ;;
    --no-worktrees)
      CREATE_WORKTREES="0"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

case "$LAYOUT" in
  hybrid|grid|windows) ;;
  *)
    echo "Error: unknown layout '$LAYOUT'. Use hybrid, grid, or windows." >&2
    exit 1
    ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_SYSTEM_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# If installed as <project>/.agent-system/04_TMUX/start-codex-agents.sh,
# infer project root from the parent directory of .agent-system.
if [[ -z "$PROJECT_ROOT" ]]; then
  if [[ "$(basename "$AGENT_SYSTEM_DIR")" == ".agent-system" ]]; then
    PROJECT_ROOT="$(cd "$AGENT_SYSTEM_DIR/.." && pwd)"
  else
    PROJECT_ROOT="$(pwd)"
  fi
fi
PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"
AGENT_WORK_DIR="$PROJECT_ROOT/.agent-work"
WORKTREE_ROOT="$(cd "$PROJECT_ROOT/.." && pwd)/$(basename "$PROJECT_ROOT")-agent-worktrees"

if [[ "$PROJECT_ROOT" == "$AGENT_SYSTEM_DIR" ]]; then
  echo "Warning: You appear to be running inside the kit directory, not a product project." >&2
  echo "Recommended: copy this kit to <project>/.agent-system, then run from <project>." >&2
fi

mkdir -p \
  "$AGENT_WORK_DIR/07_JOBS" \
  "$AGENT_WORK_DIR/08_DECISIONS" \
  "$AGENT_WORK_DIR/09_HANDOFFS" \
  "$AGENT_WORK_DIR/10_REPORTS" \
  "$AGENT_WORK_DIR/11_ARCHIVE" \
  "$AGENT_WORK_DIR/12_INBOX" \
  "$AGENT_WORK_DIR/13_OUTBOX" \
  "$AGENT_WORK_DIR/14_SHARED_CONTEXT"

create_or_use_worktree() {
  local role="$1"
  local branch="agent/${role}/workspace"
  local path="$WORKTREE_ROOT/$role"

  if [[ "$CREATE_WORKTREES" != "1" ]]; then
    echo "$PROJECT_ROOT"
    return 0
  fi

  if ! git -C "$PROJECT_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "$PROJECT_ROOT"
    return 0
  fi

  mkdir -p "$WORKTREE_ROOT"
  if [[ ! -d "$path/.git" && ! -f "$path/.git" ]]; then
    git -C "$PROJECT_ROOT" worktree add "$path" -b "$branch" >/dev/null 2>&1 || \
    git -C "$PROJECT_ROOT" worktree add "$path" "$branch" >/dev/null 2>&1 || \
    cp -R "$PROJECT_ROOT" "$path" >/dev/null 2>&1 || true
  fi
  if [[ -d "$path" ]]; then
    ln -sfn "$AGENT_SYSTEM_DIR" "$path/.agent-system" 2>/dev/null || true
    ln -sfn "$AGENT_WORK_DIR" "$path/.agent-work" 2>/dev/null || true
    echo "$path"
  else
    echo "$PROJECT_ROOT"
  fi
}

quote_for_send() {
  printf "%q" "$1"
}

send_boot_prompt() {
  local target="$1"
  local cwd="$2"
  local role="$3"
  local prompt_file="$4"
  local extra="$5"

  local boot_text
  boot_text="You are the ${role}.

Project root: ${PROJECT_ROOT}
Your current working directory: ${cwd}
Agent system directory: ${AGENT_SYSTEM_DIR}
Shared work directory: ${AGENT_WORK_DIR}

First read these files:
- ${AGENT_SYSTEM_DIR}/${prompt_file}
- ${AGENT_SYSTEM_DIR}/00_SYSTEM/AGENT_TEAM_OPERATING_MODEL.md
- ${AGENT_SYSTEM_DIR}/00_SYSTEM/TASK_STATUS_MACHINE.md
- ${AGENT_SYSTEM_DIR}/00_SYSTEM/DELEGATION_PROTOCOL.md
- ${AGENT_SYSTEM_DIR}/00_SYSTEM/MESSAGE_ROUTING_PROTOCOL.md
- ${AGENT_SYSTEM_DIR}/00_SYSTEM/AGENT_PROHIBITED_ACTIONS.md
- ${AGENT_SYSTEM_DIR}/00_SYSTEM/WORK_LOGGING_PROTOCOL.md
- ${AGENT_SYSTEM_DIR}/00_SYSTEM/PROJECT_RUNTIME_MODEL.md

Operational rules:
- Work in the assigned cwd unless explicitly told otherwise.
- Use ${AGENT_WORK_DIR} for jobs, task cards, logs, reports, handoffs, and shared context.
- Do not assume other agents can see your chat. Communicate through files in .agent-work.
- If the task belongs to another team, create a handoff file instead of doing that team's work.
- When ready, say: READY - ${role}. Include your boundaries, required inputs, and output files.

${extra}"

  tmux send-keys -t "$target" "cd $(quote_for_send "$cwd")" C-m
  tmux send-keys -t "$target" "$CODEX_CMD" C-m
  sleep 1
  tmux send-keys -t "$target" "$boot_text" C-m
}

set_pane_title() {
  local target="$1"
  local title="$2"
  tmux select-pane -t "$target" -T "$title" 2>/dev/null || true
}

configure_pane_ui() {
  tmux set-option -t "$SESSION" pane-border-status top >/dev/null 2>&1 || true
  tmux set-option -t "$SESSION" pane-border-format ' #P #{pane_title} ' >/dev/null 2>&1 || true
  tmux set-option -t "$SESSION" status-left "[$SESSION:$LAYOUT] " >/dev/null 2>&1 || true
}

new_session_or_window() {
  local window="$1"
  local cwd="$2"
  if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux new-session -d -s "$SESSION" -n "$window" -c "$cwd"
  else
    tmux new-window -t "$SESSION" -n "$window" -c "$cwd"
  fi
}

ensure_window() {
  local name="$1"
  local cwd="$2"
  if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux new-session -d -s "$SESSION" -n "$name" -c "$cwd"
  elif ! tmux list-windows -t "$SESSION" -F '#W' 2>/dev/null | grep -qx "$name"; then
    tmux new-window -t "$SESSION" -n "$name" -c "$cwd"
  fi
}

split_new_pane() {
  local target_window="$1"
  local cwd="$2"
  tmux split-window -t "$SESSION:$target_window" -c "$cwd"
  tmux select-layout -t "$SESSION:$target_window" tiled >/dev/null 2>&1 || true
  tmux display-message -p -t "$SESSION:$target_window" '#{pane_id}'
}

create_pane_grid_window() {
  local window="$1"
  shift
  local first_cwd="$1"
  shift

  new_session_or_window "$window" "$first_cwd"
  local first_pane
  first_pane="$(tmux display-message -p -t "$SESSION:$window.0" '#{pane_id}')"
  echo "$first_pane"

  while [[ $# -gt 0 ]]; do
    local cwd="$1"
    shift
    split_new_pane "$window" "$cwd"
  done
  tmux select-layout -t "$SESSION:$window" tiled >/dev/null 2>&1 || true
}

CEO_DIR="$PROJECT_ROOT"
PLANNING_DIR="$PROJECT_ROOT"
BUSINESS_DIR="$PROJECT_ROOT"
MARKETING_DIR="$PROJECT_ROOT"
DESIGN_DIR="$(create_or_use_worktree design)"
ARCH_DIR="$(create_or_use_worktree architecture)"
DEV_DIR="$(create_or_use_worktree development)"
QA_DIR="$(create_or_use_worktree qa)"
DEVOPS_DIR="$(create_or_use_worktree devops)"
RISK_DIR="$PROJECT_ROOT"

if [[ "$FRESH" == "1" ]] && tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux kill-session -t "$SESSION"
fi

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "Session '$SESSION' already exists. Use --fresh to recreate it, or attach with: tmux attach -t $SESSION" >&2
  exit 1
fi

case "$LAYOUT" in
  windows)
    ensure_window ceo "$CEO_DIR"
    ensure_window planning "$PLANNING_DIR"
    ensure_window business "$BUSINESS_DIR"
    ensure_window marketing "$MARKETING_DIR"
    ensure_window design "$DESIGN_DIR"
    ensure_window architecture "$ARCH_DIR"
    ensure_window development "$DEV_DIR"
    ensure_window qa "$QA_DIR"
    ensure_window devops "$DEVOPS_DIR"
    ensure_window risk "$RISK_DIR"
    configure_pane_ui

    send_boot_prompt "$SESSION:ceo" "$CEO_DIR" "CEO Orchestrator Agent" "02_AGENT_PROMPTS/CEO_PROMPT.md" "You create jobs, tasks, RACI, handoff order, and assign work through .agent-work files."
    send_boot_prompt "$SESSION:planning" "$PLANNING_DIR" "Planning PM Agent" "02_AGENT_PROMPTS/PLANNING_PM_PROMPT.md" "You own PRD support, scope, requirements clarification, and user-intent refinement."
    send_boot_prompt "$SESSION:business" "$BUSINESS_DIR" "Business Agent" "02_AGENT_PROMPTS/BUSINESS_PROMPT.md" "You own market, pricing, ICP, business model, and business constraints."
    send_boot_prompt "$SESSION:marketing" "$MARKETING_DIR" "Marketing Agent" "02_AGENT_PROMPTS/MARKETING_PROMPT.md" "You own positioning, copy, channels, launch messaging, and campaign assets."
    send_boot_prompt "$SESSION:design" "$DESIGN_DIR" "Design Agent" "02_AGENT_PROMPTS/DESIGN_PROMPT.md" "You own UX/UI/design system only. Do not implement production code unless explicitly assigned."
    send_boot_prompt "$SESSION:architecture" "$ARCH_DIR" "Architecture Agent" "02_AGENT_PROMPTS/ARCHITECTURE_PROMPT.md" "You own PRD/SRD/SRS/SDD/TDD/API Spec/System Architecture/Flow/Sequence and dev handoff."
    send_boot_prompt "$SESSION:development" "$DEV_DIR" "Development Agent" "02_AGENT_PROMPTS/DEVELOPMENT_PROMPT.md" "You implement only from accepted architecture/dev handoff. Record changed files and test results."
    send_boot_prompt "$SESSION:qa" "$QA_DIR" "QA Agent" "02_AGENT_PROMPTS/QA_PROMPT.md" "You own QA plan, test cases, bug reports, regression checks, and release decision."
    send_boot_prompt "$SESSION:devops" "$DEVOPS_DIR" "DevOps Agent" "02_AGENT_PROMPTS/DEVOPS_PROMPT.md" "You own deployment, CI/CD, runtime, infrastructure, observability, and rollback."
    send_boot_prompt "$SESSION:risk" "$RISK_DIR" "Legal/Risk Agent" "02_AGENT_PROMPTS/LEGAL_RISK_PROMPT.md" "You own policy, privacy, legal, compliance, and operational risk."
    ;;

  grid)
    create_pane_grid_window agents "$CEO_DIR" "$ARCH_DIR" "$DEV_DIR" "$QA_DIR" "$DESIGN_DIR" "$PLANNING_DIR" "$BUSINESS_DIR" "$MARKETING_DIR" "$DEVOPS_DIR" "$RISK_DIR" >/tmp/agent_grid_panes.$$ 
    configure_pane_ui
    mapfile -t panes < <(tmux list-panes -t "$SESSION:agents" -F '#{pane_id}')
    set_pane_title "${panes[0]}" "CEO"
    set_pane_title "${panes[1]}" "Architecture"
    set_pane_title "${panes[2]}" "Development"
    set_pane_title "${panes[3]}" "QA"
    set_pane_title "${panes[4]}" "Design"
    set_pane_title "${panes[5]}" "Planning"
    set_pane_title "${panes[6]}" "Business"
    set_pane_title "${panes[7]}" "Marketing"
    set_pane_title "${panes[8]}" "DevOps"
    set_pane_title "${panes[9]}" "Risk"

    send_boot_prompt "${panes[0]}" "$CEO_DIR" "CEO Orchestrator Agent" "02_AGENT_PROMPTS/CEO_PROMPT.md" "You create jobs, tasks, RACI, handoff order, and assign work through .agent-work files."
    send_boot_prompt "${panes[1]}" "$ARCH_DIR" "Architecture Agent" "02_AGENT_PROMPTS/ARCHITECTURE_PROMPT.md" "You own PRD/SRD/SRS/SDD/TDD/API Spec/System Architecture/Flow/Sequence and dev handoff."
    send_boot_prompt "${panes[2]}" "$DEV_DIR" "Development Agent" "02_AGENT_PROMPTS/DEVELOPMENT_PROMPT.md" "You implement only from accepted architecture/dev handoff. Record changed files and test results."
    send_boot_prompt "${panes[3]}" "$QA_DIR" "QA Agent" "02_AGENT_PROMPTS/QA_PROMPT.md" "You own QA plan, test cases, bug reports, regression checks, and release decision."
    send_boot_prompt "${panes[4]}" "$DESIGN_DIR" "Design Agent" "02_AGENT_PROMPTS/DESIGN_PROMPT.md" "You own UX/UI/design system only. Do not implement production code unless explicitly assigned."
    send_boot_prompt "${panes[5]}" "$PLANNING_DIR" "Planning PM Agent" "02_AGENT_PROMPTS/PLANNING_PM_PROMPT.md" "You own PRD support, scope, requirements clarification, and user-intent refinement."
    send_boot_prompt "${panes[6]}" "$BUSINESS_DIR" "Business Agent" "02_AGENT_PROMPTS/BUSINESS_PROMPT.md" "You own market, pricing, ICP, business model, and business constraints."
    send_boot_prompt "${panes[7]}" "$MARKETING_DIR" "Marketing Agent" "02_AGENT_PROMPTS/MARKETING_PROMPT.md" "You own positioning, copy, channels, launch messaging, and campaign assets."
    send_boot_prompt "${panes[8]}" "$DEVOPS_DIR" "DevOps Agent" "02_AGENT_PROMPTS/DEVOPS_PROMPT.md" "You own deployment, CI/CD, runtime, infrastructure, observability, and rollback."
    send_boot_prompt "${panes[9]}" "$RISK_DIR" "Legal/Risk Agent" "02_AGENT_PROMPTS/LEGAL_RISK_PROMPT.md" "You own policy, privacy, legal, compliance, and operational risk."
    rm -f /tmp/agent_grid_panes.$$
    ;;

  hybrid)
    create_pane_grid_window command-center "$CEO_DIR" "$ARCH_DIR" "$DEV_DIR" "$QA_DIR" >/dev/null
    create_pane_grid_window product-market "$PLANNING_DIR" "$DESIGN_DIR" "$BUSINESS_DIR" "$MARKETING_DIR" >/dev/null
    create_pane_grid_window ops-risk "$DEVOPS_DIR" "$RISK_DIR" >/dev/null
    configure_pane_ui

    mapfile -t cc_panes < <(tmux list-panes -t "$SESSION:command-center" -F '#{pane_id}')
    mapfile -t pm_panes < <(tmux list-panes -t "$SESSION:product-market" -F '#{pane_id}')
    mapfile -t or_panes < <(tmux list-panes -t "$SESSION:ops-risk" -F '#{pane_id}')

    set_pane_title "${cc_panes[0]}" "CEO"
    set_pane_title "${cc_panes[1]}" "Architecture"
    set_pane_title "${cc_panes[2]}" "Development"
    set_pane_title "${cc_panes[3]}" "QA"
    set_pane_title "${pm_panes[0]}" "Planning"
    set_pane_title "${pm_panes[1]}" "Design"
    set_pane_title "${pm_panes[2]}" "Business"
    set_pane_title "${pm_panes[3]}" "Marketing"
    set_pane_title "${or_panes[0]}" "DevOps"
    set_pane_title "${or_panes[1]}" "Risk"

    send_boot_prompt "${cc_panes[0]}" "$CEO_DIR" "CEO Orchestrator Agent" "02_AGENT_PROMPTS/CEO_PROMPT.md" "You create jobs, tasks, RACI, handoff order, and assign work through .agent-work files."
    send_boot_prompt "${cc_panes[1]}" "$ARCH_DIR" "Architecture Agent" "02_AGENT_PROMPTS/ARCHITECTURE_PROMPT.md" "You own PRD/SRD/SRS/SDD/TDD/API Spec/System Architecture/Flow/Sequence and dev handoff."
    send_boot_prompt "${cc_panes[2]}" "$DEV_DIR" "Development Agent" "02_AGENT_PROMPTS/DEVELOPMENT_PROMPT.md" "You implement only from accepted architecture/dev handoff. Record changed files and test results."
    send_boot_prompt "${cc_panes[3]}" "$QA_DIR" "QA Agent" "02_AGENT_PROMPTS/QA_PROMPT.md" "You own QA plan, test cases, bug reports, regression checks, and release decision."
    send_boot_prompt "${pm_panes[0]}" "$PLANNING_DIR" "Planning PM Agent" "02_AGENT_PROMPTS/PLANNING_PM_PROMPT.md" "You own PRD support, scope, requirements clarification, and user-intent refinement."
    send_boot_prompt "${pm_panes[1]}" "$DESIGN_DIR" "Design Agent" "02_AGENT_PROMPTS/DESIGN_PROMPT.md" "You own UX/UI/design system only. Do not implement production code unless explicitly assigned."
    send_boot_prompt "${pm_panes[2]}" "$BUSINESS_DIR" "Business Agent" "02_AGENT_PROMPTS/BUSINESS_PROMPT.md" "You own market, pricing, ICP, business model, and business constraints."
    send_boot_prompt "${pm_panes[3]}" "$MARKETING_DIR" "Marketing Agent" "02_AGENT_PROMPTS/MARKETING_PROMPT.md" "You own positioning, copy, channels, launch messaging, and campaign assets."
    send_boot_prompt "${or_panes[0]}" "$DEVOPS_DIR" "DevOps Agent" "02_AGENT_PROMPTS/DEVOPS_PROMPT.md" "You own deployment, CI/CD, runtime, infrastructure, observability, and rollback."
    send_boot_prompt "${or_panes[1]}" "$RISK_DIR" "Legal/Risk Agent" "02_AGENT_PROMPTS/LEGAL_RISK_PROMPT.md" "You own policy, privacy, legal, compliance, and operational risk."
    ;;
esac

cat <<INFO
Codex agents boot prompts sent to tmux session: $SESSION
Layout: $LAYOUT
Project root: $PROJECT_ROOT
Agent system: $AGENT_SYSTEM_DIR
Shared work: $AGENT_WORK_DIR
Worktrees: $WORKTREE_ROOT
Attach with: tmux attach -t $SESSION

Useful tmux keys:
  Ctrl+b z        Toggle zoom for the current pane
  Ctrl+b arrows   Move between panes
  Ctrl+b n/p      Move between windows
  Ctrl+b q        Show pane numbers
  Ctrl+b d        Detach
INFO
