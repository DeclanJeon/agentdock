# Harness Multi-Agent Team Kit v4

This kit is a tmux + Codex multi-agent operating system for real product projects.

v4 changes the runtime model:

- The kit is installed into your actual project as `.agent-system`.
- Agents write jobs, task cards, logs, handoffs, and reports into `.agent-work`.
- Codex agents start from the real project root or role-specific git worktrees.
- Each tmux window runs its own Codex session with a role-specific boot prompt.
- Agents do not assume their chats are shared. They coordinate through `.agent-work` files.

## Recommended setup

From the extracted kit directory:

```bash
./install-agent-system.sh --project /path/to/your/project
```

Then:

```bash
cd /path/to/your/project
.agent-system/04_TMUX/start-codex-agents.sh
tmux attach -t product-war-room
```

If your Codex CLI command is not `codex`:

```bash
CODEX_CMD="your-codex-command" .agent-system/04_TMUX/start-codex-agents.sh
```

To run without git worktrees:

```bash
.agent-system/04_TMUX/start-codex-agents.sh --no-worktrees
```

## Directory model

```txt
<PROJECT_ROOT>/
├── actual product code
├── .agent-system/
│   ├── 00_SYSTEM/
│   ├── 01_ROLES/
│   ├── 02_AGENT_PROMPTS/
│   ├── 03_WORKFLOWS/
│   ├── 04_TMUX/
│   ├── 05_TEMPLATES/
│   └── 06_CHECKLISTS/
├── .agent-work/
│   ├── 07_JOBS/
│   ├── 08_DECISIONS/
│   ├── 09_HANDOFFS/
│   ├── 10_REPORTS/
│   ├── 11_ARCHIVE/
│   ├── 12_INBOX/
│   ├── 13_OUTBOX/
│   └── 14_SHARED_CONTEXT/
└── ../<project>-agent-worktrees/
    ├── architecture/
    ├── development/
    ├── qa/
    ├── design/
    └── devops/
```

## First thing to do after tmux opens

Go to the CEO window and give the first goal:

```txt
User Goal:
PonsLink의 실시간 회의 번역 기능을 개선하고 싶다.

CEO Agent:
1. Inspect the repository and .agent-system rules.
2. Create a job in .agent-work/07_JOBS.
3. Break the job into task cards.
4. Assign tasks to the correct teams.
5. Define RACI, Definition of Done, and handoff order.
6. Use .agent-work for all coordination.
```

## Agent windows

The boot script creates these windows:

```txt
ceo
planning
business
marketing
design
architecture
development
qa
devops
risk
```

Each window runs Codex from a role-appropriate working directory.

## Important scripts

```txt
install-agent-system.sh
  Install this kit into a project as .agent-system.

04_TMUX/start-codex-agents.sh
  Start the tmux/Codex multi-agent runtime for the current project.

04_TMUX/create-agent-worktrees.sh
  Create role-based git worktrees manually.

04_TMUX/send-task-to-agent.sh
  Send a task file path to an agent window.

04_TMUX/spawn-agent.sh
  Spawn an extra temporary agent window.
```

## Core rule

The shared source of truth is not the tmux chat.

The shared source of truth is:

```txt
.agent-work
```

Every job, task, change, decision, handoff, and completion report should be recorded there with timestamps in this format:

```txt
YYMMDDHH:mm:ss
Example: 26051714:32:09
```

## Architecture Agent responsibility

Architecture Agent must prepare and hand off:

```txt
PRD
SRD
SRS
SDD
TDD
API SPEC
SYSTEM ARCHITECTURE
FLOW DIAGRAM
SEQUENCE DIAGRAM
ARCHITECTURE_TO_DEV_HANDOFF
```

Development should not implement from vague chat instructions. It should implement from accepted task cards and architecture handoff documents.

## When this is enough

This kit is intentionally not overbuilt into a full task-management SaaS. It gives Codex/tmux a working operating rhythm:

- boot agents
- assign roles
- split jobs
- write task cards
- use files for shared context
- isolate code work with worktrees
- record decisions and completion

Add more automation only after running a real project and finding friction.

---

## v4.1 tmux layout update

v4.1 adds pane-based tmux layouts so the agents can be viewed like a working room instead of scattered terminal windows.

Recommended boot from the target project root:

```bash
.agent-system/04_TMUX/start-codex-agents.sh --layout hybrid --fresh

tmux attach -t product-war-room
```

Available layouts:

```bash
--layout hybrid   # recommended: command-center / product-market / ops-risk
--layout grid     # all agents in one tiled window
--layout windows  # one tmux window per agent
```

See:

```text
04_TMUX/TMUX_LAYOUTS.md
```
