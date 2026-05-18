# Installer and Updater Specification

## 1. Installation goal

The user installs AgentDock globally once, then runs it inside any project.

```bash
curl -fsSL https://agentdock.dev/install.sh | bash
```

## 2. Default install paths

```txt
~/.local/bin/agentdock
~/.local/share/agentdock/
~/.config/agentdock/
```

## 3. Installer responsibilities

The installer shall:

1. Detect OS.
2. Create install directories.
3. Install `agentdock` executable wrapper.
4. Install subcommand scripts.
5. Install built-in adapters.
6. Install default kit files.
7. Create default global config.
8. Check whether `~/.local/bin` is in PATH.
9. Print next steps.

## 4. Installer non-responsibilities

The installer shall not:

- install AI CLIs automatically;
- edit shell profile without asking;
- require sudo by default;
- initialize a project;
- create tmux sessions.

## 5. Install command options

```bash
install.sh                    # user-level install
install.sh --prefix <path>     # custom prefix
install.sh --system            # optional system-level install
install.sh --uninstall         # remove global installation
```

## 6. PATH handling

If `~/.local/bin` is not in PATH:

Print:

```txt
Add this to your shell profile:
export PATH="$HOME/.local/bin:$PATH"
```

Ask before modifying shell files.

## 7. Update command

`agentdock update` should:

1. Check current version.
2. Download latest release or print manual update instructions.
3. Preserve user config.
4. Replace global kit files.
5. Never modify project `.agentdock` unless migration is explicitly run.

MVP can implement update by rerunning installer.

## 8. Uninstall command

`agentdock uninstall` should remove:

```txt
~/.local/bin/agentdock
~/.local/share/agentdock
```

It should ask separately before removing:

```txt
~/.config/agentdock
```

It must not delete any project `.agentdock` or `.agent-work` automatically.

## 9. Versioning

Global file:

```txt
~/.local/share/agentdock/VERSION
```

Command:

```bash
agentdock version
```

Output:

```txt
AgentDock 0.1.0
```

## 10. Packaging for MVP

MVP can ship as a zip/tarball containing:

```txt
agentdock/
├─ install.sh
├─ bin/
├─ adapters/
└─ kit/
```

The install script copies these files into global paths.
