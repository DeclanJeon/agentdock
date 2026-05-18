# CLI Adapter Specification

## 1. Purpose

Adapters let AgentDock detect, install, and run different AI coding CLIs without hardcoding role or vendor behavior into the core runtime.

## 2. Built-in adapters

MVP includes adapters for:

- `codex`
- `claude`
- `opencode`
- `hermes`
- `gemini`
- `custom`

## 3. Adapter fields

Bash MVP adapter file format:

```bash
ADAPTER_ID="codex"
ADAPTER_DISPLAY_NAME="OpenAI Codex CLI"
ADAPTER_BINARIES="codex"
ADAPTER_DETECT_CMD="command -v codex"
ADAPTER_VERSION_CMD="codex --version"
ADAPTER_INSTALL_METHODS="npm brew"
ADAPTER_INSTALL_NPM="npm i -g @openai/codex"
ADAPTER_INSTALL_BREW="brew install --cask codex"
ADAPTER_RUN_CMD="codex"
ADAPTER_NOTES="Requires login on first run."
```

## 4. Detection algorithm

For each adapter:

1. Load adapter file.
2. For each binary in `ADAPTER_BINARIES`, run `command -v`.
3. If found, mark installed.
4. Run `ADAPTER_VERSION_CMD` if set and command exists.
5. Record path and version.

Detection must not run install commands.

## 5. Installation algorithm

For `agentdock install <id>`:

1. Load adapter.
2. If already installed, print status and ask if reinstall is desired.
3. Determine install method:
   - use `--method` if provided;
   - if one method exists, select it;
   - if multiple methods exist, prompt.
4. Print exact command.
5. Ask confirmation unless `--yes`.
6. Execute command.
7. Re-run detection.
8. Print result.

## 6. Run command algorithm

For each role:

1. Read assigned adapter id.
2. Resolve `ADAPTER_RUN_CMD`.
3. Launch in tmux pane:

```bash
cd "$AGENT_CWD" && $ADAPTER_RUN_CMD
```

4. Send boot prompt instruction:

```txt
Read .agentdock/generated/boot-<role>.md and follow it.
```

## 7. Authentication handling

AgentDock must not manage API keys directly in MVP.

For each CLI:

- detect binary presence;
- optionally run version command;
- warn that first run may require login;
- provide `agentdock doctor` notes.

Possible future command:

```bash
agentdock auth check
```

But MVP can omit it.

## 8. Custom adapters

Custom adapters live at:

```txt
~/.config/agentdock/adapters/<id>.conf
```

They override built-in adapters with the same id only after warning.

Interactive creation:

```txt
CLI id: aider
Display name: Aider
Binary names: aider
Version command: aider --version
Install command: pipx install aider-chat
Run command: aider
```

Generated file:

```bash
ADAPTER_ID="aider"
ADAPTER_DISPLAY_NAME="Aider"
ADAPTER_BINARIES="aider"
ADAPTER_DETECT_CMD="command -v aider"
ADAPTER_VERSION_CMD="aider --version"
ADAPTER_INSTALL_METHODS="custom"
ADAPTER_INSTALL_CUSTOM="pipx install aider-chat"
ADAPTER_RUN_CMD="aider"
```

## 9. Adapter safety

Because adapter files can contain shell commands:

- built-in adapters are trusted as part of AgentDock release;
- custom adapters are user-owned;
- never execute install commands without confirmation;
- print command before execution;
- avoid sourcing arbitrary adapter files from project directories in MVP;
- load custom adapters only from `~/.config/agentdock/adapters`.

## 10. Built-in adapter examples

See `examples/adapters/` in this package.
