# SDD: Software Design Document

## 1. Design overview

AgentDock is implemented as a command dispatcher plus a set of subcommand scripts. It separates:

- global installation;
- adapter definitions;
- project initialization;
- prompt generation;
- tmux runtime;
- task/report file operations.

The design keeps the MVP Bash-friendly while allowing a future TypeScript implementation.

## 2. Component diagram

```txt
agentdock executable
    |
    +-- command dispatcher
        |
        +-- doctor
        +-- cli list/add
        +-- install
        +-- init
        +-- role add
        +-- assign
        +-- start
        +-- stop
        +-- task
        +-- report

Global data: ~/.local/share/agentdock
    |
    +-- bin subcommands
    +-- adapters/*.conf or *.yml
    +-- kit role templates
    +-- kit system prompts
    +-- kit workflow docs

Project data: <project>/.agentdock
    |
    +-- config.yml
    +-- prompts/*.md
    +-- generated/boot-*.md
    +-- state/*.log

Shared work: <project>/.agent-work
    |
    +-- jobs, decisions, handoffs, reports, inbox, outbox, shared context
```

## 3. Directory design

### 3.1 Global install tree

```txt
~/.local/share/agentdock/
├─ bin/
│  ├─ agentdock-dispatch
│  ├─ agentdock-doctor
│  ├─ agentdock-cli-list
│  ├─ agentdock-cli-add
│  ├─ agentdock-install
│  ├─ agentdock-init
│  ├─ agentdock-role-add
│  ├─ agentdock-assign
│  ├─ agentdock-start
│  ├─ agentdock-stop
│  ├─ agentdock-task
│  ├─ agentdock-report
│  └─ lib/
│     ├─ common.sh
│     ├─ adapters.sh
│     ├─ config.sh
│     ├─ prompts.sh
│     ├─ tmux.sh
│     └─ ui.sh
├─ adapters/
│  ├─ codex.conf
│  ├─ claude.conf
│  ├─ opencode.conf
│  ├─ hermes.conf
│  └─ gemini.conf
└─ kit/
   ├─ 00_SYSTEM/
   ├─ 01_ROLE_TEMPLATES/
   ├─ 02_AGENT_PROMPTS/
   ├─ 03_WORKFLOWS/
   ├─ 04_TMUX/
   ├─ 05_TEMPLATES/
   └─ 06_CHECKLISTS/
```

### 3.2 User config tree

```txt
~/.config/agentdock/
├─ global.conf
├─ adapters/
│  └─ custom-example.conf
└─ role-templates/
   └─ my-role.md
```

### 3.3 Project tree

```txt
<project>/.agentdock/
├─ config.yml
├─ prompts/
├─ generated/
└─ state/

<project>/.agent-work/
├─ 07_JOBS/
├─ 08_DECISIONS/
├─ 09_HANDOFFS/
├─ 10_REPORTS/
├─ 11_ARCHIVE/
├─ 12_INBOX/
├─ 13_OUTBOX/
├─ 14_SHARED_CONTEXT/
└─ LOCKS.md
```

## 4. Adapter design

Bash MVP should prefer `.conf` adapter files because they can be sourced safely after validation.

Example:

```bash
ADAPTER_ID="codex"
ADAPTER_DISPLAY_NAME="OpenAI Codex CLI"
ADAPTER_BINARIES="codex"
ADAPTER_DETECT_CMD="command -v codex"
ADAPTER_VERSION_CMD="codex --version"
ADAPTER_INSTALL_METHODS="npm brew"
ADAPTER_INSTALL_NPM="npm i -g @openai/codex"
ADAPTER_INSTALL_BREW="brew install --cask codex"
ADAPTER_RUN_CMD="codex"
```

Do not execute adapter-defined commands without user action except detection/version commands.

## 5. Project config parsing

MVP options:

1. Use simple generated `.agentdock/config.env` for runtime and keep `config.yml` as human-readable output.
2. Implement a minimal parser for the limited YAML shape.
3. Use Python stdlib-free parsing with careful assumptions.

Recommended MVP: generate both:

```txt
.agentdock/config.yml       # human-readable canonical config
.agentdock/config.runtime   # shell-readable generated runtime config
```

`config.runtime` example:

```bash
PROJECT_NAME="my-app"
SESSION_NAME="my-app-agents"
LAYOUT="grid"
AGENT_IDS="orchestrator backend frontend qa"
AGENT_orchestrator_NAME="Orchestrator"
AGENT_orchestrator_CLI="gemini"
AGENT_orchestrator_CMD="gemini"
AGENT_orchestrator_PROMPT=".agentdock/prompts/orchestrator.md"
AGENT_orchestrator_BOOT=".agentdock/generated/boot-orchestrator.md"
```

This avoids fragile YAML parsing during tmux launch.

## 6. Command dispatcher

`~/.local/bin/agentdock` should be a small wrapper:

```bash
#!/usr/bin/env bash
set -euo pipefail
AGENTDOCK_HOME="${AGENTDOCK_HOME:-$HOME/.local/share/agentdock}"
exec "$AGENTDOCK_HOME/bin/agentdock-dispatch" "$@"
```

Dispatcher resolves subcommands and current project directory.

## 7. Interactive prompting

Bash implementation can use simple `read -r` prompts:

- yes/no confirmation;
- numbered menus;
- comma-separated multi-select;
- free text role names.

Do not require `gum`, `fzf`, or `dialog` in MVP. They can be optional enhancers later.

## 8. Prompt generation algorithm

For every configured agent:

1. Determine role id and display name.
2. Determine assigned CLI adapter and run command.
3. Locate project-local prompt file.
4. If missing, copy from selected global template or create minimal custom prompt.
5. Generate `.agentdock/generated/boot-<role>.md`.
6. Generate/update runtime config.

## 9. tmux launch algorithm

1. Load runtime config.
2. Validate `tmux` exists.
3. Validate assigned CLIs exist.
4. Create session name.
5. If session exists:
   - attach by default;
   - or recreate if `--fresh` confirmed.
6. Create windows/panes by layout.
7. For each agent:
   - set pane title;
   - `cd` into cwd;
   - launch assigned CLI command;
   - send instruction to read boot file.
8. Attach unless `--no-attach`.

## 10. Worktree algorithm

If `use_worktrees=true`:

1. Verify project is inside a git repo.
2. Create root: `../<project>-agent-worktrees`.
3. For each role with `worktree=true`, create branch `agent/<role>/workspace`.
4. Symlink `.agentdock` and `.agent-work` from project root into worktree.
5. Use worktree path as agent cwd.

If worktree creation fails, fall back to project root and warn.

## 11. Error handling

- Missing `.agentdock/config.runtime`: tell user to run `agentdock init`.
- Missing assigned CLI: tell user to run `agentdock install <cli>` or `agentdock assign <role> <cli>`.
- Existing tmux session: attach or require `--fresh`.
- Invalid role id: show available roles.
- Missing tmux: stop immediately with install guidance.

## 12. Future TypeScript migration

Keep command behavior stable. A future TS implementation can replace Bash internals while preserving:

- command names;
- config shape;
- adapter shape;
- project directory layout;
- generated prompts;
- tmux behavior.
