# Config Schema

## 1. Config design

AgentDock uses three config levels:

1. Built-in defaults under `~/.local/share/agentdock`.
2. User-level overrides under `~/.config/agentdock`.
3. Project-level config under `<project>/.agentdock`.

Project-level config wins.

## 2. Global config

Path:

```txt
~/.config/agentdock/global.conf
```

Example:

```bash
AGENTDOCK_DEFAULT_LAYOUT="hybrid"
AGENTDOCK_DEFAULT_ATTACH="1"
AGENTDOCK_DEFAULT_WORKTREES="0"
AGENTDOCK_PREFERRED_INSTALL_METHOD="npm"
```

## 3. Project config YAML

Path:

```txt
.agentdock/config.yml
```

Example:

```yaml
version: 1

project:
  name: my-app
  root: /home/me/projects/my-app

session:
  name: my-app-agents
  layout: grid
  attach_on_start: true
  fresh_on_start: false

workspace:
  work_dir: .agent-work
  use_worktrees: false
  worktree_root: ../my-app-agent-worktrees

cli_tools:
  codex:
    command: codex
    detected_path: /home/me/.local/bin/codex
    installed: true
  gemini:
    command: gemini
    detected_path: /home/me/.npm/bin/gemini
    installed: true

agents:
  - id: orchestrator
    display_name: Orchestrator
    role_template: orchestrator
    cli: gemini
    prompt_file: .agentdock/prompts/orchestrator.md
    boot_file: .agentdock/generated/boot-orchestrator.md
    window: command-center
    cwd_mode: project_root
    worktree: false

  - id: backend
    display_name: Backend Engineer
    role_template: backend
    cli: codex
    prompt_file: .agentdock/prompts/backend.md
    boot_file: .agentdock/generated/boot-backend.md
    window: implementation
    cwd_mode: project_root
    worktree: false

orchestration:
  default_recipient: orchestrator
  communication_mode: file_based
  lock_file: .agent-work/LOCKS.md

routing:
  jobs: .agent-work/07_JOBS
  decisions: .agent-work/08_DECISIONS
  handoffs: .agent-work/09_HANDOFFS
  reports: .agent-work/10_REPORTS
  inbox: .agent-work/12_INBOX
  outbox: .agent-work/13_OUTBOX
  shared_context: .agent-work/14_SHARED_CONTEXT
```

## 4. Runtime config

Path:

```txt
.agentdock/config.runtime
```

Purpose: shell-readable generated config for reliable Bash runtime.

Example:

```bash
PROJECT_NAME="my-app"
PROJECT_ROOT="/home/me/projects/my-app"
SESSION_NAME="my-app-agents"
LAYOUT="grid"
ATTACH_ON_START="1"
USE_WORKTREES="0"
WORK_DIR=".agent-work"
WORKTREE_ROOT="../my-app-agent-worktrees"

AGENT_IDS="orchestrator backend"

AGENT_orchestrator_DISPLAY_NAME="Orchestrator"
AGENT_orchestrator_CLI="gemini"
AGENT_orchestrator_CMD="gemini"
AGENT_orchestrator_PROMPT=".agentdock/prompts/orchestrator.md"
AGENT_orchestrator_BOOT=".agentdock/generated/boot-orchestrator.md"
AGENT_orchestrator_WINDOW="command-center"
AGENT_orchestrator_CWD_MODE="project_root"

AGENT_backend_DISPLAY_NAME="Backend Engineer"
AGENT_backend_CLI="codex"
AGENT_backend_CMD="codex"
AGENT_backend_PROMPT=".agentdock/prompts/backend.md"
AGENT_backend_BOOT=".agentdock/generated/boot-backend.md"
AGENT_backend_WINDOW="implementation"
AGENT_backend_CWD_MODE="project_root"
```

## 5. Role id rules

Role ids must be sanitized:

- lowercase;
- `a-z`, `0-9`, `-`, `_` only;
- spaces become `-`;
- maximum 64 characters;
- unique within project.

Display names can be human-readable.

## 6. Session name rules

Default:

```txt
<sanitized-project-name>-agents
```

Sanitization:

- spaces to `-`;
- remove tmux-hostile characters;
- max 80 characters;
- fallback `agentdock-agents`.

## 7. Config update rules

- `agentdock init` creates config.
- Re-running init asks before overwrite.
- `agentdock assign` updates only selected agent CLI.
- `agentdock role add` appends agent entry.
- `agentdock start` may regenerate runtime config and boot files, but must preserve custom prompt files.

## 8. Config validation

Before start:

- `version` exists.
- `project.root` exists.
- `agents` list is non-empty.
- each agent id unique.
- each agent cli exists in adapter registry.
- each assigned CLI binary is installed.
- each boot file can be generated.
