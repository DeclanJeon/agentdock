# Changelog

All notable AgentDock updates are recorded here by release version.

## 0.3.0 - 2026-05-23

- Added adaptive CEO orchestration artifacts for new jobs: `ORCHESTRATION.json`, selected/rejected role rationale, role caps, QA/security policy, runtime model metadata, and fallback compatibility for older jobs.
- Added adaptive team behavior so simple jobs do not spawn unnecessary teams, standard jobs reuse a small capped team, and critical jobs require stronger review/QA gates.
- Added QA gate enforcement, blocking TFT enforcement, `agentdock job tft create|close`, `agentdock job meeting start|conclude`, and `agentdock job tick [--json] [--apply]`.
- Added dependency extraction from role reports, write-conflict detection from task cards, action-audit/communication snapshots, meeting decision snapshots, and recovery guidance artifacts.
- Added the Visual Workspace orchestration panel, dependency/waiting-on display, selected/rejected role visibility, recent coordination display, model settings panel, and mock/demo fallback removal.
- Added adaptive orchestration design/work-order/checklist/mode/recovery docs and regression coverage for orchestration classification, QA gates, TFTs, meetings, dependencies, fixtures, desktop no-write boundaries, React build, and Rust checks.

## 0.2.1 - 2026-05-23

- Added the Visual Workspace desktop app with a controlled CEO Task Composer that sends `agentdock job --no-attach <request>` through Tauri without a shell.
- Limited the desktop bridge to controlled commands and kept broad write bridges, arbitrary shell execution, recruit/send/broadcast/finish/report/task-edit UI controls forbidden.
- Added the React/Tauri Visual Office runtime, pixel-office scene, dense-role navigation, final readiness/report/blocker surfaces, native/package evidence harnesses, and workspace fixture validation.
- Added no-write safety gates, job-create argv handling, secret redaction, accessibility/reference UI, visual fixtures, native screenshots, and package artifact checks.

## 0.1.8 - 2026-05-23

- Improved Hermes workroom startup with compact worker boot prompts, boot-prompt caching, and shorter configurable waits.
- Added better team communication through broadcasts, role inbox digests, watch/status paths, selected-team routing, mention routing, and common role aliases.
- Reduced coordination overhead with per-job selected-role caching and broadcast log rotation.
- Hardened local config parsing, adapter install allowlists, root-hash tmux session names, report timestamps, pane-state locking, JSON escaping, and release checksums.
- Added `adock report --fast` and hardened the Visual Workspace snapshot/export contract with secret redaction, config fallback warnings, accessibility labels, and density metadata.
