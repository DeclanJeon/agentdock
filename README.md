# AgentDock

<p align="center">
  <strong>Hermes-only tmux workrooms for local multi-agent coding teams.</strong>
</p>

<p align="center">
  <a href="https://github.com/DeclanJeon/agentdock/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/DeclanJeon/agentdock/ci.yml?branch=main&label=ci&logo=github"></a>
  <a href="https://github.com/DeclanJeon/agentdock/releases"><img alt="Release" src="https://img.shields.io/github/v/release/DeclanJeon/agentdock?label=release&logo=github"></a>
  <img alt="Version" src="https://img.shields.io/badge/version-0.1.4-0f766e">
  <img alt="Runtime" src="https://img.shields.io/badge/runtime-Hermes%20Agent-111827">
  <img alt="Shell" src="https://img.shields.io/badge/shell-Bash-4EAA25?logo=gnubash&logoColor=white">
  <img alt="tmux" src="https://img.shields.io/badge/orchestration-tmux-1f2937">
</p>

AgentDock turns a normal project directory into a local multi-agent workroom. It starts real Hermes Agent sessions in tmux panes, gives each pane a durable role, and routes work through filesystem-backed job cards, inboxes, reports, and handoffs under `.agent-work`.

The important difference: the user works from the CEO/orchestrator Hermes pane. You do not need to keep running task commands in a second terminal. Give the CEO a job in natural language, and the CEO uses AgentDock's delegate helper to distribute task cards to the running role panes.

## What It Does

- Starts Hermes Agent roles inside a project-scoped tmux session.
- Uses `adock` as a short CLI and keeps `agentdock` as the compatibility command.
- Boots each role with generated instructions, shared context, inbox/outbox paths, and job lifecycle rules.
- Lets the CEO/orchestrator dispatch work from inside Hermes with `adock-delegate`.
- Supports BMAD-inspired role templates plus AgentDock supplemental roles such as CEO, CTO, marketing, planner, and QA.
- Keeps Codex/OpenCode/Gemini/Claude out of the AgentDock runtime path to avoid collisions with their own team features.
- Runs fully local: Bash, tmux, Hermes Agent, project files.

## Install

```bash
git clone https://github.com/DeclanJeon/agentdock.git
cd agentdock
./install.sh --prefix "$HOME/.local"
```

Make sure `~/.local/bin` is on your `PATH`, then verify:

```bash
adock doctor
```

AgentDock requires:

- `bash`
- `tmux`
- `git`
- `Hermes Agent`

If Hermes is missing, AgentDock points users to the official installer:

```bash
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
```

Hermes source: https://github.com/nousresearch/hermes-agent

## Quick Start

```bash
mkdir -p ~/work/my-project
cd ~/work/my-project

adock init
adock job "Analyze this project and propose the smallest implementation team for the first feature."
```

`adock job` starts the CEO/orchestrator Hermes pane when needed, creates a job under `.agent-work/07_JOBS`, and asks the CEO to choose templates, recruit the needed tmux/Hermes roles, assign task cards, collect role reports, and submit a timestamped final report.

Inside the first tmux pane, you can also tell the CEO/orchestrator what to do:

```txt
CEO, analyze this task, assign the needed team roles, and make the team execute it:
<your work request>
```

The CEO pane calls:

```bash
adock-delegate --from orchestrator --request "<your work request>"
```

AgentDock then creates a CEO-led job under `.agent-work/07_JOBS`. The CEO chooses the smallest useful team, recruits missing roles with `agentdock recruit`, assigns task cards, collects role reports through `agentdock job report`, and finishes with `agentdock job finish`.

## Team Layouts

Default initialization starts with one CEO/orchestrator:

```bash
adock init
```

Start with explicit roles:

```bash
adock init --roles "orchestrator,developer,qa,reviewer,uiux_designer,architect" --layout hybrid
adock start
```

Add roles while the room is running:

```bash
adock recruit api-implementer --template bmad-agent-dev --mission "Implement backend changes from task cards."
adock recruit product-scope --template bmad-pm --mission "Clarify scope and acceptance criteria."
adock recruit qa-gate --template agentdock-qa --mission "Verify behavior and regression risk."
adock recruit growth-plan --template agentdock-marketing --mission "Draft launch messaging and channel plan."
```

List templates:

```bash
adock roles list
```

## Commands

| Command | Purpose |
| --- | --- |
| `adock doctor [--json]` | Check system tools, Hermes, and project initialization. |
| `adock setup --yes` | Install or guide missing runtime dependencies. |
| `adock init [--roles "..."] [--layout hybrid]` | Create `.agentdock` and `.agent-work`. |
| `adock start` | Launch the tmux workroom. Default starts every configured role. |
| `adock stop --yes` | Stop the project tmux session. |
| `adock team` | Show configured roles and Hermes status. |
| `adock recruit <role>` | Add/start a Hermes role in the running workroom. |
| `adock job "..."` | Start a CEO-led job, auto-open the CEO Hermes pane, and ask the CEO to recruit the needed team. |
| `adock job report --from <role> --summary "..."` | Submit a timestamped role report to the active job and notify the CEO. |
| `adock job finish --summary "..."` | Mark the active job complete and write `YYMMDDHH:MM:SS-final.md` reports. |
| `adock delegate "..."` | Create a CEO-led job. Used internally by CEO panes. |
| `adock-delegate --from <role> --request "..."` | Hermes-facing CEO-led job helper. |
| `adock task "..."` | Script-friendly job creation and dispatch. |
| `adock send <role> "..."` | Send a message file and tmux message to a role. |
| `adock report [--json]` | Summarize session, current job, and reports. |

## Project Files

```txt
.agentdock/
  config.yml
  config.runtime
  prompts/
  generated/
  state/

.agent-work/
  07_JOBS/
    CURRENT.md
    JOB-*/
      README.md
      TEAM.md
      LIFECYCLE.md
      TASKS/
      REPORTS/
  08_DECISIONS/
  09_HANDOFFS/
  10_REPORTS/
  12_INBOX/
  13_OUTBOX/
  14_SHARED_CONTEXT/
  LOCKS.md
```

`.agentdock` is runtime configuration. `.agent-work` is the durable coordination layer between agents. Both are intentionally ignored by git.

## CI/CD

This repository ships with GitHub Actions:

- `ci.yml`: runs Bash syntax checks and the smoke test on every push and pull request.
- `release.yml`: when a `v*` tag is pushed, packages AgentDock and publishes a GitHub Release.

Create a release:

```bash
git tag v0.1.4
git push origin v0.1.4
```

## Verify Locally

```bash
bash -n bin/agentdock install.sh tests/smoke.sh
bash tests/smoke.sh
```

The smoke test uses a fake Hermes binary, starts tmux, validates Hermes-only runtime migration, verifies `adock-delegate`, dispatches task cards, and shuts the session down.

## Status

Version `0.1.4` is the current local release. It is intentionally Bash-first and conservative: no daemon, no hosted control plane, no hidden remote scheduler.

Current gaps:

- Worktree mode is configured but not implemented.
- Real Hermes authentication remains the user's responsibility.
- `update` and `uninstall` print safe guidance instead of managing hosted releases.
