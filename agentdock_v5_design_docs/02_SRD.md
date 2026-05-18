# SRD: System Requirements Document

## 1. System context

AgentDock runs entirely on the user's local machine. It uses:

- a globally installed CLI executable;
- a global data directory with default kit files and adapters;
- a global config directory with user overrides;
- project-local `.agentdock` configuration;
- project-local `.agent-work` shared agent workspace;
- tmux as the process/session runtime;
- installed third-party AI CLI tools as agent backends.

## 2. Deployment model

### 2.1 Global install paths

Default user-level installation:

```txt
~/.local/bin/agentdock
~/.local/share/agentdock/
~/.config/agentdock/
```

System-level installation may be added later:

```txt
/usr/local/bin/agentdock
/usr/local/share/agentdock/
/etc/agentdock/
```

MVP must default to user-level installation to avoid requiring sudo.

### 2.2 Project-local paths

Inside each initialized project:

```txt
<project>/
├─ .agentdock/
│  ├─ config.yml
│  ├─ prompts/
│  ├─ generated/
│  └─ state/
└─ .agent-work/
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

## 3. System dependencies

### Required

- POSIX shell or Bash
- `tmux`
- `git`
- coreutils: `mkdir`, `cp`, `mv`, `rm`, `cat`, `grep`, `sed`, `awk`, `printf`, `date`

### Recommended

- `node` and `npm` for npm-based CLI installation
- `curl` for installer and script-based third-party installations
- `brew`, `apt`, `dnf`, or `pacman` for package-manager assisted installation

### Optional

- `python3` for YAML parsing fallback or richer report rendering
- `yq` if available, but AgentDock must not require it in MVP

## 4. Supported platforms

MVP:

- Linux
- macOS
- WSL2

Later:

- Windows PowerShell native
- Docker/devcontainer

## 5. Supported AI CLIs

Built-in adapter targets:

- Codex CLI
- Claude Code
- OpenCode
- Hermes Agent
- Gemini CLI
- Custom command adapter

AgentDock must not assume that all tools are installed.

## 6. System capabilities

### 6.1 Global CLI runtime

The `agentdock` command must:

- dispatch subcommands;
- know global data/config locations;
- treat current directory as project root for project commands;
- fail gracefully when required tools are missing;
- keep output readable and actionable.

### 6.2 CLI detection

AgentDock must:

- check adapter definitions;
- run `command -v <binary>` for each binary name;
- attempt version command when available;
- store detected path in runtime state or project config;
- display detected/missing status.

### 6.3 Optional installation

AgentDock must:

- provide install methods per adapter;
- ask for confirmation before installing;
- show the exact command;
- support `--method` when multiple install methods exist;
- verify detection after installation.

### 6.4 Project initialization

AgentDock must:

- create `.agentdock` and `.agent-work`;
- generate `config.yml`;
- generate role prompt files;
- generate boot prompt files;
- preserve user-edited prompt files unless overwrite is confirmed;
- support custom role names and role templates;
- support role-to-CLI assignment.

### 6.5 Runtime launching

AgentDock must:

- read `.agentdock/config.yml`;
- regenerate boot files if config changed;
- create tmux session;
- create windows/panes according to layout;
- launch each configured CLI in the correct cwd;
- send instruction to read the generated boot prompt;
- attach to tmux unless `--no-attach` is provided.

### 6.6 File-based coordination

AgentDock must create and preserve the shared workspace directories. Agents are instructed to coordinate through files:

- jobs;
- task cards;
- decisions;
- handoffs;
- reports;
- inbox/outbox;
- shared context;
- locks.

## 7. Performance requirements

- `agentdock doctor` should finish within 5 seconds on a normal machine, excluding slow version checks.
- `agentdock init` should complete within 30 seconds unless user interaction takes longer.
- `agentdock start` should create tmux layout within 10 seconds before AI CLIs finish loading.

## 8. Reliability requirements

- Project-local files must not be deleted during init unless user confirms.
- Existing tmux session must not be killed unless `--fresh` or confirmation is provided.
- If one CLI is missing, AgentDock should still launch agents assigned to available CLIs or fail with a clear message.
- If tmux is missing, runtime commands must fail with install guidance.

## 9. Security requirements

- Third-party CLI installation is explicit opt-in.
- Install commands are displayed before execution.
- AgentDock does not store API keys directly.
- AgentDock does not edit shell profile without confirmation.
- AgentDock does not run commands outside project root except installation, global config, and optional worktree creation.

## 10. Observability requirements

AgentDock should write local logs:

```txt
.agentdock/state/events.log
.agentdock/state/last-start.log
.agentdock/state/doctor.log
```

Logs must not include secrets by default.
