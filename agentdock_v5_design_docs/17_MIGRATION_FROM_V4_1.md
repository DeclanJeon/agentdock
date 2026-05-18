# Migration from harness_multi_agent_team_kit_v4_1 to AgentDock v5

## 1. Current v4.1 model

The uploaded v4.1 kit is project-installed:

```txt
<project>/.agent-system/
<project>/.agent-work/
```

It launches Codex-only agents with:

```bash
.agent-system/04_TMUX/start-codex-agents.sh
```

v4.1 assumes:

- the kit is copied into each project;
- Codex command is the runtime;
- role windows are mostly fixed;
- project root may be inferred from `.agent-system` location.

## 2. Required v5 model

AgentDock v5 is globally installed:

```txt
~/.local/bin/agentdock
~/.local/share/agentdock/kit
```

Each project receives only:

```txt
<project>/.agentdock/
<project>/.agent-work/
```

v5 must assume:

- current directory is project root;
- roles are user-defined;
- CLIs are user-selected;
- CLI installation is optional and explicit;
- tmux runtime is generated from project config.

## 3. Asset mapping

| v4.1 Path | v5 Destination | Notes |
|---|---|---|
| `00_SYSTEM/` | `kit/00_SYSTEM/` | Keep most files |
| `01_ROLES/` | `kit/01_ROLE_TEMPLATES/` | Convert fixed roles into templates |
| `02_AGENT_PROMPTS/` | `kit/02_AGENT_PROMPTS/` | Use as default prompt templates |
| `03_WORKFLOWS/` | `kit/03_WORKFLOWS/` | Keep workflows |
| `04_TMUX/` | `kit/04_TMUX/legacy/` or reference | Rewrite start runtime, do not reuse as-is |
| `05_TEMPLATES/` | `kit/05_TEMPLATES/` | Keep templates |
| `06_CHECKLISTS/` | `kit/06_CHECKLISTS/` | Keep checklists |
| `06_PROJECT_BOARD/` | optional project template | Could become `.agent-work/PROJECT_BOARD` later |
| `07_JOBS/` | project `.agent-work/07_JOBS/` | Runtime only |
| `08_DECISIONS/` | project `.agent-work/08_DECISIONS/` | Runtime only |
| `09_HANDOFFS/` | project `.agent-work/09_HANDOFFS/` | Runtime only |
| `10_REPORTS/` | project `.agent-work/10_REPORTS/` | Runtime only |
| `11_ARCHIVE/` | project `.agent-work/11_ARCHIVE/` | Runtime only |
| `install-agent-system.sh` | legacy only | Replace with global installer |

## 4. Rewrite `start-codex-agents.sh`

Do not patch it lightly. Create new v5 runtime:

```txt
bin/agentdock-start
bin/lib/tmux.sh
```

Key changes:

- `CODEX_CMD` becomes per-role `AGENT_<role>_CMD`.
- Fixed agent list becomes config-driven `AGENT_IDS`.
- Project root comes from current dir or `--project`, not script location.
- Boot prompt is generated as file, not built as giant string.
- `AGENT_SYSTEM_DIR` becomes global `AGENTDOCK_HOME/kit`.
- Project prompts come from `.agentdock/prompts`.
- Runtime workspace remains `.agent-work`.

## 5. Preserve v4.1 strengths

Keep these design ideas:

- agents coordinate through files;
- role boundaries matter;
- task lifecycle and quality gates are explicit;
- worktrees are optional isolation;
- tmux layouts support hybrid/grid/windows;
- architecture-to-development handoff documents are valuable;
- reports and decisions should be durable.

## 6. Remove v4.1 limitations

Remove these assumptions:

- Codex-only runtime;
- fixed roles;
- project-local copied `.agent-system`;
- start script living inside project;
- project root inferred from `.agent-system`;
- one boot prompt shape for every CLI.

## 7. Migration implementation checklist

- [ ] Create global install tree.
- [ ] Copy reusable kit docs into `kit/`.
- [ ] Create adapter registry.
- [ ] Create project `.agentdock` config generator.
- [ ] Create dynamic prompt generator.
- [ ] Create config-driven tmux launcher.
- [ ] Create task/report commands.
- [ ] Add smoke tests using fake CLI.
- [ ] Mark v4.1 scripts as legacy reference.
