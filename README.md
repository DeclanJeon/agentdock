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
  <img alt="Version" src="https://img.shields.io/badge/version-0.1.4-0f766e">
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
3. The CEO reads the active job, selects the smallest useful team, and recruits missing roles with `agentdock recruit`.
4. Recruited roles work from task cards and submit results with `agentdock job report`.
5. The CEO aggregates role reports and submits the final report with `agentdock job finish`.

AgentDock intentionally keeps Codex, OpenCode, Gemini, Claude, and other CLIs out of the runtime path. The runtime is Hermes-only to avoid collisions with each tool's own agent/team features.

## Highlights

| Capability | What it gives you |
| --- | --- |
| CEO-led jobs | `adock job "..."` creates a live job and pushes the CEO past READY into team selection and execution. |
| Real tmux roles | Team members are actual Hermes sessions in tmux panes/windows, not hidden in-process helpers. |
| Template-driven recruiting | CEO can recruit BMAD-inspired roles and AgentDock supplemental roles such as CEO, CTO, planning, marketing, and QA. |
| Durable coordination | Job state lives in `.agent-work`: task cards, inboxes, handoffs, reports, lifecycle, and shared context. |
| Report handoff | Roles submit timestamped reports to the CEO; the CEO aggregates them into a final timestamped report. |
| Local-first runtime | Bash, tmux, Hermes Agent, and project files. No daemon or hosted scheduler. |

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
- The CEO is instructed to choose templates, recruit missing roles, assign task cards, and start execution immediately.
- Each recruited role submits results back to the CEO with `agentdock job report`.
- The CEO finishes by writing `YYMMDDHH:MM:SS-final.md`.

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

The CEO submits the final report:

```bash
agentdock job finish --summary "Feature implemented, verified, and ready for review."
```

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
| `adock job "..."` | Start a CEO-led job and auto-open the CEO Hermes pane. |
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

## Verify Locally

```bash
bash -n bin/agentdock install.sh tests/smoke.sh
bash tests/smoke.sh
```

The smoke test uses a fake Hermes binary, starts tmux, validates Hermes-only runtime migration, verifies CEO-led jobs, checks role report submission, aggregates final reports, and shuts the session down.

## Release

This repository ships with GitHub Actions:

- `ci.yml`: runs Bash syntax checks and the smoke test on every push and pull request.
- `release.yml`: packages AgentDock and publishes a GitHub Release when a `v*` tag is pushed.

Create a release:

```bash
git tag v0.1.4
git push origin v0.1.4
```

## Status

Version `0.1.4` is the current local release. It is intentionally Bash-first and conservative: no daemon, no hosted control plane, no hidden remote scheduler.

Current gaps:

- Worktree mode is configured but not implemented.
- Real Hermes authentication remains the user's responsibility.
- `update` and `uninstall` print safe guidance instead of managing hosted releases.
