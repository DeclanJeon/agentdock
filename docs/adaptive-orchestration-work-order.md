# Adaptive Orchestration Work Order (CLI-only)

## Goal

Keep `adock job "..."` fast and understandable: simple jobs stay simple, larger jobs get a small useful Hermes team, and risky jobs require review/QA evidence before finish.

## Implementation Checklist

- [x] Classify jobs into `solo`, `focused`, `standard_team`, or `critical`.
- [x] Store mode, selected roles, rejected roles, team cap, QA/security policy, runtime model, and worktree metadata in `ORCHESTRATION.json`.
- [x] Generate task cards for selected roles.
- [x] Require selected-role reports before finalization.
- [x] Enforce QA/review gates for critical jobs.
- [x] Support `job tft` and `job meeting` records for blockers and decisions.
- [x] Support `job tick --json` and `--apply` for safe CEO follow-ups.
- [x] Expose read-only state through CLI snapshots/exports.
- [x] Remove desktop/UI assumptions from active implementation and tests.

## Validation

Run shell syntax checks, version checks, smoke tests, orchestration mode tests, QA gate tests, TFT/meeting tests, model settings tests, worktree/perf tests, and CLI-only removal contract tests.
