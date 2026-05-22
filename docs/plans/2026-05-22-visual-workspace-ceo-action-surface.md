# Visual Workspace CEO Action Surface Implementation Plan

> **For Hermes:** Use AgentDock tmux-role workflow, not native subagents, when executing this plan. Use strict TDD for behavior changes.

**Goal:** Make the desktop Visual Workspace support the user's target flow: open the app, enter a task for the CEO/orchestrator, have AgentDock create a CEO-led job, and then watch the CEO recruit roles, assign task cards, facilitate execution, collect reports, and finish.

**Architecture:** Keep the existing snapshot-first Visual Workspace as the source of truth, but add a narrowly scoped controlled action bridge for job creation only in the first implementation slice. Do not add arbitrary shell execution or broad write capability. All follow-up actions remain visible through snapshots until each action is separately designed, tested, and approved.

**Tech Stack:** Bash AgentDock CLI, React/Vite TypeScript UI, Tauri v2 Rust command bridge, `.agent-work` filesystem snapshots, tmux/Hermes roles.

---

## 0. Current-state finding

### What is already implemented

- CLI workflow supports the required orchestration pattern:
  - `adock job "..."`
  - CEO/orchestrator receives job intake.
  - CEO selects/recruits roles.
  - Task cards are written under `TASKS/`.
  - Role inbox messages are sent.
  - Role reports are submitted.
  - `adock job finish` aggregates final report.
- Visual Workspace desktop app renders current state from `agentdock workspace snapshot --json`.
- UI shows active job, lifecycle, selected roles, missing reports, blockers, read-only trust badges, dense-role navigation, inspector, final readiness.
- Release cleanup is currently green:
  - matrix 15/15 PASS
  - native `releaseProof=true`
  - `cargo test`, `npm run tauri:build`, package artifact verification passed.

### What is not implemented

- No app-side task composer.
- No app-side `job_create`/`delegate_to_ceo` Tauri command.
- No app button to send a new request to the CEO.
- No UI flow that shows job creation in progress, success, failure, or generated job id.
- No action audit UI.
- No controlled write/action capability model. Current `commands.write_bridge_enabled` is intentionally false.
- No direct recruit/send/finish buttons. This is acceptable for the first slice; those should not be added without explicit later scope.

### Key constraint

Current tests intentionally assert the desktop bridge exposes only `workspace_snapshot`. Implementing CEO task submission will require updating the safety contract from:

`read-only snapshot only`

to:

`read-only snapshot + one controlled job-create action`

This must be done explicitly, with tests proving no arbitrary shell/write bridge is exposed.

---

## 1. Target user flow

1. User opens Visual Workspace desktop app.
2. User sees current AgentDock state and a clearly labeled `CEO Task` composer.
3. User types a work request.
4. User clicks `Send to CEO`.
5. App calls a narrow Tauri command, e.g. `agentdock_job_create`.
6. Tauri validates project root and request.
7. Tauri runs the AgentDock binary without a shell:
   - `agentdock job --no-attach <request>`
8. CLI creates `.agent-work/07_JOBS/JOB-*`, updates `CURRENT.md`, and sends intake to orchestrator.
9. App shows structured success:
   - job id
   - job path
   - next expected phase: CEO planning/team selection
10. App refreshes snapshot.
11. User watches CEO facilitation through existing workspace UI:
   - planning
   - recruiting
   - executing
   - verifying
   - complete

---

## 2. Non-goals for first implementation slice

Do not implement these in the first slice:

- Arbitrary command execution from UI.
- Free-form shell bridge.
- Direct role recruitment buttons.
- Direct `send`, `broadcast`, `task card edit`, `report`, or `finish` buttons.
- UI editing of `.agent-work` files.
- JSON import/replacement workflow.
- OpenAPI expansion.

These can become separate controlled actions later, each with its own TDD and safety review.

---

## 3. Required file changes

### Backend / Tauri

- Modify: `src-tauri/src/lib.rs`
  - Add `ActionErrorKind` or extend the current result type safely.
  - Add request DTO: `JobCreateRequest { project_root: String, request: String }` or command args equivalent.
  - Add response DTO: `JobCreateResult` with `ok`, `statusCode`, `stdout`, `stderr`, `command`, `jobId`, `jobPath`, `message`, `durationMs`.
  - Add Tauri command: `agentdock_job_create(project_root: String, request: String) -> JobCreateResult`.
  - Execute only `[agentdock, "job", "--no-attach", request]` through `Command::new`, never via shell.
  - Reuse project root canonicalization and validation.
  - Apply timeout, redaction, and stderr/stdout sanitization.
  - Parse `JOB-...` and job path from stdout when present.
  - Update `generate_handler![workspace_snapshot, agentdock_job_create]`.

### Frontend types/model

- Modify: `src-ui/model/snapshot.ts`
  - Add `commands.allowed_actions?: string[]` or `commands.controlled_actions_enabled?: boolean`.
  - Keep `write_bridge_enabled` false unless a future broad write bridge exists.

- Create: `src-ui/model/actions.ts`
  - Define `JobCreateResult` TypeScript type.
  - Define validation helpers, e.g. `validateCeoTaskRequest(text)`.

### Frontend UI

- Create: `src-ui/components/CeoTaskComposer.tsx`
  - Textarea for user request.
  - Submit button.
  - Disabled state for empty/too-long/in-flight.
  - Result panel: created job id/path or redacted error.
  - Explicit trust copy: `Controlled action: creates a CEO-led AgentDock job. No arbitrary shell access.`

- Modify: `src-ui/App.tsx`
  - Import and render `CeoTaskComposer` near top HUD or command office area.
  - Pass `projectRootFromLocation()`.
  - On successful create, call `loadSnapshot()`.

- Optional later placement refinement:
  - Render composer inside `Command Office` / orchestrator area rather than global top row.

### Tests / gates

- Modify: `tests/workspace_desktop_no_write.sh`
  - Rename conceptual assertion to `controlled-action safety`.
  - Allow exactly `workspace_snapshot` and `agentdock_job_create` in Tauri handler.
  - Still fail if handler exposes `send`, `recruit`, `finish`, `broadcast`, shell bridge, file write, or arbitrary command tokens.

- Create: `tests/workspace_job_create_bridge.sh`
  - Use fake project and fake `agentdock` binary.
  - Verify Tauri/Rust unit logic or CLI-adjacent helper invokes exact command shape without shell.
  - Verify request is passed as a single argument.
  - Verify invalid project fails.
  - Verify empty/overlong request fails.

- Add Rust tests in `src-tauri/src/lib.rs`
  - Request validation.
  - Job id parsing.
  - Command vector construction.
  - Secret redaction.

- Add frontend tests only if test framework is introduced.
  - Current `package.json` has no Vitest. Either add Vitest in a separate TDD setup task or cover UI via existing shell/static checks until test framework is approved.

---

## 4. Bite-sized implementation tasks

### Task 1: Freeze action-surface contract

**Objective:** Document the security boundary before code changes.

**Files:**
- Create: `docs/visual-workspace-controlled-actions.md`
- Modify: `README.md`

**Steps:**
1. Write contract: allowed action in slice 1 is only `agentdock_job_create`.
2. State forbidden actions: shell, recruit, send, finish, file edit, arbitrary command.
3. State audit requirement: stdout/stderr redacted, job id/path shown.
4. Verify by readback.

**Command:**
```bash
python3 -m json.tool .agent-work/07_JOBS/JOB-260522142505456533/OUTPUTS/release-final-verification-matrix.json >/dev/null
```

**Expected:** PASS.

### Task 2: Add Rust command-shape tests first

**Objective:** RED-test controlled job create helper behavior before exposing Tauri command.

**Files:**
- Modify: `src-tauri/src/lib.rs`

**Tests to add:**
- `build_job_create_command_uses_no_shell`
- `parse_created_job_id_from_agentdock_output`
- `reject_empty_job_request`
- `reject_overlong_job_request`
- `redact_job_create_output_secrets`

**Run RED:**
```bash
cargo test --manifest-path src-tauri/Cargo.toml job_create -- --nocapture
```

**Expected:** FAIL because helpers do not exist yet.

### Task 3: Implement minimal Rust helpers

**Objective:** Pass helper tests without exposing Tauri command yet.

**Files:**
- Modify: `src-tauri/src/lib.rs`

**Implementation notes:**
- Add `const JOB_CREATE_TIMEOUT: Duration = Duration::from_secs(30);`
- Add `const MAX_JOB_REQUEST_CHARS: usize = 8000;`
- Add `fn validate_job_request(request: &str) -> Result<String, String>`.
- Add `fn build_job_create_args(request: &str) -> Vec<String>` returning `job --no-attach <request>`.
- Add `fn parse_job_id(text: &str) -> Option<String>`.

**Run GREEN:**
```bash
cargo test --manifest-path src-tauri/Cargo.toml job_create -- --nocapture
```

**Expected:** PASS.

### Task 4: Add Tauri command with exact handler exposure

**Objective:** Expose `agentdock_job_create` as the only controlled action.

**Files:**
- Modify: `src-tauri/src/lib.rs`

**Steps:**
1. Add `#[tauri::command] fn agentdock_job_create(project_root: String, request: String) -> JobCreateResult`.
2. Reuse project root validation.
3. Resolve AgentDock binary through existing `resolve_agentdock`.
4. Run `Command::new(agentdock).args(["job", "--no-attach", request])` with timeout.
5. Parse job id/path from output.
6. Update handler to `generate_handler![workspace_snapshot, agentdock_job_create]`.

**Verification:**
```bash
cargo test --manifest-path src-tauri/Cargo.toml
cargo check --manifest-path src-tauri/Cargo.toml
```

**Expected:** PASS.

### Task 5: Update no-write/safety gate to controlled-action gate

**Objective:** Keep safety tests strict while allowing the one new action.

**Files:**
- Modify: `tests/workspace_desktop_no_write.sh`

**Checks:**
- `workspace_snapshot` must exist.
- `agentdock_job_create` may exist.
- `generate_handler` must not expose any of:
  - `send`
  - `recruit`
  - `finish`
  - `broadcast`
  - `write_file`
  - `remove_file`
  - `control`
- No `sh -c`, `bash -c`, `/bin/sh`, `/bin/bash` in production adapter.
- Snapshot operation still must not mutate `.agentdock` or `.agent-work`.

**Run:**
```bash
bash tests/workspace_desktop_no_write.sh
```

**Expected:** PASS.

### Task 6: Add action bridge smoke test

**Objective:** Verify job creation command can be exercised safely with a fake AgentDock binary.

**Files:**
- Create: `tests/workspace_job_create_bridge.sh`

**Test shape:**
1. Create temp project with `.agentdock/` and `.agent-work/`.
2. Create fake `agentdock` binary that records argv and prints:
   - `Created CEO-led job: <tmp>/.agent-work/07_JOBS/JOB-TEST123`
3. Set `AGENTDOCK_BIN` to fake binary.
4. Run a Rust unit/integration path or a small helper binary path if exposed.
5. Assert argv equals `job`, `--no-attach`, `<request>` as separate args.
6. Assert no shell metacharacter expansion occurs when request contains `; rm -rf /`.

**Run:**
```bash
bash tests/workspace_job_create_bridge.sh
```

**Expected:** PASS.

### Task 7: Add frontend action types and validation

**Objective:** Add UI-side request validation without changing visual layout yet.

**Files:**
- Create: `src-ui/model/actions.ts`

**Required exports:**
- `MAX_CEO_TASK_CHARS = 8000`
- `validateCeoTaskRequest(text: string): { ok: boolean; message?: string }`
- `JobCreateResult` interface

**Verification:**
```bash
npm run build
```

**Expected:** PASS.

### Task 8: Add CEO Task Composer UI

**Objective:** Let user submit a task from the app.

**Files:**
- Create: `src-ui/components/CeoTaskComposer.tsx`
- Modify: `src-ui/App.tsx`
- Modify: `src-ui/styles.css`

**UI behavior:**
- Textarea placeholder: `Describe the work for the CEO to analyze, recruit, assign, and facilitate...`
- Submit button: `Send to CEO`
- Empty request disabled.
- In-flight disabled.
- Success shows job id and message.
- Failure shows redacted error.
- On success, call `loadSnapshot()`.
- Trust copy visible: `Controlled action · creates a CEO-led job only · no arbitrary shell`.

**Verification:**
```bash
npm run build
bash tests/workspace_desktop_app.sh
```

**Expected:** PASS.

### Task 9: Add snapshot support for controlled actions metadata

**Objective:** Make UI display action capability from snapshot, not hardcoded assumptions.

**Files:**
- Modify: `bin/agentdock` workspace snapshot generation
- Modify: `src-ui/model/snapshot.ts`
- Modify: `src-ui/components/TopHud.tsx`

**Snapshot contract:**
```json
"commands": {
  "mode": "controlled-actions",
  "write_bridge_enabled": false,
  "allowed_read_commands": ["workspace snapshot --json"],
  "allowed_actions": ["agentdock job --no-attach"]
}
```

**Verification:**
```bash
./bin/agentdock workspace snapshot --json | python3 -m json.tool >/tmp/workspace.json
python3 - <<'PY'
import json
s=json.load(open('/tmp/workspace.json'))
assert s['commands']['write_bridge_enabled'] is False
assert 'agentdock job --no-attach' in s['commands'].get('allowed_actions', [])
PY
```

**Expected:** PASS.

### Task 10: Render facilitation timeline from existing artifacts

**Objective:** Make it clear after job creation that CEO is facilitating work.

**Files:**
- Modify: `bin/agentdock` snapshot generation to include normalized lifecycle events if not already enough.
- Modify: `src-ui/model/snapshot.ts`
- Create/modify: `src-ui/components` or `src-ui/scene/MissionBoard.tsx`

**UI states:**
- Intake created
- CEO planning
- Recruiting roles
- Task cards assigned
- Roles executing
- Reports submitted
- QA/verifying
- Final report complete

**Verification:**
```bash
bash tests/workspace_visual_scene.sh
npm run build
```

**Expected:** PASS.

### Task 11: Native/manual evidence refresh

**Objective:** Re-prove the UI after adding controlled action surface.

**Commands:**
```bash
bash tests/workspace_desktop_app.sh
bash tests/workspace_desktop_no_write.sh
bash tests/workspace_security_redaction.sh
bash tests/workspace_p05.sh
bash tests/smoke.sh
npm run build
cargo test --manifest-path src-tauri/Cargo.toml
npm run tauri:build
bash tests/workspace_package_artifacts.sh
```

Then run native screenshot evidence harness with current job id and releaseProof assertion.

**Expected:** all PASS, native manifest `releaseProof=true`, 12/12 captured.

---

## 5. AgentDock team work orders

### orchestrator

Mission: coordinate implementation, keep lifecycle current, ensure selected reports are submitted, and finish only after QA GO.

Acceptance:
- TEAM.md and LIFECYCLE.md current.
- Task cards written for developer, system-architect, ux-designer, agentdock-qa, delivery-planner.
- Final report aggregates all role reports.

### system-architect

Mission: approve controlled-action boundary.

Acceptance:
- Confirms no arbitrary shell/write bridge.
- Confirms only `workspace_snapshot` and `agentdock_job_create` are exposed.
- Confirms `write_bridge_enabled=false` remains semantically true.
- Confirms future recruit/send/finish actions are separate scope.

### developer

Mission: implement Rust bridge, UI composer, snapshot metadata, tests.

Acceptance:
- RED/GREEN evidence for Rust helper tests.
- `agentdock_job_create` works through Tauri command.
- UI composer creates a job and refreshes snapshot.
- Existing release matrix passes after changes.

### ux-designer

Mission: make the task submission flow obvious and safe.

Acceptance:
- User can identify where to give CEO work in under 10 seconds.
- Success/failure states are clear.
- Controlled-action trust copy is visible.
- Composer placement does not confuse read-only monitoring surfaces.

### agentdock-qa

Mission: verify behavior and release gates.

Acceptance:
- Fake-agentdock bridge test passes.
- Real local manual test creates a new job from UI or documented Tauri path.
- Snapshot refresh shows new active job.
- Full matrix passes.
- Native evidence is refreshed after UI change.

### delivery-planner

Mission: track remaining work through commit and release.

Acceptance:
- Existing uncommitted Visual Workspace work is split into logical commits.
- Controlled-action feature commits are separated from prior read-only release work.
- Release notes clearly say this version supports `create CEO-led job from app`, not full recruit/send/finish controls.

---

## 6. Consolidated checklist

### A. Existing remaining work before new feature

- [ ] Review current uncommitted worktree.
- [ ] Commit existing read-only Visual Workspace release work in logical splits.
- [ ] Preserve current green release evidence paths.
- [ ] Confirm no generated build outputs are staged.
- [ ] Confirm `.gitignore` excludes `node_modules/`, `dist/`, `src-tauri/target/`.

### B. Controlled action backend

- [ ] Contract doc written.
- [ ] Rust RED tests added and observed failing.
- [ ] Job request validation implemented.
- [ ] Command args builder implemented without shell.
- [ ] Job id/path parsing implemented.
- [ ] `agentdock_job_create` Tauri command added.
- [ ] Handler exposes only `workspace_snapshot` + `agentdock_job_create`.
- [ ] Invalid project fails closed.
- [ ] Empty/overlong request fails closed.
- [ ] Output redaction verified.

### C. Controlled action UI

- [ ] `CeoTaskComposer` created.
- [ ] Empty request disabled.
- [ ] In-flight state shown.
- [ ] Success shows job id/path.
- [ ] Failure shows redacted error.
- [ ] Success triggers snapshot refresh.
- [ ] Trust copy says controlled job-create only.
- [ ] UI does not imply recruit/send/finish buttons exist.

### D. Snapshot/facilitation visibility

- [ ] Snapshot exposes allowed action metadata.
- [ ] Top HUD distinguishes read-only monitoring from controlled job creation.
- [ ] Mission board shows current lifecycle phase.
- [ ] Timeline or status panel shows CEO facilitation progress.
- [ ] Roles show selected/bench/reported/missing report states after CEO assigns tasks.

### E. Tests and release gates

- [ ] `cargo test --manifest-path src-tauri/Cargo.toml` PASS.
- [ ] `cargo check --manifest-path src-tauri/Cargo.toml` PASS.
- [ ] `npm run build` PASS.
- [ ] `bash tests/workspace_desktop_app.sh` PASS.
- [ ] `bash tests/workspace_desktop_no_write.sh` PASS with updated controlled-action contract.
- [ ] `bash tests/workspace_security_redaction.sh` PASS.
- [ ] `bash tests/workspace_p05.sh` PASS.
- [ ] `bash tests/smoke.sh` PASS.
- [ ] `npm run tauri:build` PASS.
- [ ] `bash tests/workspace_package_artifacts.sh` PASS.
- [ ] Native screenshot manifest refreshed and `releaseProof=true`.

### F. Manual acceptance

- [ ] Open app.
- [ ] Type a CEO task.
- [ ] Submit.
- [ ] See created job id.
- [ ] Confirm `.agent-work/07_JOBS/CURRENT.md` points to the new job.
- [ ] Confirm CEO/orchestrator receives inbox/job intake.
- [ ] Confirm app refresh shows new active job.
- [ ] Confirm CEO recruits/assigns through normal AgentDock workflow.
- [ ] Confirm app shows role/task/report progress.

### G. Commit/release

- [ ] Commit existing read-only Visual Workspace work first.
- [ ] Commit controlled-action backend separately.
- [ ] Commit UI composer separately.
- [ ] Commit tests/docs separately if needed.
- [ ] Write release note with exact supported action.
- [ ] Keep `recruit/send/finish from UI` in future backlog unless separately approved.

---

## 7. Recommended execution order

1. Commit/review existing green read-only Visual Workspace release work.
2. Create a new AgentDock job for `Visual Workspace CEO Action Surface`.
3. Assign architect/developer/UX/QA/delivery roles.
4. Implement backend helper tests first.
5. Implement Tauri command.
6. Update safety/no-write gate.
7. Implement UI composer.
8. Add/refresh facilitation timeline.
9. Run full matrix and native evidence.
10. Manual app test.
11. Commit split and final AgentDock job finish.

---

## 8. Safe claim wording after implementation

Allowed only after all gates pass:

"Visual Workspace now supports a controlled `Send to CEO` action that creates a CEO-led AgentDock job from the desktop app, then returns to snapshot-based monitoring for CEO facilitation, role recruitment, task assignment, reports, blockers, and final readiness. The app still does not expose arbitrary shell/write controls."

Not allowed until future scope:

- "The app can manage every AgentDock action."
- "The app can recruit/send/finish directly."
- "Full write bridge enabled."
- "Arbitrary command execution from UI."
