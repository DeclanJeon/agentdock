# Changelog

All notable AgentDock updates are recorded here by release version.

## 0.3.2 - 2026-05-23

- Removed the desktop application stack and all tracked React/Vite/Tauri source, native packaging, generated character assets, and UI-only tests.
- Simplified installation and release packaging to CLI assets only: `bin`, adapters, roles, tests, scripts, README, VERSION, and install script.
- Kept terminal-first orchestration through `adock job "..."`, CEO-led team selection, reports, QA gates, TFT/meeting records, runtime model settings, and worktree tools.
- Converted workspace HTML export into a lightweight CLI diagnostic that embeds status JSON and uses no bundled visual assets.

## 0.3.1 - 2026-05-23

- Added live role status files and `agentdock status set/show` to avoid expensive report scans.
- Added faster job kickoff, short snapshot caching, workspace performance metrics, source update, safe uninstall, and optional per-role worktree management.

## 0.3.0 - 2026-05-23

- Added adaptive CEO orchestration artifacts for new jobs: `ORCHESTRATION.json`, selected/rejected role rationale, role caps, QA/security policy, runtime model metadata, and fallback compatibility for older jobs.
- Added adaptive team behavior so simple jobs do not spawn unnecessary teams, standard jobs reuse a small capped team, and critical jobs require stronger review/QA gates.
- Added QA gate enforcement, blocking TFT enforcement, `agentdock job tft create|close`, `agentdock job meeting start|conclude`, and `agentdock job tick [--json] [--apply]`.
- Added dependency extraction from role reports, write-conflict detection from task cards, action-audit/communication snapshots, meeting decision snapshots, and recovery guidance artifacts.

## 0.2.1 - 2026-05-23

- Added a desktop workspace experiment with a controlled CEO task composer. This experiment was removed in 0.3.2 in favor of CLI-only operation.

## 0.1.8 - 2026-05-23

- Improved Hermes workroom startup with compact worker boot prompts, boot-prompt caching, and shorter configurable waits.
- Added better team communication through broadcasts, role inbox digests, watch/status paths, selected-team routing, mention routing, and common role aliases.
- Hardened local config parsing, adapter install allowlists, root-hash tmux session names, report timestamps, pane-state locking, JSON escaping, and release checksums.
