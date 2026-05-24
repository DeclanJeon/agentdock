# Post-Finish Direct Hermes Intake Design

Generated: 2026-05-24
Status: Proposed
Scope: AgentDock CLI / Hermes tmux roles only

## Goal

When an AgentDock job finishes and the coordinator Hermes tmux pane remains alive, a later direct user request given to that pane must be routed through AgentDock's orchestration pipeline, not handled as a normal standalone Hermes task and not delegated to Hermes/Codex native subagents.

The desired flow is:

```text
User direct request in live Hermes tmux pane
  -> detect/request intake boundary
  -> create a new AgentDock job
  -> classify solo vs team via ORCHESTRATION.json
  -> reuse existing tmux roles or recruit missing tmux roles
  -> execute through task cards/reports
  -> finish and teardown completed workers
```

## Non-goals

- Do not add a second non-terminal control plane.
- Do not use Hermes internal teams, Codex native subagents, or any model-provider team feature to satisfy AgentDock team formation.
- Do not reopen or mutate a completed prior job as the default behavior.
- Do not bulk-import agency roles. Keep smallest useful team semantics.
- Do not expand OpenAPI/browser/UI surfaces; this is CLI/tmux orchestration logic.

## Current behavior summary

Current supporting pieces already exist:

- `bin/agentdock:495-592` classifies every `agentdock job` request into adaptive orchestration modes.
- `bin/agentdock:2899-3246` creates a CEO-led job, writes `ORCHESTRATION.json`, `TEAM.md`, `TASKS/`, and sends the CEO/selected roles tmux messages.
- `bin/agentdock:4267-4284` implements `delegate`, which calls `cmd_job_start --no-attach`.
- `bin/agentdock:1987-2000` and `bin/agentdock:2111-2127` tell coordinator roles to run `adock-delegate` when direct user work arrives.
- `bin/agentdock:2846-2897` keeps the coordinator pane active after finish and disbands only completed/reported worker panes.

Current gaps:

1. Direct-request routing is prompt-dependent. A live Hermes role must choose to follow boot instructions and run `adock-delegate`; there is no stronger intake boundary.
2. `CURRENT.md` remains after `job finish`, and boot logic treats existence of `CURRENT.md` as active-job evidence even if `LIFECYCLE.md` says `Status: complete`.
3. Stale pane mappings in `.agentdock/state/panes.env` can make the runtime believe a role exists even when the actual tmux session/pane differs.
4. Tests cover adaptive `agentdock job` classification, but not the post-finish live-pane direct-request handoff.

## Design principles

1. Job artifacts are source of truth, not tmux scrollback.
2. A completed job is historical, not active.
3. Direct user work inside an AgentDock coordinator pane is an intake event, not an execution event.
4. Team means tmux-backed AgentDock roles only.
5. Reuse before recruit; recruit only missing capability lanes.
6. Solo mode must stay lightweight and should not create fake teams.
7. The implementation must be testable without invoking real Hermes network/model calls.

## Proposed model

Introduce explicit active-job state semantics and a direct-intake command path.

### 1. Active job state resolver

Add a helper in `bin/agentdock`:

```bash
job_lifecycle_status() {
  local job_dir="$1" status
  status="$(sed -n 's/^Status:[[:space:]]*//p' "$job_dir/LIFECYCLE.md" 2>/dev/null | head -1)"
  [[ -n "$status" ]] && printf '%s' "$status" || printf 'unknown'
}

job_is_active() {
  local job_dir="$1" status
  [[ -d "$job_dir" ]] || return 1
  status="$(job_lifecycle_status "$job_dir")"
  case "$status" in
    complete|completed|closed|finished) return 1 ;;
    *) return 0 ;;
  esac
}

current_active_job_dir() {
  local root="$1" job_dir
  job_dir="$(current_job_dir "$root" 2>/dev/null || true)"
  [[ -n "$job_dir" ]] || return 1
  job_is_active "$job_dir" || return 1
  printf '%s\n' "$job_dir"
}
```

Use this helper anywhere the runtime needs to decide whether `CURRENT.md` represents active work.

### 2. Finish semantics

After successful `cmd_job_finish`, keep a historical pointer but remove or neutralize the active pointer.

Recommended minimal behavior:

- Write `.agent-work/07_JOBS/LAST_FINISHED.md` with the final job path and final report path.
- Replace `.agent-work/07_JOBS/CURRENT.md` with a clear inactive marker or remove it.

Preferred behavior:

```text
.agent-work/07_JOBS/CURRENT.md        absent when no active job exists
.agent-work/07_JOBS/LAST_FINISHED.md  historical pointer to most recent finished job
```

Rationale: boot/intake logic becomes simple and cannot misread a complete job as active.

Backward compatibility:

- `current_job_dir()` can remain as the raw legacy parser.
- New code should call `current_active_job_dir()` when it needs an unfinished job.
- `job report`, `job finish`, and follow-up commands should accept `--job <path>` for historical or explicit operations.

### 3. Direct intake command

Add or formalize a command whose purpose is explicit:

```bash
agentdock intake --from <role> --request "..." [--project <path>]
```

Implementation can initially delegate to the existing function:

```bash
cmd_intake() {
  # parse --from/--request/--file/--project
  # require role exists
  # if there is an active current job, create a follow-up message or a new job depending on policy
  # if no active job, call cmd_job_start --from "$from" --request "$text" --no-attach --project "$root"
}
```

`adock-delegate` can remain as a compatibility alias. New prompt text should prefer `agentdock intake` because its name describes the boundary more clearly.

### 4. Intake policy

When a direct user request arrives in a live coordinator pane:

1. Determine active job state with `current_active_job_dir`.
2. If no active job exists:
   - create a new job with `cmd_job_start --no-attach`.
   - classification runs through existing `write_orchestration_json`.
3. If an active job exists and the request is clearly a report/follow-up for that job:
   - route as a job message or CEO action inside the current job.
4. If an active job exists but the request is a new unrelated task:
   - default to creating a new job only if concurrent jobs are supported safely.
   - if concurrent jobs are not supported, refuse with a clear message that an active job must finish first, unless the user explicitly requests supersede/queue.

For the current codebase, choose the conservative policy:

```text
No active job -> create new job.
Active unfinished job -> create a message under the active job or reject new-job intake with a clear instruction.
Completed current pointer -> treat as no active job.
```

### 5. Boot prompt changes

Update coordinator boot prompt generation so it no longer says `CURRENT.md exists => active job`.

Replace the rule with:

```text
If `.agent-work/07_JOBS/CURRENT.md` points to an unfinished job, execute the active job flow.
If it points to a completed job or is absent, treat direct user work as a new intake and run `agentdock intake --from <role> --request "<verbatim user request>"`.
```

The generated prompt should explicitly say:

- Do not execute direct user implementation work in the coordinator pane unless the new job classifies as `solo_direct` and the job task card assigns the coordinator to execute it.
- Do not use native Hermes/Codex subagents for AgentDock team formation.
- Team creation/reuse must happen through `agentdock recruit` and tmux role panes.

### 6. Team formation path

Do not add a new team classifier. Reuse `write_orchestration_json()` so `agentdock intake` and `agentdock job` behave identically.

Expected behavior by mode:

| Mode | Direct request behavior |
|---|---|
| `solo_direct` | New job is created; coordinator handles directly; no worker task cards except coordinator. |
| `assisted_single_lane` | New job is created; at most one configured/recruited specialist lane. |
| `standard_team` | New job is created; selected configured roles get task cards; missing roles are recruited by CEO through tmux. |
| `critical_review` | New job is created; QA/security/review gates are required before finish. |

### 7. Pane-state hygiene

Before sending or recruiting, validate pane mappings:

- `tmux has-session -t "$SESSION_NAME"`
- `tmux list-panes -a -F '#{pane_id}' | grep -Fxq "$pane"`

If a pane mapping is stale:

- remove it from `.agentdock/state/panes.env`.
- allow `agentdock recruit <role>` or `agentdock start` to recreate it.

This reduces false reuse after old tmux sessions are gone.

### 8. Artifact changes

New/changed files:

- `bin/agentdock`
  - add active-job helpers.
  - add `cmd_intake` or make `cmd_delegate` call the active resolver.
  - update `cmd_job_finish` to clear/neutralize current active pointer and write `LAST_FINISHED.md`.
  - update boot prompt text generated by `generate_role_prompt` and `generate_boot_prompt`.
  - update help text.
- `tests/post_finish_direct_intake.sh`
  - new integration test.
- `tests/workspace_adaptive_orchestration.sh`
  - extend only if needed to assert `agentdock intake` equivalence to `agentdock job`.
- `docs/post-finish-direct-intake-design.md`
  - this design.
- `docs/post-finish-direct-intake-checklist.md`
  - implementation checklist.
- `docs/post-finish-direct-intake-work-order.md`
  - AgentDock-ready work order.

## Test strategy

Use fake `tmux` and fake `hermes` like `tests/workspace_adaptive_orchestration.sh` so no model/network call is required.

Required tests:

1. Finish clears active current:
   - create a job.
   - provide required reports if needed or create a solo job.
   - run `agentdock job finish`.
   - assert `CURRENT.md` is absent or inactive.
   - assert `LAST_FINISHED.md` exists and points to final report.
2. Completed CURRENT is not active:
   - create a fixture where `CURRENT.md` points to a job with `LIFECYCLE.md Status: complete`.
   - run `agentdock intake --from orchestrator --request "..."`.
   - assert a new `JOB-*` is created and `CURRENT.md` now points to the new job.
3. Intake uses adaptive classifier:
   - simple docs request -> `solo_direct`.
   - multi-lane/test request -> `standard_team`, QA required.
   - security/token request -> `critical_review`.
4. No native subagent path:
   - assert generated coordinator boot prompt contains tmux/recruit prohibition language.
   - assert no test path calls Hermes internal team/subagent commands.
5. Stale pane cleanup:
   - fake `panes.env` contains a pane id that `tmux list-panes` does not return.
   - send/recruit path should not treat it as valid running pane.

## Acceptance criteria

- A completed previous job cannot be mistaken for an active job by boot or intake logic.
- A direct user request in a live coordinator pane has one canonical command path: `agentdock intake` / compatibility `adock-delegate`.
- New intake creates a normal CEO-led job and writes `ORCHESTRATION.json`.
- Solo/team/critical classification remains shared with `agentdock job`.
- Team work uses `agentdock recruit` and tmux panes only.
- `job finish` still keeps the coordinator pane alive but no longer leaves an ambiguous active job pointer.
- Existing tests pass and the new post-finish direct-intake tests pass.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Existing scripts expect `CURRENT.md` after finish | Add `LAST_FINISHED.md`; keep raw `current_job_dir` for explicit legacy flows; document the change. |
| Active job follow-up gets incorrectly treated as new job | Conservative policy: if active unfinished job exists, do not silently create new job unless explicit. |
| Prompt text drifts from CLI behavior | Test generated boot prompt for required intake/team-formation language. |
| Stale tmux panes cause false dispatch | Validate pane id against live tmux before reuse; remove stale mappings. |
| Too many roles recruited | Reuse existing classifier and team cap; keep agency bulk import rejected. |
