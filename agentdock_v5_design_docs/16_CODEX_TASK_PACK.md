# Codex Task Pack

Copy these tasks into Codex in order. Each task is scoped to produce implementable code.

## Task 001: Create AgentDock repository skeleton

```txt
Implement the AgentDock v5 repository skeleton.

Requirements:
- Create install.sh, VERSION, bin/, bin/lib/, adapters/, kit/ directories.
- Create a global wrapper architecture where install.sh copies files to a prefix.
- Create bin/agentdock-dispatch that routes commands: help, version, doctor, cli, install, init, start, stop, task, report.
- Create bin/lib/common.sh and bin/lib/ui.sh.
- The code must be Bash, set -euo pipefail, and avoid external dependencies beyond Bash/coreutils.
- Add README quickstart.
- Do not implement actual tmux launch yet.

Acceptance:
- ./bin/agentdock-dispatch help works.
- ./bin/agentdock-dispatch version prints VERSION.
```

## Task 002: Implement adapter registry

```txt
Implement AgentDock adapter registry.

Requirements:
- Add adapters/codex.conf, claude.conf, opencode.conf, hermes.conf, gemini.conf.
- Implement bin/lib/adapters.sh.
- Implement functions:
  - adapter_dirs
  - list_adapters
  - load_adapter <id>
  - detect_adapter <id>
  - adapter_version <id>
  - print_adapter_table
- Support custom adapters from ~/.config/agentdock/adapters.
- Detection must run only command -v and version commands, never install commands.

Acceptance:
- agentdock cli list shows installed/missing status.
- Missing commands do not fail the entire command.
```

## Task 003: Implement doctor command

```txt
Implement agentdock doctor.

Requirements:
- Check git, tmux, bash, curl, node, npm.
- Check AI CLI adapters using adapter registry.
- Print clear status table.
- Detect whether current directory has .agentdock/config.yml.
- Use exit code 0 even if optional AI CLIs are missing.
- Use non-zero exit only when required tools are missing.

Acceptance:
- agentdock doctor works outside a project.
- agentdock doctor works inside a project.
```

## Task 004: Implement AI CLI installation command

```txt
Implement agentdock install <cli>.

Requirements:
- Load adapter.
- Show available install methods.
- Accept --method <method>.
- Show exact command before execution.
- Confirm unless --yes is provided.
- Support --dry-run.
- Re-run detection after install command.

Acceptance:
- agentdock install codex --dry-run prints install command and does not execute.
- Unknown adapter fails clearly.
- Unknown method fails clearly.
```

## Task 005: Implement project workspace initialization

```txt
Implement agentdock init.

Requirements:
- Use current directory as project root unless --project is provided.
- Create .agentdock/{prompts,generated,state}.
- Create .agent-work directories: 07_JOBS, 08_DECISIONS, 09_HANDOFFS, 10_REPORTS, 11_ARCHIVE, 12_INBOX, 13_OUTBOX, 14_SHARED_CONTEXT.
- Create .agent-work/LOCKS.md.
- Support non-interactive flags for tests:
  --roles "orchestrator:codex,backend:codex,qa:gemini"
  --layout grid
  --no-worktrees
- Generate .agentdock/config.yml and .agentdock/config.runtime.
- Generate prompt files for roles.
- Do not overwrite existing prompts unless --force.

Acceptance:
- Running init in temp dir creates all expected files.
- Role ids are sanitized.
- Runtime config is shell-sourceable.
```

## Task 006: Implement role add and assign

```txt
Implement:
- agentdock role add
- agentdock assign <role> <cli>
- agentdock team

Requirements:
- role add creates prompt file and appends config/runtime entry.
- assign updates role CLI mapping.
- team prints role to CLI table.
- Regenerate boot prompt after changes.

Acceptance:
- Add a custom role called api-designer and assign to codex.
- team output reflects the change.
```

## Task 007: Implement boot prompt generator

```txt
Implement boot prompt generation.

Requirements:
- For each role, create .agentdock/generated/boot-<role>.md.
- Include role identity, assigned CLI, project root, cwd, prompt path, workspace paths, required reading, communication rules, safety rules, and first action.
- Regenerate on init, assign, role add, and start.

Acceptance:
- Every configured role has a boot file.
- Boot file paths are correct relative to project root.
```

## Task 008: Implement tmux start/stop with fake CLI support

```txt
Implement agentdock start and stop.

Requirements:
- Load .agentdock/config.runtime.
- Validate tmux installed.
- Validate each assigned CLI command exists unless --allow-missing.
- Create tmux session from project name or config.
- Support layouts: grid, windows, hybrid.
- Launch each role command in correct cwd.
- Send instruction to read boot prompt.
- Record pane ids in .agentdock/state/panes.env.
- stop kills only configured session after confirmation unless --yes.

Acceptance:
- Use fake CLI scripts in PATH to test without real AI CLIs.
- tmux panes are created and titled.
```

## Task 009: Implement task and send

```txt
Implement agentdock task and send.

Requirements:
- task creates .agent-work/07_JOBS/JOB-<timestamp>/README.md.
- task updates .agent-work/07_JOBS/CURRENT.md.
- task writes event log.
- If session running, send job path to orchestrator role if available.
- send <role> "message" writes inbox message and sends to pane if running.

Acceptance:
- Job folder appears.
- Message file appears in role inbox.
- tmux pane receives message when session is active.
```

## Task 010: Implement report

```txt
Implement agentdock report.

Requirements:
- Print project name, session status, current job, latest reports, latest decisions, latest handoffs.
- If git repo, show git status summary.
- Support --json minimally.

Acceptance:
- report works with empty workspace.
- report works after task creation.
```

## Task 011: Migrate v4.1 kit assets

```txt
Migrate useful assets from harness_multi_agent_team_kit_v4_1 into AgentDock v5 kit.

Requirements:
- 00_SYSTEM -> kit/00_SYSTEM
- 01_ROLES -> kit/01_ROLE_TEMPLATES
- 02_AGENT_PROMPTS -> kit/02_AGENT_PROMPTS
- 03_WORKFLOWS -> kit/03_WORKFLOWS
- 05_TEMPLATES -> kit/05_TEMPLATES
- 06_CHECKLISTS -> kit/06_CHECKLISTS
- Keep 04_TMUX scripts as reference but do not call start-codex-agents.sh directly.
- Add migration README.

Acceptance:
- AgentDock install includes migrated kit docs.
- v4.1 project-copy installer is not used by v5 runtime.
```

## Task 012: Add tests and release smoke script

```txt
Create a test/smoke.sh script.

Requirements:
- Use temp directory.
- Use fake AI CLI binaries.
- Run install into temp prefix.
- Run doctor.
- Run cli list.
- Run init with non-interactive roles.
- Run start --no-attach.
- Verify tmux session.
- Run task.
- Run report.
- Run stop --yes.

Acceptance:
- test/smoke.sh exits 0 on a machine with tmux and git.
```
