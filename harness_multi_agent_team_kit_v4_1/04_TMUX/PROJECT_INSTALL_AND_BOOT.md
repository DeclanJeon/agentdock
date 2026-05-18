# Project Install and Boot Guide

## 1. Install the kit into a real project

From the extracted kit directory:

```bash
./install-agent-system.sh --project /path/to/your/project
```

This creates:

```txt
/path/to/your/project/.agent-system
/path/to/your/project/.agent-work
```

## 2. Start the multi-agent war-room

```bash
cd /path/to/your/project
.agent-system/04_TMUX/start-codex-agents.sh
```

Then attach:

```bash
tmux attach -t product-war-room
```

## 3. Optional: custom Codex command

If your Codex command is not `codex`:

```bash
CODEX_CMD="your-codex-command" .agent-system/04_TMUX/start-codex-agents.sh
```

## 4. Optional: disable worktrees

```bash
.agent-system/04_TMUX/start-codex-agents.sh --no-worktrees
```

This makes every agent run inside the project root.

## 5. Send a task file to an agent

```bash
.agent-system/04_TMUX/send-task-to-agent.sh architecture .agent-work/07_JOBS/JOB-260517-001/TASKS/TASK-001.md
```

## 6. Spawn an extra agent

```bash
.agent-system/04_TMUX/spawn-agent.sh researcher
```
