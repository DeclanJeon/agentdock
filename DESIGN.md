# AgentDock CLI-Only Design

## Product Boundary

AgentDock is a terminal-first orchestrator. The supported user interface is the `adock`/`agentdock` CLI plus tmux panes. The former desktop app and visual workspace runtime are removed.

## Primary User Flow

```bash
adock job "작업내용"
```

The CEO agent receives the job, decides whether the work should stay solo or needs a small team, recruits only useful Hermes roles, assigns task cards, tracks gates, and writes the final report.

## Runtime Principles

- Simple jobs should not spawn unnecessary teams.
- Team members are real Hermes Agent sessions in tmux, not simulated UI agents or Hermes-native/internal subagents.
- Team-classified jobs auto-start selected missing workers via the `agentdock recruit`/tmux path before task messages are sent.
- Coordination state lives in `.agent-work` and remains inspectable/editable as plain files.
- CLI diagnostics may summarize state, but must not become a second control plane.
- Runtime model settings are stored in AgentDock config and can be applied to running Hermes panes.
- Optional per-role worktrees are allowed for isolation, with explicit merge preview/apply commands.

## Supported Surfaces

- `adock job`, `agentdock intake`, `adock-delegate`, `job report`, `job finish`, `job tick`, `job tft`, `job meeting`
- `adock recruit`, `send`, `broadcast`, `inbox`, `watch`, `team`
- `adock workspace snapshot --json` and `workspace export --out <file>` as read-only CLI diagnostics
- `adock workspace model ...` for Hermes model configuration
- `adock worktree ...` for optional role worktree isolation

## Removed Surfaces

- Desktop app launchers
- Tauri bridge commands
- React/Vite UI code
- Generated character/GIF assets
- Native screenshot/visual QA harnesses
