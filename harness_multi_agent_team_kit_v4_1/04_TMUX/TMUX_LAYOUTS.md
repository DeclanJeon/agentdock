# tmux Layouts

v4.1 supports three tmux layouts for Codex multi-agent operation.

## Recommended: hybrid

```bash
.agent-system/04_TMUX/start-codex-agents.sh --layout hybrid --fresh
```

This creates three windows:

```text
command-center
├── CEO
├── Architecture
├── Development
└── QA

product-market
├── Planning
├── Design
├── Business
└── Marketing

ops-risk
├── DevOps
└── Legal/Risk
```

Use this for most real work. It keeps the screen readable while still giving you a command-center view.

## Single-window grid

```bash
.agent-system/04_TMUX/start-codex-agents.sh --layout grid --fresh
```

This places all agents into one tiled tmux window named `agents`.

Use this when you want to see every agent at once. It can become cramped on small screens.

## One window per agent

```bash
.agent-system/04_TMUX/start-codex-agents.sh --layout windows --fresh
```

This creates one tmux window per agent.

Use this when you want each Codex session to have maximum terminal space.

## Important flags

```bash
--fresh
```

Kills the existing tmux session before booting a new one. Use this when you changed layout or accidentally attached to an older session.

```bash
--no-worktrees
```

Runs all agents in the project root. This is simpler but less safe when multiple agents edit code.

## Environment examples

```bash
SESSION=pons-sfu-room CODEX_CMD=codex .agent-system/04_TMUX/start-codex-agents.sh --layout hybrid --fresh
```

```bash
CODEX_CMD="codex --dangerously-bypass-approvals-and-sandbox" .agent-system/04_TMUX/start-codex-agents.sh --layout grid --fresh
```

Only use permissive Codex modes when you understand the risk.

## Essential tmux keys

```text
Ctrl+b z        Toggle zoom for the current pane
Ctrl+b arrows   Move between panes
Ctrl+b n         Next window
Ctrl+b p         Previous window
Ctrl+b q         Show pane numbers
Ctrl+b d         Detach from tmux
```

## Recommended first boot

From your project root:

```bash
.agent-system/04_TMUX/start-codex-agents.sh --layout hybrid --fresh

tmux attach -t product-war-room
```

Then go to the CEO pane and give the first product goal.
