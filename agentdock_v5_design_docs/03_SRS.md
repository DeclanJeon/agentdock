# SRS: Software Requirements Specification

Requirement IDs are stable references for implementation and testing.

## 1. Functional requirements

### FR-001 Global command

AgentDock shall install an executable named `agentdock` into a user-accessible PATH directory.

### FR-002 Global data directory

AgentDock shall install default kit files, role templates, workflow templates, and adapter definitions under `~/.local/share/agentdock` by default.

### FR-003 Global config directory

AgentDock shall create `~/.config/agentdock` for user-level settings and custom adapters.

### FR-004 Project root detection

For project commands, AgentDock shall use the current working directory as the project root unless `--project <path>` is provided.

### FR-005 Doctor command

`agentdock doctor` shall detect required system dependencies and supported AI CLI tools.

### FR-006 CLI list command

`agentdock cli list` shall show each known adapter, installed status, detected path, and version if available.

### FR-007 Missing CLI display

AgentDock shall explicitly mark a supported CLI as missing when its binary is not detected.

### FR-008 CLI install command

`agentdock install <cli>` shall install the selected CLI using an adapter-defined method only after explicit confirmation.

### FR-009 Install method selection

If an adapter has multiple install methods, `agentdock install <cli> --method <method>` shall use that method. Without `--method`, AgentDock shall prompt the user.

### FR-010 Custom adapter creation

`agentdock cli add` shall create a custom adapter definition under `~/.config/agentdock/adapters`.

### FR-011 Init command

`agentdock init` shall initialize the current project by creating `.agentdock` and `.agent-work` if they do not exist.

### FR-012 Project config generation

`agentdock init` shall generate `.agentdock/config.yml`.

### FR-013 Role customization

`agentdock init` shall allow users to define arbitrary role names, select role templates, or create custom roles.

### FR-014 Role-to-CLI assignment

`agentdock init` shall allow each role to be assigned to any installed or configured CLI adapter.

### FR-015 Role add command

`agentdock role add` shall add a project-local role prompt file and config entry.

### FR-016 Assign command

`agentdock assign <role> <cli>` shall update `.agentdock/config.yml` to map the selected role to the selected CLI.

### FR-017 Prompt generation

AgentDock shall generate boot prompt files under `.agentdock/generated` for every configured role.

### FR-018 Prompt override

AgentDock shall use project-local prompt files in `.agentdock/prompts` when present, falling back to global templates otherwise.

### FR-019 Start command

`agentdock start` shall launch a tmux session using `.agentdock/config.yml`.

### FR-020 Layout modes

AgentDock shall support `hybrid`, `grid`, and `windows` layout modes.

### FR-021 tmux session naming

Default session name shall be `<project-name>-agents`, sanitized for tmux.

### FR-022 Fresh mode

`agentdock start --fresh` shall kill and recreate the existing session only after explicit confirmation unless `--yes` is provided.

### FR-023 CLI launch per role

For each configured role, AgentDock shall launch the role's assigned CLI command in its pane/window.

### FR-024 Boot prompt delivery

For each configured role, AgentDock shall send an instruction to read the generated boot prompt file.

### FR-025 Stop command

`agentdock stop` shall stop the configured tmux session after confirmation.

### FR-026 Task command

`agentdock task "<text>"` shall create a timestamped job folder under `.agent-work/07_JOBS` and update `.agent-work/07_JOBS/CURRENT.md`.

### FR-027 Task dispatch

If tmux session is running, `agentdock task` shall send the job path to the orchestrator role if configured, otherwise to all roles.

### FR-028 Report command

`agentdock report` shall summarize latest reports, handoffs, decisions, current job, and tmux session status.

### FR-029 Worktree support

If enabled, AgentDock shall create or reuse role-specific git worktrees and symlink `.agentdock` and `.agent-work` into each worktree.

### FR-030 No silent overwrite

AgentDock shall not overwrite existing project-local prompts or config without confirmation.

## 2. Non-functional requirements

### NFR-001 Portability

MVP shall work on Linux, macOS, and WSL2.

### NFR-002 Minimal dependencies

MVP shall require only Bash, tmux, git, and common coreutils.

### NFR-003 Inspectability

Generated prompts, configs, adapters, and task files shall be human-readable text.

### NFR-004 Recoverability

If a command fails midway, rerunning it should not corrupt existing project setup.

### NFR-005 Vendor neutrality

AgentDock shall not prefer one AI CLI in data model or command naming.

### NFR-006 Security

AgentDock shall never install third-party CLIs without explicit user consent.

### NFR-007 Extensibility

New AI CLIs shall be addable through adapter files without changing core runtime logic.

## 3. Interface requirements

### IR-001 CLI output

All commands shall print clear, plain terminal output with status markers:

```txt
✓ installed
✗ missing
! warning
→ next action
```

### IR-002 Exit codes

- `0`: success
- `1`: user-facing failure
- `2`: invalid arguments
- `3`: missing dependency
- `4`: project not initialized
- `5`: adapter error

### IR-003 Config format

Project config shall use YAML-like syntax in MVP. If robust YAML parsing is unavailable, restrict supported YAML to simple key/value and list structures or use generated shell-readable config files internally.

## 4. Data requirements

### DR-001 Global adapter files

Adapter files must define:

- id;
- display name;
- binary names;
- detection command;
- version command;
- install methods;
- run command.

### DR-002 Project agent entries

Each agent entry must define:

- id;
- display name;
- role template or custom prompt;
- assigned CLI;
- prompt file;
- generated boot file;
- window/pane group;
- cwd mode.

### DR-003 State logs

Project state logs shall be append-only text files when possible.

## 5. Constraints

- Bash arrays and string escaping must be handled carefully.
- tmux command target names must be sanitized.
- AI CLI interactive behavior varies; AgentDock must not assume all CLIs accept identical flags.
- Some CLIs may require login before first use. AgentDock can detect command presence but may not be able to verify authentication reliably.
