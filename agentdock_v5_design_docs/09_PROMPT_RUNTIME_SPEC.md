# Prompt Runtime Specification

## 1. Purpose

AgentDock makes prompts inspectable and project-aware. Each role receives a generated boot prompt file instead of a giant hidden string.

## 2. Prompt sources

Prompt composition uses these layers:

```txt
Global system rules
+ Global role template
+ Project-local role prompt override
+ Current project metadata
+ Current routing/workspace rules
= Generated boot prompt
```

## 3. Source locations

Global:

```txt
~/.local/share/agentdock/kit/00_SYSTEM/
~/.local/share/agentdock/kit/01_ROLE_TEMPLATES/
~/.local/share/agentdock/kit/02_AGENT_PROMPTS/
```

Project-local:

```txt
.agentdock/prompts/
.agentdock/generated/
.agent-work/14_SHARED_CONTEXT/
.agent-work/07_JOBS/CURRENT.md
```

## 4. Role prompt file

Path:

```txt
.agentdock/prompts/<role-id>.md
```

Example:

```md
# Backend Engineer

## Mission
Implement backend APIs, data access, business rules, and server-side tests.

## Boundaries
- Prefer server/API/database files.
- Do not change UI unless explicitly assigned.
- Do not change deployment secrets.

## Required output
- Implementation summary
- Files changed
- Tests run
- Risks
- Handoff notes
```

## 5. Generated boot prompt

Path:

```txt
.agentdock/generated/boot-<role-id>.md
```

Required sections:

```md
# Boot Prompt: <Display Name>

## Runtime identity
- Role id
- Display name
- Assigned CLI
- Project root
- Current working directory
- AgentDock project config

## Required reading
- role prompt
- system operating model
- task status machine
- message routing protocol
- work logging protocol
- current job if exists

## Operating rules
- coordinate through `.agent-work`
- do not assume chat is shared
- inspect git status before editing
- respect locks
- write reports
- write handoffs

## Output locations
- inbox
- outbox
- reports
- handoffs
- shared context

## First action
Read the required files, then reply with readiness statement.
```

## 6. Boot prompt generation algorithm

For each agent:

1. Read config entry.
2. Find prompt file path.
3. Ensure prompt file exists.
4. Determine assigned CLI.
5. Determine cwd.
6. Write boot file with absolute and relative paths.
7. Log generation event.

## 7. Boot prompt delivery

Do not send long prompt text directly to tmux in MVP. Send this instruction:

```txt
Read .agentdock/generated/boot-<role-id>.md and follow it. After reading, say READY - <display name>.
```

Reason:

- avoids tmux send escaping bugs;
- keeps prompts inspectable;
- works across different CLIs;
- allows easy regeneration.

## 8. Required shared rules

Every boot prompt must include these rules:

- The shared source of truth is `.agent-work`, not tmux chat.
- Use inbox/outbox for cross-agent communication.
- Use reports for status and completion summaries.
- Use handoffs when another role should continue work.
- Check locks before editing files.
- Do not modify files outside project root unless explicitly assigned.
- Do not install dependencies or run destructive commands without asking the user or orchestrator.

## 9. Role template presets

Global templates should include:

- orchestrator
- planner
- architect
- developer
- frontend
- backend
- qa
- reviewer
- devops
- docs
- risk
- custom

These are starting points only. Users can rename and edit them.

## 10. Prompt regeneration rules

`agentdock start` should regenerate boot prompts if:

- config changed;
- prompt file changed;
- current job changed;
- generated boot file missing;
- `--regen-prompts` provided.

Never overwrite project-local prompt overrides without confirmation.
