# Security and Privacy Specification

## 1. Security posture

AgentDock is a local developer tool. It should be transparent and conservative because it launches external AI CLIs and may run installation commands.

## 2. Consent requirements

AgentDock must ask confirmation before:

- installing third-party AI CLIs;
- running curl-piped scripts;
- overwriting project config;
- overwriting project prompt files;
- killing tmux sessions;
- modifying shell profile;
- deleting global user config;
- enabling git worktrees if it creates branches.

## 3. Secrets handling

AgentDock must not ask for or store:

- API keys;
- OAuth tokens;
- passwords;
- private SSH keys.

AI CLIs handle their own authentication.

## 4. Install command safety

Before executing install commands, print:

```txt
AgentDock will run:
<command>

Proceed? [y/N]
```

Default answer is no.

## 5. Adapter safety

- Built-in adapters ship with AgentDock.
- User custom adapters live in `~/.config/agentdock/adapters`.
- Project-local adapter execution is not supported in MVP to avoid repository-supplied command execution.
- Adapter install commands are never run during detection.

## 6. Project boundary

Agent boot prompts must include:

- do not edit files outside project root;
- do not modify secrets;
- do not install packages without confirmation;
- do not run destructive commands without confirmation;
- write reports before handoff.

## 7. Logging safety

Do not log environment variables wholesale.

Safe logs:

- command names;
- detected binary paths;
- timestamps;
- role ids;
- file paths;
- high-level status.

Unsafe logs:

- token values;
- full env dumps;
- private key contents;
- `.env` file contents.

## 8. tmux safety

AgentDock should only kill sessions it created or sessions matching project config after confirmation.

## 9. Supply chain note

Since third-party CLI install commands can change over time, adapter install commands should be reviewed and versioned. AgentDock should print the command so the user can inspect before running.

## 10. Safe defaults

- `use_worktrees=false` by default in MVP.
- `attach_on_start=true`.
- no automatic task execution after install.
- no hidden background daemon.
- no network calls except installer/update and user-approved third-party CLI installation.
