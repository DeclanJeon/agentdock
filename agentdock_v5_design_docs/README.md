# AgentDock v5 Product Design Documents

AgentDock v5 is a global CLI for launching customizable multi-agent AI coding workspaces from any project directory.

This document package is designed to be given directly to Codex or another coding agent so implementation can start without another planning pass.

## Core product sentence

AgentDock is a globally installed CLI that detects installed AI coding CLIs, lets the user define arbitrary roles, maps each role to a selected CLI, generates project-local prompts and workspace files, then launches a tmux-based multi-agent workroom from the current project directory.

## Critical design rule

Role is user-defined. CLI is user-selected. AgentDock only orchestrates.

## Document map

| File | Purpose |
|---|---|
| `00_PRODUCT_BRIEF.md` | One-page product summary |
| `01_PRD.md` | Product requirements document |
| `02_SRD.md` | System requirements document |
| `03_SRS.md` | Software requirements specification |
| `04_SDD.md` | Software design document |
| `05_SYSTEM_ARCHITECTURE.md` | Runtime and component architecture |
| `06_CLI_COMMAND_SPEC.md` | User-facing command specification |
| `07_CLI_ADAPTER_SPEC.md` | Codex, Claude, OpenCode, Hermes, Gemini, custom adapter model |
| `08_CONFIG_SCHEMA.md` | Global/project config schemas |
| `09_PROMPT_RUNTIME_SPEC.md` | Prompt generation, role templates, boot files |
| `10_TMUX_RUNTIME_SPEC.md` | tmux session/window/pane runtime rules |
| `11_INSTALLER_UPDATER_SPEC.md` | curl installer, update, uninstall behavior |
| `12_PROJECT_WORKSPACE_SPEC.md` | `.agentdock` and `.agent-work` project layout |
| `13_SECURITY_PRIVACY_SPEC.md` | Safety, permissions, install consent, boundaries |
| `14_QA_TEST_PLAN.md` | Test strategy and acceptance gates |
| `15_IMPLEMENTATION_PLAN.md` | Milestones, file tree, implementation order |
| `16_CODEX_TASK_PACK.md` | Copy-pasteable tasks for Codex implementation |
| `17_MIGRATION_FROM_V4_1.md` | How to transform the uploaded v4.1 kit into v5 |
| `examples/` | Concrete config, adapter, prompt, and script examples |

## Intended implementation language

The MVP can be implemented in Bash first, because the existing v4.1 kit is Bash/tmux oriented. A TypeScript rewrite can follow after the CLI behavior stabilizes.

Recommended MVP stack:

- Bash for installer and runtime scripts
- `tmux` for process/session orchestration
- `git` for repo detection and optional worktrees
- `python3` or `yq` optional for YAML parsing, but avoid hard dependency in v1 if possible
- Markdown for role prompts, reports, handoffs, and task files

## Minimum v5 MVP

1. Global install to `~/.local/bin/agentdock` and `~/.local/share/agentdock`.
2. `agentdock doctor` detects system tools and AI CLIs.
3. `agentdock install <cli>` installs selected AI CLI only after explicit confirmation.
4. `agentdock init` creates project-local `.agentdock` and `.agent-work`.
5. User can define arbitrary roles and assign each role to any detected CLI.
6. `agentdock start` launches tmux using current project directory as project root.
7. Boot prompts are generated dynamically per role.
8. Agents coordinate through files, not shared chat.

## Non-goals for MVP

- No SaaS dashboard.
- No remote background execution.
- No LLM API gateway.
- No automatic account login.
- No hidden installation of AI tools.
- No hardcoded role-to-CLI mapping.
