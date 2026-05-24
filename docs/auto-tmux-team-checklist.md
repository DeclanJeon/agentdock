# Auto tmux Team Formation Checklist

Generated: 2026-05-24
Status: Complete
Scope: ensure `adock job` / `agentdock intake` create real tmux/Hermes role panes when adaptive orchestration selects team work.

## Goal

When a user gives a new AgentDock job or direct post-finish intake:

1. AgentDock classifies whether the work is solo or team-based.
2. Solo work stays on the coordinator.
3. Team work creates or reuses real tmux-backed Hermes roles via the `agentdock recruit` path before task messages are sent.
4. AgentDock must not rely on Hermes native/internal subagents to satisfy team formation.

## Checklist

- [x] Add RED regression for automatic tmux role creation on team-classified jobs.
  - Standard-team request should create selected worker roles as real tmux panes.
  - `.agentdock/state/panes.env` should include selected worker pane IDs.
  - `ORCHESTRATION.json` should include the coordinator and worker roles.

- [x] Add RED regression for post-finish/direct intake path.
  - `agentdock intake --from <role> --request ...` should use the same auto tmux team path as `adock job`.

- [x] Implement automatic tmux recruit for missing selected worker roles.
  - Reuse already-running/configured roles when present.
  - Recruit only missing selected workers.
  - Keep `solo_direct` at zero worker recruitment.
  - Keep Hermes native/internal subagents out of the flow.

- [x] Update job artifacts and docs.
  - `TEAM.md` / task instructions should say workers were auto-started when applicable.
  - README should describe team-classified jobs as creating tmux roles directly.
  - Developer notes should document the code-level guarantee.

- [x] Verification.
  - [x] Focused new test fails before implementation.
  - [x] Focused new test passes after implementation.
  - [x] `bash -n bin/agentdock install.sh scripts/check-version.sh tests/*.sh`
  - [x] `bash scripts/check-version.sh`
  - [x] `python3 tests/fixtures/workspace/validate_workspace_fixtures.py`
  - [x] all `tests/*.sh`
  - [x] `git diff --check`
  - [x] commit and push
