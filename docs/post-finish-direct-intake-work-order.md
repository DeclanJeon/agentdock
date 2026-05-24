# Post-Finish Direct Hermes Intake Work Order

Generated: 2026-05-24
Status: Ready for AgentDock job execution
Related design: `docs/post-finish-direct-intake-design.md`
Related checklist: `docs/post-finish-direct-intake-checklist.md`

## Goal

Implement a robust post-finish direct-intake path so a live coordinator Hermes tmux pane routes new direct user work through AgentDock job classification and tmux-backed team formation after the previous job has finished.

## User problem

After an `adock job` completes, the coordinator tmux pane remains running. If the user later gives that live Hermes agent a normal request, the agent must decide whether the task is solo or requires a team, then create/reuse a tmux-backed AgentDock team when needed. It must not use Hermes internal teams or Codex/native subagents.

Current behavior depends too much on prompt compliance and can misread a completed `CURRENT.md` as an active job.

## Execution mode

Recommended AgentDock team:

| Role | Required | Mission |
|---|---:|---|
| orchestrator | yes | Own job lifecycle, keep team small, enforce tmux-only team semantics, aggregate reports. |
| developer | yes | Implement CLI/lifecycle/intake changes in `bin/agentdock` and tests. |
| agentdock-qa | yes | Verify post-finish direct-intake scenarios, regression shell tests, and no native-subagent path. |
| system-architect | optional/P1 | Review active-job state semantics and backward compatibility if developer finds ambiguity. |
| delivery-planner | optional/P2 | Update release notes/docs if this becomes release-facing. |

Smallest useful default: orchestrator + developer + agentdock-qa. Add system-architect only if active/current pointer semantics conflict with existing workflows.

## Constraints

- Use tmux AgentDock roles only for team work.
- Do not use Hermes native subagents, Codex native subagents, or internal team modes for AgentDock team formation.
- Keep `agentdock job` adaptive classification as the single source of solo/team mode logic.
- Preserve historical job artifacts and final reports.
- Do not break explicit `--job <path>` operations on completed jobs.
- Do not introduce non-terminal UI behavior.
- No network/model call should be required by tests.

## Source files likely touched

- Modify: `bin/agentdock`
- Create: `tests/post_finish_direct_intake.sh`
- Modify: `docs/adaptive-orchestration-design.md`
- Modify: `docs/adaptive-orchestration-modes.md`
- Modify: `docs/DEVELOPER_NOTES.md` if developer notes are expected to stay current
- Existing docs for context:
  - `docs/post-finish-direct-intake-design.md`
  - `docs/post-finish-direct-intake-checklist.md`

## Acceptance criteria

1. After `agentdock job finish`, there is no ambiguous active current pointer.
2. `LAST_FINISHED.md` records the most recent completed job and final report path.
3. `agentdock intake --from <role> --request "..."` exists and routes through the same job creation/classification path as `agentdock job`.
4. Completed `CURRENT.md` fixtures are treated as no active job.
5. Unfinished active jobs are not silently overwritten by unrelated direct intake.
6. Coordinator boot prompt no longer says raw `CURRENT.md` existence is enough to mean active job.
7. Generated coordinator prompt tells direct user work to use `agentdock intake` or compatibility `adock-delegate`.
8. Generated prompt preserves tmux-only team formation and forbids native subagent/internal team mode for AgentDock teams.
9. Stale tmux pane mappings are ignored or cleaned before send/recruit logic claims a live role.
10. Tests prove solo, standard team, and critical review intake classification.
11. Existing adaptive orchestration and smoke tests still pass.

## Suggested implementation sequence

### Task 1: Add active-job helper tests first

Objective: create failing coverage for completed-current semantics.

Files:

- Create: `tests/post_finish_direct_intake.sh`

Steps:

1. Copy the fake `tmux` / fake `hermes` pattern from `tests/workspace_adaptive_orchestration.sh`.
2. Add helper `make_project()` with at least an `orchestrator`, `developer`, and `agentdock-qa` role.
3. Create a job fixture whose `LIFECYCLE.md` contains `Status: complete` and whose `CURRENT.md` points to that fixture.
4. Run the not-yet-implemented command:

```bash
env PATH="$fakebin:$PATH" ./bin/agentdock intake --from orchestrator --project "$project" --request "문서 오타를 수정해줘"
```

5. Expected initial result before implementation: FAIL because `intake` command does not exist or completed-current handling is wrong.

### Task 2: Add active-job resolver helpers

Objective: separate raw current pointer parsing from active unfinished job detection.

Files:

- Modify: `bin/agentdock`

Implementation requirements:

- Add `job_lifecycle_status`.
- Add `job_is_active`.
- Add `current_active_job_dir`.
- Do not remove `current_job_dir`; legacy explicit operations still need it.

Verification:

```bash
bash -n bin/agentdock
```

Expected: exit 0.

### Task 3: Update finish pointer behavior

Objective: successful finish should close active state and record historical last-finished state.

Files:

- Modify: `bin/agentdock`

Implementation requirements:

- In `cmd_job_finish`, after final report creation and teardown summary, write:

```text
.agent-work/07_JOBS/LAST_FINISHED.md
```

with:

```text
Finished job: <job README path>
Final report: <final report path>
Finished at: <timestamp>
```

- Remove `CURRENT.md` after finish, or rewrite it so active resolvers reject it. Preferred: remove it.
- Do not remove job directory or reports.

Verification:

```bash
bash -n bin/agentdock
```

Expected: exit 0.

### Task 4: Implement `agentdock intake`

Objective: provide explicit direct-user-work intake path.

Files:

- Modify: `bin/agentdock`

Implementation requirements:

- Add `cmd_intake()` near `cmd_delegate()`.
- Parse:
  - `--from <role>`
  - `--request <text>`
  - `--file <path>`
  - `--project <path>`
- Validate request non-empty.
- Default `--from` to `orchestrator_role "$root"`.
- Validate role exists.
- If `current_active_job_dir "$root"` returns no active job, call:

```bash
cmd_job_start --from "$from" --request "$text" --no-attach --project "$root"
```

- If an unfinished active job exists, choose conservative behavior:
  - do not overwrite `CURRENT.md` silently.
  - write a clear message or fail with a clear instruction. For this slice, failing clearly is acceptable:

```text
agentdock: active unfinished job exists: <path>. Finish it first or send a scoped job follow-up.
```

- Add command dispatch in main case:

```bash
intake) cmd_intake "$@" ;;
```

- Update help text to include `intake`.

Verification:

```bash
bash -n bin/agentdock
```

Expected: exit 0.

### Task 5: Keep compatibility aliases

Objective: existing `adock-delegate` and `agentdock delegate` still work.

Files:

- Modify: `bin/agentdock`

Implementation requirements:

- Keep `cmd_delegate` but have it call `cmd_intake` or share the same implementation path.
- Do not break `/home/declan/.local/bin/adock-delegate` behavior after install/symlink update.
- Help text should say `delegate` is compatibility and `intake` is preferred.

Verification:

```bash
./bin/agentdock help | grep -E 'intake|delegate'
```

Expected: both are present.

### Task 6: Update coordinator prompt generation

Objective: stop raw `CURRENT.md exists` from implying active job.

Files:

- Modify: `bin/agentdock`

Targets:

- `generate_role_prompt()` coordinator orchestration text.
- `generate_boot_prompt()` coordinator rules and first action text.
- Any current text similar to `If .agent-work/07_JOBS/CURRENT.md exists`.

Required wording concepts:

- `CURRENT.md` must point to an unfinished job to count as active.
- Completed `CURRENT.md` or no `CURRENT.md` means no active job.
- Direct user work in the coordinator pane should run `agentdock intake --from <role> --request "<verbatim user request>"`.
- `adock-delegate` remains compatibility.
- Team means tmux roles created/reused with `agentdock recruit`.
- Native subagents/internal team mode are forbidden for AgentDock team formation.

Verification:

```bash
bash -n bin/agentdock
```

Then generate a test boot prompt in a temp project and assert wording in the test script.

### Task 7: Harden stale pane mapping behavior

Objective: avoid dispatching to dead tmux panes after old sessions/jobs.

Files:

- Modify: `bin/agentdock`

Implementation requirements:

- Before `send_message_to_role` sends keys to a pane, validate that pane id exists in live tmux.
- If stale, call `pane_state_remove "$root" "$role"` and only write the inbox file.
- Do not fail the whole command only because the tmux pane is stale; the inbox artifact is still useful.
- Ensure `recruit_role` can recreate the pane later.

Verification:

- Covered by `tests/post_finish_direct_intake.sh` fake tmux case.
- Run syntax check.

### Task 8: Complete post-finish intake tests

Objective: make the new test script comprehensive enough to prevent regression.

Files:

- Modify: `tests/post_finish_direct_intake.sh`

Required cases:

1. Finish clears active current and writes `LAST_FINISHED.md`.
2. Completed `CURRENT.md` is treated as inactive and new intake creates a new job.
3. `agentdock intake` simple docs request -> `solo_direct`.
4. `agentdock intake` CLI/QA implementation request -> `standard_team`, `requires_qa=true`, `QA.md` exists.
5. `agentdock intake` security/token request -> `critical_review`, `requires_security_review=true`.
6. Active unfinished job blocks silent overwrite.
7. Generated coordinator boot prompt contains required direct-intake/tmux-only language.
8. Stale pane mapping is ignored or removed.

Verification:

```bash
bash tests/post_finish_direct_intake.sh
```

Expected:

```text
post-finish direct intake ok
```

### Task 9: Update docs

Objective: align repo docs with the new lifecycle and command.

Files:

- Modify: `docs/adaptive-orchestration-design.md`
- Modify: `docs/adaptive-orchestration-modes.md`
- Modify: `docs/DEVELOPER_NOTES.md`

Required notes:

- `agentdock intake` is preferred for direct user work in a live coordinator pane.
- `adock-delegate` / `agentdock delegate` are compatibility aliases.
- `CURRENT.md` represents active unfinished job only; `LAST_FINISHED.md` stores historical last finish.
- Direct intake uses the same adaptive classifier as `agentdock job`.
- Team formation remains tmux-backed via `agentdock recruit` only.

Verification:

```bash
grep -R "agentdock intake" docs bin/agentdock
```

Expected: command is documented in help/prompt/docs.

### Task 10: Run full regression suite

Objective: verify no existing AgentDock behavior broke.

Run:

```bash
bash -n bin/agentdock
bash tests/workspace_adaptive_orchestration.sh
bash tests/workspace_qa_gate.sh
bash tests/workspace_tft_artifacts.sh
bash tests/workspace_tick_meeting_dependencies.sh
bash tests/workspace_model_settings.sh
bash tests/workspace_status_worktree_perf.sh
bash tests/workspace_action_audit.sh
bash tests/post_finish_direct_intake.sh
bash tests/smoke.sh
```

Expected: all pass.

If a test fails, developer must diagnose root cause before changing tests. Do not weaken tests to fit broken behavior.

## QA instructions

QA must independently verify:

- `agentdock intake` and `agentdock job` share classification behavior.
- Finished jobs do not remain active.
- Direct intake after a completed job creates a new job.
- Active unfinished jobs are protected from silent overwrite.
- Generated prompts still forbid native subagents/internal team mode for AgentDock teams.
- Stale pane mapping behavior is safe.
- Full regression commands pass.

QA report command:

```bash
agentdock job report --from agentdock-qa --summary "QA: passed; tests=<exact commands>; risks=<remaining risks or none>"
```

If failing:

```bash
agentdock job report --from agentdock-qa --summary "QA: failed; tests=<exact commands>; blockers=<what must be fixed>"
```

## Developer report requirements

Developer must report:

- Files changed.
- Exact behavior change for `CURRENT.md` and `LAST_FINISHED.md`.
- Exact command examples for `agentdock intake`.
- Tests added and run.
- Any compatibility risks for scripts that read `CURRENT.md` after finish.

Developer report command:

```bash
agentdock job report --from developer --summary "Summary: ...; Files changed: ...; Tests run: ...; Blockers: none|...; Handoff needs: QA verification"
```

## Orchestrator finish rules

Do not run `agentdock job finish` until:

- Developer report is submitted.
- QA report is submitted with exact `QA: passed;` wording, or the final report intentionally closes as NO-GO with blockers.
- The final report includes whether `CURRENT.md` behavior changed and where `LAST_FINISHED.md` is written.

Final summary should distinguish:

- implementation complete vs release readiness,
- tests passed vs skipped,
- remaining compatibility risks.
