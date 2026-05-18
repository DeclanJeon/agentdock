# CLI Command Specification

## 1. Global usage

```bash
agentdock <command> [options]
```

## 2. Commands

### 2.1 `agentdock help`

Print command list.

```bash
agentdock help
agentdock --help
```

### 2.2 `agentdock doctor`

Detect system requirements and known AI CLIs.

Options:

```bash
agentdock doctor
agentdock doctor --json
agentdock doctor --project /path/to/project
```

Output example:

```txt
AgentDock Doctor

System:
✓ git      /usr/bin/git
✓ tmux     /usr/bin/tmux
✓ bash     /usr/bin/bash
✓ node     /usr/bin/node
✓ npm      /usr/bin/npm

AI CLIs:
✓ codex     installed    /home/me/.local/bin/codex    0.0.x
✗ claude    missing
✓ opencode  installed    /home/me/.local/bin/opencode
✗ hermes    missing
✓ gemini    installed    /home/me/.npm/bin/gemini

Project:
! not initialized. Run: agentdock init
```

### 2.3 `agentdock cli list`

List adapter registry.

```bash
agentdock cli list
agentdock cli list --json
```

### 2.4 `agentdock cli add`

Create custom adapter interactively.

```bash
agentdock cli add
agentdock cli add --id aider --command aider --install "pipx install aider-chat"
```

### 2.5 `agentdock install <cli>`

Install a supported or custom CLI after confirmation.

```bash
agentdock install codex
agentdock install opencode --method npm
agentdock install hermes --method script
agentdock install gemini --yes
```

Rules:

- Show exact command.
- Ask confirmation unless `--yes` is supplied.
- Verify installation after command finishes.
- Never install all missing CLIs automatically.

### 2.6 `agentdock init`

Initialize current project.

```bash
agentdock init
agentdock init --preset core-4
agentdock init --custom
agentdock init --project /path/to/project
agentdock init --force
```

Interactive flow:

1. Show project path.
2. Run CLI detection.
3. Offer installation for missing CLIs.
4. Ask setup mode: preset/custom/import.
5. Ask worker count or role list.
6. Ask role templates.
7. Ask CLI assignment per role.
8. Ask layout.
9. Ask worktree usage.
10. Generate files.

### 2.7 `agentdock role add`

Add role to current project.

```bash
agentdock role add
agentdock role add api-designer --template custom --cli codex
```

### 2.8 `agentdock assign <role> <cli>`

Assign or reassign a role to a CLI.

```bash
agentdock assign backend codex
agentdock assign qa gemini
```

Rules:

- Validate role exists.
- Validate adapter exists.
- Warn if CLI is not installed.
- Update config and regenerate boot file.

### 2.9 `agentdock team`

Display current project team.

```bash
agentdock team
```

Output example:

```txt
AgentDock Team: my-app

Role                  CLI        Status
orchestrator          gemini     installed
backend-engineer      codex      installed
frontend-engineer     opencode   installed
qa-reviewer           codex      installed
```

### 2.10 `agentdock start`

Launch tmux runtime.

```bash
agentdock start
agentdock start --layout grid
agentdock start --fresh
agentdock start --no-attach
agentdock start --no-worktrees
```

Rules:

- Requires initialized project.
- Validates all assigned CLIs.
- Existing session attaches by default.
- `--fresh` recreates session after confirmation.

### 2.11 `agentdock stop`

Stop project tmux session.

```bash
agentdock stop
agentdock stop --yes
```

### 2.12 `agentdock task "..."`

Create and dispatch a job.

```bash
agentdock task "Fix payment webhook and add tests"
agentdock task --file ./brief.md
agentdock task --to qa "Run release gate"
```

Job folder:

```txt
.agent-work/07_JOBS/JOB-YYMMDDHHMMSS/
├─ README.md
├─ TASKS/
├─ LOGS/
├─ REPORTS/
└─ HANDOFFS/
```

### 2.13 `agentdock send <role> "..."`

Send a message to a running role pane and write it to inbox.

```bash
agentdock send backend "Review the current job and inspect API routes."
```

### 2.14 `agentdock report`

Collect summary.

```bash
agentdock report
agentdock report --latest
agentdock report --json
```

Output includes:

- project;
- session status;
- current job;
- latest reports;
- latest decisions;
- latest handoffs;
- changed files if git repo.

### 2.15 `agentdock update`

Update global AgentDock kit.

```bash
agentdock update
```

MVP can print manual update instructions if update hosting is not implemented.

### 2.16 `agentdock uninstall`

Remove global installation after confirmation.

```bash
agentdock uninstall
```

Must not delete project `.agentdock` or `.agent-work` unless explicitly requested.

## 3. Exit codes

| Code | Meaning |
|---:|---|
| 0 | Success |
| 1 | General failure |
| 2 | Invalid arguments |
| 3 | Missing dependency |
| 4 | Project not initialized |
| 5 | Adapter failure |
| 6 | User cancelled |

## 4. Global options

```bash
--project <path>   Override current directory as project root
--yes              Skip confirmations for safe scripted operations
--json             Machine-readable output where supported
--verbose          Print debug logs
--quiet            Reduce output
```
