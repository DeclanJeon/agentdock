# Adaptive CEO Orchestration Checklist

Status: Implementation pass 1 complete  
Last refreshed: 2026-05-23  
Design: `docs/adaptive-orchestration-design.md`  
Work order: `docs/adaptive-orchestration-work-order.md`

## P0 — Contract and safety

- [x] Define `agentdock.orchestration.v1` schema.
- [x] Add `ORCHESTRATION.json` to every new `adock job`.
- [x] Keep snapshot backward-compatible when orchestration fields are absent.
- [x] Preserve no-shell/no-broad-write Tauri boundary.
- [x] Ensure simple jobs do not auto-recruit teams.
- [x] Add tests for mode classification.
- [x] Add docs for mode meanings.

## P1 — Adaptive mode classifier

- [x] Implement `solo_direct` classification.
- [x] Implement `assisted_single_lane` classification.
- [x] Implement `standard_team` classification.
- [x] Implement `tft_required` as escalation-only, not initial default.
- [x] Implement `critical_review` classification.
- [x] Store classifier reason in `ORCHESTRATION.json`.
- [x] Add team cap per mode.

## P1 — Anti-over-orchestration policy

- [x] Require distinct output for every selected role.
- [x] Reuse configured/running roles before recommending recruit.
- [x] Record rejected role suggestions and reasons.
- [x] Cap standard jobs to 2–4 default workers.
- [x] Prevent agency role bulk import.
- [x] Avoid meeting artifacts for status-only updates.
- [x] Show “no team needed” state for simple jobs.

## P1 — Team plan and task cards

- [x] Add mode/reason/team cap to `TEAM.md`.
- [x] Generate selected role entries with source: reuse/recruit.
- [x] Generate task card for each selected non-CEO role.
- [x] Add dependencies field to task cards.
- [x] Add acceptance criteria to task cards.
- [x] Add required report command to task cards.
- [x] Warn if selected role has no task card.

## P2 — QA gate

- [x] Define QA policy by job type.
- [x] Add `requires_qa` to orchestration artifact.
- [x] Add optional `QA.md` template.
- [x] Add `qa_status` to snapshot.
- [x] Block finish when `requires_qa=true` and QA is missing/failed.
- [x] Allow finish without QA for simple low-risk jobs.
- [x] Add QA gate UI only when relevant.

## P2 — Dependency and blocker handling

- [x] Add optional `DEPENDENCIES.json`.
- [x] Extract dependency hints from task cards.
- [x] Extract blocker/dependency hints from reports.
- [x] Show blocked-by / waiting-on in snapshot.
- [x] Suggest follow-up before recruiting new roles.
- [x] Escalate to TFT only when blocker crosses role boundaries.

## P2 — TFT support

- [x] Add `JOB/TFTS/` directory creation.
- [x] Add TFT markdown schema.
- [x] Add `adock job tft create` or equivalent command.
- [x] Add `adock job tft close` or equivalent command.
- [x] Extend snapshot to parse TFT files.
- [x] Keep legacy `TEAM.md` `TFT:` parser as fallback.
- [x] Show TFT members, goal, status, exit condition in UI.
- [x] Ensure active blocking TFT can block finish.
- [x] Ensure closed TFT does not block finish.

## P3 — Meeting/debate support

- [x] Add `JOB/MEETINGS/` directory creation.
- [x] Add meeting artifact template.
- [x] Add meeting only for tradeoff/conflict/QA-fail decisions.
- [x] Record proposals.
- [x] Record decision.
- [x] Record rejected alternatives.
- [x] Record action items.
- [x] Surface concluded decisions in UI/history.

## P3 — CEO tick loop

- [x] Add `adock job tick` read-only preview mode.
- [x] Add `adock job tick --apply` for safe next action only.
- [x] Tick reads orchestration/team/tasks/reports/QA/TFTs.
- [x] Tick suggests finish when gates pass.
- [x] Tick suggests follow-up for stale role.
- [x] Tick suggests TFT for cross-role blocker.
- [x] Tick must not recruit beyond mode cap.
- [x] Tick must not create team for simple jobs.

## P3 — UI visibility

- [x] Add orchestration mode card or compact badge.
- [x] Show mode reason in Korean operator copy.
- [x] Show selected/rejected roles.
- [x] Show team cap.
- [x] Show QA required/not required.
- [x] Show TFT only when proposed/active/history exists.
- [x] Keep simple job UI uncluttered.
- [x] Maintain responsive layout.

## Tests

- [x] `tests/workspace_adaptive_orchestration.sh`
- [x] `tests/workspace_qa_gate.sh`
- [x] `tests/workspace_tft_artifacts.sh`
- [x] `tests/workspace_tick_meeting_dependencies.sh`
- [x] Fixture for simple solo job.
- [x] Fixture for standard team job.
- [x] Fixture for QA-required blocked finish.
- [x] Fixture for active TFT.
- [x] Tauri no-shell/no-write regression.
- [x] React build.
- [x] Rust tests.

## Acceptance criteria

- [x] Simple request completes without unnecessary team recruitment.
- [x] User can see why no team was created.
- [x] Standard request gets a small explainable team.
- [x] Risky request requires appropriate review/QA.
- [x] Blocked cross-role work can create a bounded TFT.
- [x] Meeting artifacts exist only for real decisions.
- [x] Final report includes orchestration mode, selected team, reports, QA status, TFT/meeting decisions if any, and remaining risks.

## Gap-review additions

### Communication and audit

- [x] Standardize cross-role message metadata.
- [x] Persist action audit entries into job artifacts.
- [x] Add handoff artifact template.
- [x] Expose recent bounded communication events in snapshot/UI.
- [x] Ensure coordination is not tmux-chat-only.

### Budget and authority

- [x] Add orchestration budget fields.
- [x] Block or require reason when exceeding role/TFT/meeting caps.
- [x] Add approval-required flag for destructive/security/production/dependency/model-global actions.
- [x] Ensure `job tick --apply` cannot perform high-risk actions without authority.
- [x] Show escalation reason in UI.

### Locks and write ownership

- [x] Add `write_scope` to task cards.
- [x] Add `shared_files` to task cards.
- [x] Detect overlapping write scopes.
- [x] Surface lock/write conflicts in snapshot/UI.
- [x] Require CEO coordination for shared-file edits.

### Recovery paths

- [x] Define stale role recovery order.
- [x] Define offline pane recovery order.
- [x] Define missing report recovery order.
- [x] Define QA failure recovery order.
- [x] Add `recovery_suggestion` to blocker alerts.
- [x] Ensure follow-up is suggested before backup recruitment when capability exists.

### Runtime model audit

- [x] Record current Hermes provider/model/source in `ORCHESTRATION.json`.
- [x] Include runtime model metadata in final report.
- [x] Keep model metadata optional for compatibility.

### Legacy compatibility

- [x] Add fallback mode for jobs without `ORCHESTRATION.json`.
- [x] Keep old jobs visible in history.
- [x] Keep legacy `TEAM.md` `TFT:` parser.
- [x] Add legacy fixture with no new orchestration artifacts.
