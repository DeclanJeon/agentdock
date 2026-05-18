# System Architecture

## 1. Architecture style

AgentDock uses a local, file-system-centered orchestration architecture.

```txt
User terminal
   |
   v
agentdock global CLI
   |
   +--> detects system dependencies
   +--> detects AI CLI adapters
   +--> generates project config/prompts
   +--> launches tmux runtime
              |
              +--> pane 1: selected CLI + role boot prompt
              +--> pane 2: selected CLI + role boot prompt
              +--> pane N: selected CLI + role boot prompt

Shared source of truth:
<project>/.agent-work
```

## 2. Layered architecture

### Layer 1: Global installation layer

Responsible for installing and updating AgentDock itself.

Contents:

- executable wrapper;
- subcommand scripts;
- default adapter definitions;
- default role templates;
- default workflow docs;
- default system rules.

### Layer 2: Project configuration layer

Responsible for project-specific team setup.

Contents:

- chosen roles;
- selected CLI per role;
- layout;
- project root;
- worktree settings;
- prompt overrides;
- generated boot prompts.

### Layer 3: Runtime orchestration layer

Responsible for starting and controlling tmux sessions.

Contents:

- session creation;
- window/pane layout;
- CLI process launch;
- boot prompt dispatch;
- task dispatch;
- stop/restart behavior.

### Layer 4: Agent coordination layer

Responsible for persistent communication between independent agent sessions.

Contents:

- jobs;
- task cards;
- inbox/outbox;
- decisions;
- handoffs;
- reports;
- shared context;
- locks.

## 3. Data flow: init

```txt
agentdock init
   |
   +--> detect project root
   +--> detect system tools
   +--> detect AI CLIs
   +--> optionally install missing CLIs
   +--> ask role setup questions
   +--> ask CLI assignment questions
   +--> create .agentdock/config.yml
   +--> create .agentdock/config.runtime
   +--> create .agentdock/prompts/*.md
   +--> create .agentdock/generated/boot-*.md
   +--> create .agent-work directories
```

## 4. Data flow: start

```txt
agentdock start
   |
   +--> load .agentdock/config.runtime
   +--> validate tmux and assigned CLIs
   +--> create tmux session
   +--> create layout
   +--> for each agent:
         +--> resolve cwd
         +--> launch CLI
         +--> send boot prompt read instruction
   +--> attach to session
```

## 5. Data flow: task

```txt
agentdock task "Fix login bug"
   |
   +--> create job id
   +--> create .agent-work/07_JOBS/JOB-<timestamp>/README.md
   +--> update .agent-work/07_JOBS/CURRENT.md
   +--> append event log
   +--> if tmux running:
         +--> send job path to orchestrator role
```

## 6. Component responsibilities

| Component | Responsibility |
|---|---|
| Dispatcher | Route `agentdock <command>` to subcommand script |
| Doctor | Detect dependencies and AI CLIs |
| Adapter registry | Load built-in and user adapters |
| Installer | Run user-approved third-party CLI install commands |
| Init wizard | Build roles and CLI mappings |
| Config writer | Write `config.yml` and `config.runtime` |
| Prompt generator | Generate role boot prompts |
| Tmux runtime | Create windows/panes and launch CLIs |
| Task manager | Create jobs and dispatch tasks |
| Report collector | Summarize `.agent-work` state |

## 7. Runtime boundaries

AgentDock controls only:

- files under AgentDock global directories;
- files under project `.agentdock` and `.agent-work`;
- tmux sessions it creates;
- optional git worktrees it creates;
- CLI install commands approved by user.

AI CLIs control their own authentication and model behavior.

## 8. Failure isolation

- Missing optional CLI does not break the entire app unless a configured role requires it.
- Failed install does not corrupt project config.
- Failed tmux launch leaves config intact.
- Failed worktree creation falls back to project root with warning.
- Invalid custom adapter is ignored with warning unless explicitly selected.

## 9. Extensibility points

- Add adapter file for new CLI.
- Add role template file.
- Add layout strategy.
- Add report renderer.
- Add project stack detector.
- Add future web dashboard without changing core `.agent-work` protocol.
