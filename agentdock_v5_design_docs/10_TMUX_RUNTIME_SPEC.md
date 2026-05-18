# tmux Runtime Specification

## 1. Purpose

tmux is AgentDock's local process cockpit. It provides persistent sessions, pane/window layout, visual monitoring, and manual control.

## 2. Layout modes

### 2.1 `windows`

One tmux window per role.

Best for many workers.

```txt
window: orchestrator
window: backend
window: frontend
window: qa
```

### 2.2 `grid`

All roles in one tiled window.

Best for 2 to 6 workers.

```txt
agents
├─ orchestrator
├─ backend
├─ frontend
└─ qa
```

### 2.3 `hybrid`

Group roles by window.

Best default.

```txt
command-center
├─ orchestrator
├─ planner
└─ reviewer

implementation
├─ backend
├─ frontend
└─ devops

quality-docs
├─ qa
└─ docs
```

## 3. Session behavior

Default session name:

```txt
<project-name>-agents
```

Rules:

- If session does not exist, create it.
- If session exists and `--fresh` is not used, attach to it.
- If `--fresh` is used, confirm before killing existing session unless `--yes`.

## 4. Pane setup

For each role:

1. Create pane/window.
2. Set pane title to role display name.
3. `cd` to role cwd.
4. Launch assigned CLI command.
5. Wait briefly.
6. Send boot prompt instruction.

Pseudo-command:

```bash
tmux send-keys -t "$target" "cd '$cwd'" C-m
tmux send-keys -t "$target" "$run_cmd" C-m
sleep 1
tmux send-keys -t "$target" "Read '$boot_file' and follow it. Say READY - $display_name when ready." C-m
```

## 5. cwd resolution

Supported cwd modes:

- `project_root`: run inside project root.
- `worktree`: run inside role-specific git worktree.
- `custom`: run inside configured path.

MVP default: `project_root`.

## 6. Worktree mode

When enabled:

```txt
../<project>-agent-worktrees/<role-id>/
```

Each worktree should symlink:

```txt
.agentdock -> <project>/.agentdock
.agent-work -> <project>/.agent-work
```

## 7. Pane target tracking

AgentDock should record pane ids:

```txt
.agentdock/state/panes.env
```

Example:

```bash
PANE_orchestrator="%1"
PANE_backend="%2"
PANE_frontend="%3"
```

This allows `agentdock send <role> "..."`.

## 8. Task dispatch

`agentdock task` should send to:

1. agent marked `orchestrator=true`, if exists;
2. role id `orchestrator`, if exists;
3. first configured agent;
4. all agents if `--broadcast`.

Message:

```txt
New AgentDock job created: .agent-work/07_JOBS/JOB-<id>/README.md
Read it and coordinate through .agent-work.
```

## 9. Stop behavior

`agentdock stop`:

- checks session exists;
- asks confirmation;
- kills only that session;
- does not delete files.

## 10. Error handling

- Missing tmux: fail with install guidance.
- Invalid layout: fail and show valid values.
- Missing CLI for role: fail before creating session unless `--skip-missing` is provided.
- Pane send failure: warn and continue with other panes.

## 11. UI settings

AgentDock should set helpful tmux options for its session:

```bash
tmux set-option -t "$SESSION" pane-border-status top
tmux set-option -t "$SESSION" pane-border-format ' #P #{pane_title} '
tmux set-option -t "$SESSION" status-left "[$SESSION:$LAYOUT] "
```

Do not alter global tmux config.
