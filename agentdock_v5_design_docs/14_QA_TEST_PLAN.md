# QA Test Plan

## 1. Test goals

Verify AgentDock can be installed globally, initialized inside a project, detect AI CLIs, create custom role-to-CLI mappings, generate prompts, launch tmux sessions, and manage file-based jobs without corrupting user files.

## 2. Test environments

MVP target:

- Ubuntu Linux
- macOS
- WSL2 Ubuntu

Recommended local test matrix:

| Environment | Required |
|---|---|
| Ubuntu + tmux + git | yes |
| macOS + tmux + git | yes |
| WSL2 + tmux + git | yes |
| No AI CLIs installed | yes |
| Some AI CLIs installed | yes |
| No git repo project | yes |
| Git repo project | yes |

## 3. Unit-level shell tests

Test helper functions:

- sanitize role id;
- sanitize session name;
- detect command path;
- load adapter;
- validate adapter fields;
- generate config.runtime;
- generate boot prompt;
- create workspace dirs;
- create job id.

## 4. Integration tests

### IT-001 Install

1. Run installer into temp prefix.
2. Verify executable exists.
3. Verify global data tree exists.
4. Run `agentdock version`.

Expected: success.

### IT-002 Doctor with no AI CLIs

1. Use clean PATH with only required tools.
2. Run `agentdock doctor`.

Expected: system tools detected, AI CLIs missing.

### IT-003 Custom fake CLI detection

1. Create fake executable `fakecodex` in temp PATH.
2. Add custom adapter.
3. Run `agentdock cli list`.

Expected: fake adapter installed.

### IT-004 Init custom team

1. Create temp project.
2. Run `agentdock init` with scripted answers.
3. Choose 3 roles.
4. Assign fake CLIs.

Expected:

- `.agentdock/config.yml` exists;
- `.agentdock/config.runtime` exists;
- `.agentdock/prompts/*.md` exists;
- `.agentdock/generated/boot-*.md` exists;
- `.agent-work` dirs exist.

### IT-005 Start tmux with fake CLI

1. Fake CLI command sleeps or echoes input.
2. Run `agentdock start --no-attach`.
3. Verify tmux session exists.
4. Verify panes exist.
5. Verify pane titles.
6. Verify `panes.env` written.

### IT-006 Task creation

1. Run `agentdock task "Test task"`.
2. Verify job folder.
3. Verify CURRENT.md.
4. Verify event log.

### IT-007 Stop

1. Start session.
2. Run `agentdock stop --yes`.
3. Verify session removed.

## 5. Manual acceptance tests

### MAT-001 Real Codex role

- Install Codex manually.
- Initialize project with one role assigned to Codex.
- Start AgentDock.
- Verify Codex opens and receives boot prompt instruction.

### MAT-002 Mixed CLIs

- Configure at least two real CLIs.
- Assign roles differently.
- Start session.
- Verify each pane runs assigned CLI.

### MAT-003 Re-init protection

- Modify `.agentdock/prompts/backend.md`.
- Rerun `agentdock init`.
- Verify prompt is not overwritten without confirmation.

## 6. Regression checklist

Before release:

- `agentdock doctor` works outside project.
- `agentdock doctor` works inside project.
- `agentdock init` does not require AI CLI installed.
- Missing assigned CLI blocks `start` with clear message.
- `agentdock assign` changes mapping and regenerates boot prompt.
- `agentdock start --fresh` confirms before killing session.
- `agentdock stop` does not delete `.agent-work`.
- `agentdock uninstall` does not delete project data.

## 7. Definition of done

A release is done when:

- all required commands work in a temp environment;
- fake CLI integration tests pass;
- at least one real AI CLI manual smoke test passes;
- README install and quickstart are accurate;
- migration notes from v4.1 are included.
