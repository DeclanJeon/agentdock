# Project Runtime Model

This kit must run inside a real product/project directory, not inside the kit directory itself.

## Directory roles

```txt
<PROJECT_ROOT>/
├── actual product code
├── .agent-system/       # operating manuals, prompts, workflows, templates
├── .agent-work/         # jobs, tasks, logs, handoffs, reports, shared context
└── ../<project>-agent-worktrees/
    ├── architecture/
    ├── development/
    ├── qa/
    ├── design/
    └── devops/
```

## Agent system directory

`.agent-system` is the rulebook. Agents read from it but should not casually modify it during normal project work.

It contains:

- role definitions
- boot prompts
- tmux scripts
- workflow rules
- templates
- checklists
- governance rules

## Agent work directory

`.agent-work` is the shared company workspace. Agents communicate through files here because Codex sessions do not automatically share chat context.

It contains:

- job breakdowns
- task cards
- work logs
- task changelogs
- handoff files
- completion reports
- decision records
- shared project context

## Worktrees

Development-oriented agents should not all edit the same working tree.

Recommended:

- CEO, PM, Business, Marketing, Risk: project root
- Architecture: architecture worktree
- Development: development worktree
- QA: qa worktree
- Design: design worktree when design files or UI implementation will be touched
- DevOps: devops worktree

## Communication rule

Agents do not rely on hidden conversation memory across tmux panes.

All durable collaboration must be written into `.agent-work` files.

## First command after boot

The user should normally talk to the CEO Agent first:

```txt
User Goal:
<what you want to build/change/analyze>

CEO Agent, create the job, task breakdown, team assignment, RACI, and handoff order.
Use .agent-work as the shared workspace.
```
