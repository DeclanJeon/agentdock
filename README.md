# AgentDock

<p align="center">
  <strong>CLI-only Hermes/tmux workrooms for local multi-agent jobs.</strong>
</p>

<p align="center">
  <a href="https://github.com/DeclanJeon/agentdock/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/DeclanJeon/agentdock/ci.yml?branch=main&label=ci&logo=github"></a>
  <a href="https://github.com/DeclanJeon/agentdock/releases"><img alt="Release" src="https://img.shields.io/github/v/release/DeclanJeon/agentdock?label=release&logo=github"></a>
  <img alt="Version" src="https://img.shields.io/badge/version-0.3.2-0f766e">
  <img alt="Runtime" src="https://img.shields.io/badge/runtime-Hermes%20Agent-111827">
  <img alt="Shell" src="https://img.shields.io/badge/shell-Bash-4EAA25?logo=gnubash&logoColor=white">
  <img alt="tmux" src="https://img.shields.io/badge/orchestration-tmux-1f2937">
</p>

---

## Overview

AgentDock turns a project directory into a local multi-agent workroom. It is now CLI-only: there is no desktop app, no bundled UI runtime, and no browser-like control surface. The main command is:

```bash
adock job "작업내용"
```

The job flow is filesystem-backed under `.agent-work`:

1. `adock job "..."` creates a CEO-led job.
2. The CEO Hermes pane starts or is reused.
3. The CEO classifies the job, keeps simple work solo, and recruits only useful Hermes roles for larger work.
4. Roles receive task cards, communicate through inboxes, and submit role reports.
5. QA/review/TFT/meeting gates run only when the job risk requires them.
6. `adock job finish` writes the final report and disbands completed/reported worker panes.

AgentDock intentionally avoids running Codex/Claude/Gemini/etc. as managed worker CLIs. Runtime workers are Hermes Agent sessions in tmux panes so behavior is inspectable and local.

## What's New In 0.3.2

- Removed the desktop application stack entirely: React, Vite, Tauri, native app packaging, generated character assets, and UI-only tests/docs are gone.
- Kept the terminal workflow focused on `adock job "..."`, CEO orchestration, task cards, reports, QA gates, TFT/meeting records, model settings, and optional worktrees.
- Simplified install/release artifacts so packages ship only the CLI, adapters, roles, tests, and scripts.
- Kept `adock workspace snapshot --json` and `adock workspace export --out <file>` as lightweight read-only CLI diagnostics; they do not launch a desktop runtime or use bundled visual assets.

## Core Commands

| Command | Purpose |
| --- | --- |
| `adock init` | Initialize `.agentdock` and `.agent-work` in the current project. |
| `adock setup` | Install/check Hermes Agent and required local tools. |
| `adock doctor` | Check tmux, Hermes, project state, and adapter availability. |
| `adock job "작업내용"` | Start a CEO-led job from the terminal. |
| `adock job report --from <role> --summary "..."` | Submit a role report. |
| `adock job finish --summary "..."` | Finalize the active job after required reports/gates pass. |
| `adock job tick [--json] [--apply]` | Ask the CEO loop for safe next actions and optionally apply follow-ups. |
| `adock job tft create|close ...` | Track temporary cross-role blocker teams when needed. |
| `adock job meeting start|conclude ...` | Record bounded coordination meetings and decisions. |
| `adock recruit <role> --template <id>` | Add a Hermes role to the running team. |
| `adock send <role> "..."` | Send a durable inbox message to a role. |
| `adock broadcast "..."` | Send a shared durable message to all configured roles. |
| `adock workspace snapshot --json` | Print read-only job/team/report status JSON. |
| `adock workspace export --out workspace.html` | Write a static CLI status report HTML file. |
| `adock workspace model set --model <id> --apply-running --json` | Save/apply the Hermes model for future/running roles. |
| `adock worktree init|create|list|status|merge|remove` | Manage optional per-role git worktrees. |

## Install

```bash
git clone https://github.com/DeclanJeon/agentdock.git
cd agentdock
./install.sh --prefix "$HOME/.local"
adock doctor
```

If Hermes Agent is missing, `install.sh` installs it from GitHub unless `--skip-hermes` is passed. To defer Hermes setup:

```bash
./install.sh --skip-hermes --prefix "$HOME/.local"
```

## Typical Use

```bash
cd /path/to/project
adock init
adock setup
adock job "이 저장소의 테스트 실패 원인을 분석하고 수정해줘"
```

Useful follow-up commands:

```bash
adock team
adock inbox ceo-orchestrator
adock workspace snapshot --json
adock job tick --json
adock job finish --summary "수정 및 검증 완료"
```

## State Layout

AgentDock writes local coordination files only inside the project:

- `.agentdock/` — project runtime config, generated role prompts, cache/state.
- `.agent-work/07_JOBS/` — active and historical jobs.
- `.agent-work/12_INBOX/` — durable role inboxes.
- `.agent-work/10_REPORTS/` — role and final reports.
- `.agent-work/15_STATUS/` — lightweight role status JSON for CLI snapshots.

## Release Checklist

```bash
bash scripts/check-version.sh
bash tests/smoke.sh
git tag v0.3.2
git push origin v0.3.2
```

## Status

Version `0.3.2` is CLI-only. The desktop application has been removed; use `adock job "..."` as the primary interface.
