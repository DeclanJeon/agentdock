# AgentDock Remaining Work Checklist

Generated: 2026-05-24
Status: In progress
Scope: main branch quality, post-finish intake hardening, docs/CI/release consistency

## P0 — CI / release blockers

- [x] Fix README/version metadata mismatch so `bash scripts/check-version.sh` passes.
  - Evidence: `README status version does not match VERSION=0.3.2`.
  - Fix: added explicit `Version \`0.3.2\`` status text to `README.md`.
  - Verified: `bash scripts/check-version.sh`.

- [x] Fix `tests/workspace_p05.sh` failure around exported workspace accessibility marker.
  - Evidence: test expected legacy desktop `role="button"`/Tamagotchi GIF markers while current export is CLI-only static HTML.
  - Fix: updated `tests/workspace_p05.sh` to assert CLI-only read-only export markers, embedded snapshot JSON, density class, role count, and absence of GIF assets.
  - Verified: `bash tests/workspace_p05.sh`.

- [x] Preserve read-only behavior for `workspace snapshot --json` and `workspace export`.
  - Evidence: `tests/workspace_quiet_no_write.sh` could mutate `.agentdock/state/panes.env` when stale pane mappings existed.
  - Fix: made `tmux_target_for_role` cleanup opt-in; snapshot/export use read-only lookup while write-intent paths pass cleanup mode. Added an explicit stale pane mapping fixture to the no-write test.
  - Verified: `bash tests/workspace_quiet_no_write.sh`.

## P1 — Post-finish intake hardening

- [x] Apply active-job resolver consistently to default job commands.
  - Current risk: `job report`, `job finish`, `job tft`, `job meeting`, and `job tick` still defaulted through raw `current_job_dir()`.
  - Fix: changed default lookup to `current_active_job_dir()` for those commands; explicit `--job` report/finish paths still target historical jobs when requested.
  - Verified: `bash tests/post_finish_direct_intake.sh` includes completed-CURRENT default-command rejection coverage.

- [x] Update post-finish implementation docs from Proposed/checklist state to implemented-with-followups state.
  - Files: `docs/post-finish-direct-intake-design.md`, `docs/post-finish-direct-intake-checklist.md`, `docs/post-finish-direct-intake-work-order.md`.
  - Fix: design/checklist/work-order statuses now reflect implemented state; checklist items are checked.

## P1 — CI / release workflow

- [x] Expand CI beyond smoke + workspace_p05.
  - Include at minimum `tests/post_finish_direct_intake.sh` and `tests/workspace_quiet_no_write.sh`.
  - Fix: CI now validates fixtures and runs all `tests/*.sh`.
  - File: `.github/workflows/ci.yml`.

- [x] Include docs and top-level docs in release archive.
  - Current release package omits `docs`, `CHANGELOG.md`, and `DESIGN.md` while README links to them.
  - Fix: release package now includes `docs`, `CHANGELOG.md`, and `DESIGN.md`; release verification also runs all tests.
  - File: `.github/workflows/release.yml`.

## P2 — Documentation polish

- [x] Update `CHANGELOG.md` for post-finish direct intake and follow-up fixes.
- [x] Update `DESIGN.md` supported surfaces to mention `agentdock intake` / `adock-delegate`.
- [x] Update `docs/DEVELOPER_NOTES.md` stale line count/test list and `adock-delegate`-first phrasing.
- [x] Fix README typo: `` `s install.sh` `` → `install.sh` / `./install.sh`.
- [x] Reconcile `docs/bmad-template-sync-work-order.md` with implemented BMAD sync behavior.

## Final verification

- [x] `bash -n bin/agentdock install.sh scripts/check-version.sh tests/*.sh`
- [x] `bash scripts/check-version.sh`
- [x] `python3 tests/fixtures/workspace/validate_workspace_fixtures.py`
- [x] all `tests/*.sh`
- [x] `git diff --check`
- [x] commit and push
