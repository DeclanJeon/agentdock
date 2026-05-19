# AgentDock

<p align="center">
  <a href="https://github.com/DeclanJeon/agentdock">
    <img alt="AgentDock on GitHub" src="https://img.shields.io/badge/GitHub-AgentDock-181717?style=for-the-badge&logo=github&logoColor=white">
  </a>
</p>

<p align="center">
  <strong>Hermes-only tmux workrooms for local multi-agent coding teams.</strong>
</p>

<p align="center">
  Start one CEO agent, hand it a job, and let it recruit the right local Hermes roles, assign task cards, collect role reports, and submit a final report.
</p>

<p align="center">
  <a href="https://github.com/DeclanJeon/agentdock/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/DeclanJeon/agentdock/ci.yml?branch=main&label=ci&logo=github"></a>
  <a href="https://github.com/DeclanJeon/agentdock/releases"><img alt="Release" src="https://img.shields.io/github/v/release/DeclanJeon/agentdock?label=release&logo=github"></a>
  <img alt="Version" src="https://img.shields.io/badge/version-0.1.7-0f766e">
  <img alt="Runtime" src="https://img.shields.io/badge/runtime-Hermes%20Agent-111827">
  <img alt="Shell" src="https://img.shields.io/badge/shell-Bash-4EAA25?logo=gnubash&logoColor=white">
  <img alt="tmux" src="https://img.shields.io/badge/orchestration-tmux-1f2937">
</p>

---

## Overview

AgentDock turns any project directory into a local multi-agent workroom. It starts Hermes Agent sessions in tmux panes, gives each pane a durable role, and coordinates work through filesystem-backed job cards, inboxes, reports, handoffs, and lifecycle files under `.agent-work`.

The main interaction is CEO-led:

1. You create a job with `adock job "..."`.
2. AgentDock starts the CEO/orchestrator Hermes pane if needed.
3. The CEO reads the active job, reuses suitable configured/running roles, and recruits only missing roles with `agentdock recruit`.
4. Recruited roles work from task cards and submit results with `agentdock job report`.
5. The CEO aggregates role reports and submits the final report with `agentdock job finish`.
6. AgentDock disbands only completed/reported worker panes after the final CEO report is written.

AgentDock intentionally keeps Codex, OpenCode, Gemini, Claude, and other CLIs out of the runtime path. The runtime is Hermes-only to avoid collisions with each tool's own agent/team features.

## Features

| Feature | What it gives you |
| --- | --- |
| CEO-led job orchestration | `adock job "..."` creates a live job, starts or reuses the CEO pane, and pushes it directly into team selection and execution. |
| Real tmux workrooms | Team members are actual Hermes sessions in tmux panes/windows, so you can inspect, attach, and manage the running room. |
| Team reuse | Every job includes a configured/running team snapshot so the CEO can reuse suitable roles instead of recreating them. |
| Template-driven recruiting | The CEO can recruit BMAD-inspired roles and AgentDock roles for CEO, CTO, marketing, planning, and QA lanes. |
| Task cards | Selected roles receive markdown task cards under `.agent-work/07_JOBS/JOB-*/TASKS/`. |
| Inbox dispatch | `adock send` and job commands write durable inbox messages under `.agent-work/12_INBOX/` and also send to the tmux pane when it is running. |
| Role reports | Roles submit `YYMMDDHH:MM:SS-<role>.md` reports with `adock job report`. |
| CEO final reports | `adock job finish` aggregates role reports into `YYMMDDHH:MM:SS-final.md` and copies it to `.agent-work/10_REPORTS/<ceo>/`. |
| Completion-gated teardown | `adock job finish` refuses missing selected-role reports, then tears down only completed/reported worker panes. Unfinished panes stay open. |
| Hermes-only runtime | Runtime panes use Hermes Agent only, avoiding collisions with Codex, Claude, Gemini, or other CLIs' own agent systems. |
| Local-first state | Bash, tmux, Hermes Agent, and project files. No daemon, hosted scheduler, or remote control plane. |
| Release/version guard | `scripts/check-version.sh` keeps `VERSION`, README, smoke tests, and release tags synchronized. |

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

If Hermes is missing, AgentDock prints the official installer:

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

What happens next:

- AgentDock creates `.agentdock/` and `.agent-work/` state.
- The CEO/orchestrator Hermes pane opens automatically when needed.
- The active job is written under `.agent-work/07_JOBS/JOB-*`.
- The CEO is instructed to inspect the existing team, reuse suitable roles, recruit only missing roles, assign task cards, and start execution immediately.
- Each recruited role submits results back to the CEO with `agentdock job report`.
- The CEO finishes by writing `YYMMDDHH:MM:SS-final.md`, then AgentDock disbands only completed/reported worker panes.

## CEO Workflow

Inside the CEO pane, the normal flow is:

```bash
agentdock roles list
agentdock recruit api-implementer --template bmad-agent-dev --mission "Implement backend changes from task cards."
agentdock recruit qa-gate --template agentdock-qa --mission "Verify behavior and regression risk."
```

Each role then reports completed work:

```bash
agentdock job report --from api-implementer --summary "Implemented the API change, ran tests, no known blockers."
agentdock job report --from qa-gate --summary "Validated acceptance criteria and smoke-tested the workflow."
```

After all selected roles have reported, the CEO submits the final report and disbands completed/reported worker panes:

```bash
agentdock job finish --summary "Feature implemented, verified, and ready for review."
```

## Job Lifecycle

AgentDock jobs are filesystem-backed so the team can recover context across panes and sessions.

| Phase | What happens |
| --- | --- |
| Intake | `adock job "..."` creates `.agent-work/07_JOBS/JOB-*`, writes `README.md`, `TEAM.md`, `LIFECYCLE.md`, and a CEO task card. |
| Team selection | The CEO inspects the existing configured/running team snapshot, reuses suitable roles, and recruits only missing capabilities. |
| Assignment | The CEO writes task cards under `TASKS/` and sends each selected role an inbox message. |
| Execution | Roles work in real Hermes/tmux panes and coordinate through `.agent-work`. |
| Reporting | Each selected role submits a timestamped report with `adock job report --from <role> --summary "..."`. |
| Finalization | `adock job finish` refuses to complete if selected task cards have no matching role report. |
| Teardown | After the final CEO report is written, only completed/reported worker panes are closed. Unfinished or unreported panes stay open. |

## Manual Delegation

You can also work directly inside the CEO pane:

```txt
CEO, analyze this task, assign the needed team roles, and make the team execute it:
<your work request>
```

The CEO pane can call:

```bash
adock-delegate --from orchestrator --request "<your work request>"
```

That creates the same CEO-led job flow as `adock job`.

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

## Command Reference

`agentdock` and `adock` are the same CLI. `adock` is the short alias installed by `install.sh`.

### Basic Commands

| Command | Purpose |
| --- | --- |
| `adock version` | Print the installed AgentDock version. |
| `adock help` | Print the command help. |
| `adock doctor [--json]` | Detect system tools, Hermes, adapters, and project initialization state. |
| `adock setup [--cli hermes] [--yes]` | Install or guide missing runtime dependencies. Runtime roles are Hermes-only. |
| `adock update` | Print safe update guidance. |
| `adock uninstall` | Print safe uninstall guidance. Project `.agentdock` and `.agent-work` are never deleted by this command. |

### Project Setup

| Command | Purpose |
| --- | --- |
| `adock init` | Initialize `.agentdock` and `.agent-work` with the default `ceo-orchestrator` role. |
| `adock init --roles "ceo,dev,qa" --layout hybrid` | Initialize with explicit role IDs and a layout. |
| `adock init --preset core-4` | Initialize with `orchestrator developer qa reviewer`. |
| `adock init --force` | Regenerate AgentDock project files for an existing initialized directory. |
| `adock role add <role> [--cli hermes]` | Add a configured project role without necessarily starting a pane. |
| `adock assign <role> --cli hermes` | Assign a role to Hermes. Non-Hermes runtime assignment is rejected. |

### Runtime And Team

| Command | Purpose |
| --- | --- |
| `adock start` | Launch the project tmux workroom. By default it starts every configured role. |
| `adock start --no-attach` | Start the workroom without attaching your terminal. |
| `adock start --bootstrap-only` | Start only the CEO/orchestrator pane. Used by job intake when no session exists. |
| `adock start --fresh --yes` | Kill the existing project session and start a fresh one. |
| `adock start --skip-missing` | Start even if an assigned CLI is missing. Useful for smoke tests or partial environments. |
| `adock stop --yes` | Stop the whole AgentDock tmux session, including all windows and panes. |
| `adock team` | Show configured roles, their assigned CLI, and install status. |
| `adock recruit <role>` | Add/configure a role if needed and start its Hermes pane when the workroom is running. |
| `adock recruit <role> --template bmad-agent-dev --mission "..." --instructions "..."` | Recruit or update a role from a BMAD or AgentDock template with job-specific mission text. |
| `adock send <role> "..."` | Write a durable inbox message and send it to the role's tmux pane when it is running. |

### Jobs And Reports

| Command | Purpose |
| --- | --- |
| `adock job "..."` | Create a CEO-led job, start/reuse the CEO pane, and send the CEO into team selection immediately. |
| `adock job --no-attach "..."` | Create and dispatch a job without attaching to tmux. |
| `adock job report --from <role> --summary "..."` | Submit a timestamped role report, copy it to `.agent-work/10_REPORTS/<role>/`, and notify the CEO. |
| `adock job report --from <role> --file report.md` | Submit a role report from a file. |
| `adock job finish --summary "..."` | Write the final CEO report, copy it to `.agent-work/10_REPORTS/<ceo>/`, and close only completed/reported worker panes. |
| `adock job finish --keep-team --summary "..."` | Write the final report but leave running panes open. `--no-teardown` is an alias. |
| `adock job status` | Show the same summary as `adock report`. |
| `adock task "..."` | Script-friendly job creation that dispatches task cards to configured roles. |
| `adock delegate "..."` | Create a CEO-led job. This is the user-facing form of the delegate flow. |
| `adock-delegate --from <role> --request "..."` | Hermes-facing helper used inside role panes to create a CEO-led job from a direct user request. |
| `adock report [--json]` | Summarize session state, configured/running roles, current job, lifecycle status, and recent reports. |

### Templates And Adapters

| Command | Purpose |
| --- | --- |
| `adock roles list` | List bundled BMAD and AgentDock role templates. |
| `adock roles sync bmad --yes` | Sync BMAD role templates into the user config directory from the default source. |
| `adock roles sync bmad --offline --yes` | Install bundled fallback BMAD templates without network access. |
| `adock cli list [--json]` | List adapter registry entries and detected install status. |
| `adock cli add --id <id> --command <cmd> --install "..."` | Add a custom adapter entry for detection/install guidance. Runtime panes still enforce Hermes. |
| `adock install tmux --yes` | Preview or run supported system-tool install guidance. |
| `adock install hermes --yes` | Print or run adapter install guidance when available. |

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

## Verify Locally

```bash
bash -n bin/agentdock install.sh tests/smoke.sh scripts/check-version.sh
bash scripts/check-version.sh
bash tests/smoke.sh
```

The smoke test uses a fake Hermes binary, starts tmux, validates Hermes-only runtime migration, verifies CEO-led jobs, checks role report submission, aggregates final reports, protects unfinished panes, and shuts the session down.

## Release

This repository ships with GitHub Actions:

- `ci.yml`: runs Bash syntax checks and the smoke test on every push and pull request.
- `release.yml`: packages AgentDock and publishes a GitHub Release when a `v*` tag is pushed.

Before tagging a release, update all version surfaces together:

- `VERSION`
- `bin/agentdock` (`AGENTDOCK_VERSION`)
- `README.md` badge, release example, and status line
- `tests/smoke.sh` version assertions

Verify they are synchronized:

```bash
bash scripts/check-version.sh
```

Create a release:

```bash
git tag v0.1.7
git push origin v0.1.7
```

## Status

Version `0.1.7` is the current local release. It is intentionally Bash-first and conservative: no daemon, no hosted control plane, no hidden remote scheduler.

Current gaps:

- Worktree mode is configured but not implemented.
- Real Hermes authentication remains the user's responsibility.
- `update` and `uninstall` print safe guidance instead of managing hosted releases.
