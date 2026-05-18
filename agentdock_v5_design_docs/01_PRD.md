# PRD: AgentDock v5

## 1. Product overview

AgentDock v5 is a globally installed CLI that launches customizable tmux-based multi-agent AI workspaces inside any software project.

It evolves the uploaded `harness_multi_agent_team_kit_v4_1` from a project-copied Codex-only kit into a reusable multi-CLI orchestration product.

## 2. Goals

### 2.1 Primary goals

- Install AgentDock globally with one command.
- Run AgentDock from any project directory.
- Detect supported AI CLIs installed on the user's system.
- Show installed and missing CLIs clearly.
- Allow user-approved installation of missing CLIs.
- Let users create or select roles dynamically.
- Let users map each role to any available AI CLI.
- Generate role-specific prompt files and boot files automatically.
- Launch a tmux session with one pane/window per configured agent.
- Preserve shared work state under `.agent-work`.

### 2.2 Secondary goals

- Support built-in role presets for faster setup.
- Support custom CLI adapters.
- Support custom role templates.
- Support optional git worktrees per role.
- Support reusable project profiles.
- Allow later migration to TypeScript without changing user-facing behavior.

## 3. Non-goals

- AgentDock does not implement its own LLM model.
- AgentDock does not hide or bypass AI CLI authentication.
- AgentDock does not run autonomous background work outside the user's terminal session.
- AgentDock does not force a specific AI vendor.
- AgentDock does not replace git, GitHub, Jira, Linear, or project management systems.
- AgentDock does not guarantee CLIs have identical behavior.

## 4. User personas

### 4.1 Solo product engineer

Wants to run one orchestrator, one developer, one reviewer, and one QA agent inside a project without manually creating tmux panes or rewriting prompts.

### 4.2 AI workflow power user

Already uses Codex, Claude, OpenCode, Gemini, and wants to compare or combine them in the same project.

### 4.3 Team lead / technical PM

Wants reproducible agent setups so team members can run the same AI workroom layout.

### 4.4 Open-source maintainer

Wants lightweight, inspectable automation that does not require a hosted service.

## 5. User stories

### Installation

- As a user, I can install AgentDock once globally so I can use it in many projects.
- As a user, I can run `agentdock doctor` to verify dependencies.
- As a user, I can uninstall AgentDock cleanly.

### CLI detection and installation

- As a user, I can see which supported AI CLIs are installed.
- As a user, I can see the path and version of each detected CLI when available.
- As a user, I can choose to install a missing CLI.
- As a user, I can review the exact install command before it runs.
- As a user, I can skip missing CLI installation.
- As a user, I can add a custom CLI adapter.

### Project initialization

- As a user, I can run `agentdock init` from a project directory.
- As a user, I can create a custom team by entering role names.
- As a user, I can choose built-in role templates.
- As a user, I can assign any detected CLI to any role.
- As a user, I can choose layout: `hybrid`, `grid`, or `windows`.
- As a user, I can choose whether to use git worktrees.

### Runtime

- As a user, I can run `agentdock start` to launch my configured agents.
- As a user, I can stop the session with `agentdock stop`.
- As a user, I can send a task using `agentdock task "..."`.
- As a user, I can collect status with `agentdock report`.

### Prompts and workspace

- As a user, I can inspect generated boot prompts.
- As a user, I can edit project-local prompts.
- As a user, I can see reports, decisions, and handoffs under `.agent-work`.

## 6. MVP scope

### Required commands

- `agentdock doctor`
- `agentdock cli list`
- `agentdock install <cli>`
- `agentdock init`
- `agentdock start`
- `agentdock stop`
- `agentdock task "..."`
- `agentdock report`
- `agentdock role add`
- `agentdock assign <role> <cli>`

### Required built-in adapters

- `codex`
- `claude`
- `opencode`
- `hermes`
- `gemini`
- `custom`

### Required built-in role templates

- `orchestrator`
- `planner`
- `architect`
- `developer`
- `frontend`
- `backend`
- `qa`
- `reviewer`
- `devops`
- `docs`
- `risk`
- `custom`

## 7. UX requirements

- All destructive actions must ask for confirmation.
- Install commands for third-party CLIs must be shown before execution.
- `agentdock start` must not guess a project root from the global install path. It must use the current directory or configured project root.
- Generated prompt files must be readable Markdown.
- The user must be able to rerun `agentdock init` safely without losing existing custom prompts unless they confirm overwrite.

## 8. Acceptance criteria

AgentDock v5 MVP is acceptable when:

1. A fresh Linux/macOS/WSL2 user can install AgentDock globally.
2. `agentdock doctor` detects `git`, `tmux`, and supported AI CLIs.
3. Missing CLIs are shown as missing, not ignored.
4. User can install or skip missing CLIs.
5. User can initialize a project with at least 4 custom roles.
6. User can assign different CLIs to different roles.
7. `agentdock start` creates a tmux session named from the project by default.
8. Each pane launches the configured CLI from the correct project directory.
9. Each agent receives a boot prompt file path.
10. `.agent-work` contains job, report, handoff, inbox, outbox, and shared-context directories.
