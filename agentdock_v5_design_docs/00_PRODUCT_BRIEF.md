# AgentDock v5 Product Brief

## Problem

Developers increasingly use multiple AI coding CLIs: Codex, Claude Code, OpenCode, Hermes Agent, Gemini CLI, and others. Each tool has its own strengths, but running them as a coordinated multi-agent team is awkward:

- users manually open many terminals;
- roles are unclear;
- prompts are copied by hand;
- agents do not share context;
- multiple agents edit the same files;
- reports, decisions, and handoffs are not preserved;
- setup is too personal and difficult for others to reproduce.

The existing v4.1 kit solves part of this by creating a project-local `.agent-system` and launching Codex agents with tmux. v5 must become a globally installed CLI that works from any project directory and supports arbitrary AI CLIs and user-defined roles.

## Product

AgentDock is a global command-line tool that turns a project directory into a multi-agent AI coding workspace.

The user installs AgentDock once:

```bash
curl -fsSL https://agentdock.dev/install.sh | bash
```

Then inside any project:

```bash
agentdock init
agentdock start
```

AgentDock detects installed AI CLIs, offers optional installation for missing ones, lets the user create roles and assign each role to a CLI, generates role-specific boot prompts, and launches a tmux workroom.

## Target users

- product engineers using AI coding CLIs heavily;
- solo builders who want a small AI team per project;
- teams experimenting with agentic coding workflows;
- developers who want reproducible tmux-based AI workspaces;
- users who want to mix Codex, Claude, Gemini, Hermes, OpenCode, or custom CLIs.

## Product principles

1. **Global install, project-local runtime.** AgentDock itself lives globally. Each project only receives config, prompts, and workspace files.
2. **No hardcoded team.** Roles are templates, not destiny. Users can add, rename, remove, and remap roles.
3. **No hardcoded CLI.** CLI tools are detected and assigned by the user.
4. **Consent-first installation.** Missing AI CLIs are never installed silently.
5. **File-based coordination.** Agents coordinate through `.agent-work`, not through invisible chat state.
6. **tmux as the cockpit.** tmux handles session persistence, panes, windows, restart, observation, and control.
7. **Prompts are inspectable.** Every generated boot prompt is a file the user can read and edit.
8. **MVP before magic.** Prefer reliable shell automation to fragile cleverness.

## Success metrics

- User can install AgentDock globally in one command.
- User can initialize a project in under 3 minutes.
- AgentDock accurately reports which supported CLIs are installed.
- User can assign at least 3 custom roles to different CLIs.
- `agentdock start` launches a working tmux session from the current project directory.
- Agents receive readable role boot prompts.
- Work reports and handoffs are written to `.agent-work`.
