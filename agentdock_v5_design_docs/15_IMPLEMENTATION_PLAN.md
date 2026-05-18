# Implementation Plan

## 1. Recommended implementation strategy

Implement v5 in Bash first, using the existing v4.1 kit as the asset base. The goal is to ship a working global CLI, not a perfect framework.

## 2. Milestone 0: repo setup

Create repository structure:

```txt
agentdock/
├─ install.sh
├─ VERSION
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
│     ├─ ui.sh
│     ├─ adapters.sh
│     ├─ project.sh
│     ├─ config.sh
│     ├─ prompts.sh
│     └─ tmux.sh
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

## 3. Milestone 1: global installer

Implement:

- `install.sh`
- `VERSION`
- wrapper `~/.local/bin/agentdock`
- copy `bin`, `adapters`, `kit`
- PATH guidance
- `agentdock version`
- `agentdock help`

Acceptance:

```bash
./install.sh --prefix /tmp/agentdock-test
/tmp/agentdock-test/bin/agentdock version
```

## 4. Milestone 2: adapter registry and doctor

Implement:

- adapter file format;
- load built-in adapters;
- load user custom adapters;
- detect command path;
- version command;
- `agentdock doctor`;
- `agentdock cli list`.

Acceptance:

- installed commands show path;
- missing commands show missing;
- no install commands run.

## 5. Milestone 3: installer for AI CLIs

Implement:

- `agentdock install <cli>`;
- method selection;
- command preview;
- confirmation;
- post-install detection.

Acceptance:

- dry run mode prints command;
- user can cancel;
- missing method fails clearly.

## 6. Milestone 4: project init

Implement:

- project root detection;
- create `.agentdock`;
- create `.agent-work`;
- role prompt generation;
- custom roles;
- CLI assignment;
- layout selection;
- write `config.yml`;
- write `config.runtime`.

Acceptance:

- init produces valid project files;
- re-init does not overwrite prompts silently.

## 7. Milestone 5: prompt generator

Implement:

- `generate_boot_prompt(role)`;
- boot files include role, CLI, paths, routing rules;
- `agentdock assign` regenerates boot prompt.

Acceptance:

- every configured role has a boot prompt;
- boot prompt points to correct role prompt and workspace paths.

## 8. Milestone 6: tmux runtime

Implement:

- `agentdock start`;
- session naming;
- `hybrid`, `grid`, `windows` layouts;
- per-role CLI launch;
- pane titles;
- boot prompt instruction;
- `panes.env`;
- `agentdock stop`.

Acceptance:

- fake CLI starts in panes;
- assigned CLI per role is honored;
- start does not use global kit path as project root.

## 9. Milestone 7: task and report

Implement:

- `agentdock task`;
- job folder generation;
- `CURRENT.md`;
- dispatch to orchestrator;
- `agentdock report`.

Acceptance:

- job file appears;
- running session receives task;
- report summarizes state.

## 10. Milestone 8: migration assets

Transform v4.1 assets:

- copy `00_SYSTEM` to `kit/00_SYSTEM`;
- copy role docs into `kit/01_ROLE_TEMPLATES`;
- copy prompts into `kit/02_AGENT_PROMPTS`;
- copy workflows into `kit/03_WORKFLOWS`;
- keep useful tmux helper scripts under `kit/04_TMUX`;
- copy templates/checklists.

Do not copy v4.1 `install-agent-system.sh` as active installer. Keep it only as legacy reference.

## 11. Implementation order for Codex

Give Codex the tasks in `16_CODEX_TASK_PACK.md` one at a time. Start with the skeleton and tests using fake CLIs. Do not begin with real Codex/Claude integration.
