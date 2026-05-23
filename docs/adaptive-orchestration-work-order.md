# Adaptive CEO Orchestration Work Order

Status: Ready for implementation planning  
Last refreshed: 2026-05-23  
Related design: `docs/adaptive-orchestration-design.md`

## Objective

Implement adaptive CEO orchestration so `adock job` chooses the lightest safe coordination mode: no unnecessary team for simple work, focused roles for standard work, TFT/meeting only when needed, and QA/review gates only when policy requires them.

## Non-goals

- Do not auto-create large teams for every request.
- Do not run arbitrary shell commands from UI/Tauri.
- Do not allow external agency prompts to override AgentDock safety rules.
- Do not require meeting/TFT artifacts for simple tasks.
- Do not block docs-only or tiny changes behind heavy QA bureaucracy.

## Implementation slices

### Slice 1 — Orchestration schema and artifact writer

Files likely touched:
- `bin/agentdock`
- `src-ui/model/snapshot.ts`
- `docs/workspace-snapshot-ui-contract.md`
- tests under `tests/fixtures/workspace/`

Tasks:
1. Add `ORCHESTRATION.json` generation to `cmd_job_start`.
2. Define `agentdock.orchestration.v1` fields:
   - `mode`
   - `complexity`
   - `risk`
   - `intents`
   - `requires_qa`
   - `requires_security_review`
   - `team_cap`
   - `reason`
3. Add a simple deterministic classifier in Bash or Python helper.
4. Emit orchestration metadata in `workspace_snapshot_json` as optional `orchestration`.
5. Update TypeScript snapshot model.
6. Add fixture validation for optional orchestration payload.

Acceptance criteria:
- `adock job "fix typo"` creates `ORCHESTRATION.json` with `mode=solo_direct` or `assisted_single_lane`.
- `adock job "build responsive UI with Tauri bridge and tests"` selects `standard_team`.
- Snapshot remains valid when orchestration is absent.

### Slice 2 — Anti-over-orchestration team planner

Files likely touched:
- `bin/agentdock`
- `.agentdock/agency/registry.json`
- `docs/agency-agents-integration-design.md`

Tasks:
1. Add team-cap policy per mode.
2. Add `distinct_output` rule to team recommendations.
3. Record rejected role suggestions with reasons.
4. Reuse configured/running roles before recruit recommendations.
5. Update `TEAM.md` generation to include:
   - selected roles,
   - rejected suggestions,
   - mode reason,
   - team cap.

Acceptance criteria:
- Simple jobs do not recommend 3+ roles.
- Standard jobs recommend only capabilities with distinct outputs.
- TEAM.md explains why roles were or were not selected.

### Slice 3 — Task dispatch contract

Files likely touched:
- `bin/agentdock`
- `src-tauri/src/lib.rs`
- `src-ui/components/InterventionPanel.tsx`

Tasks:
1. Ensure every selected non-CEO role has a task card.
2. Add required fields to task cards:
   - owner,
   - mission,
   - inputs,
   - dependencies,
   - acceptance criteria,
   - required report command.
3. Keep direct task mutation disabled from UI initially.
4. Continue using proposal-only task changes for safety.

Acceptance criteria:
- Selected role without task card is flagged in snapshot warnings.
- Task cards include report command and acceptance criteria.

### Slice 4 — Adaptive QA gate

Files likely touched:
- `bin/agentdock`
- `src-ui/model/timeline.ts`
- `src-ui/components/FinalReadinessPanel.tsx`
- `src-ui/scene/FinalGateScene.tsx`

Tasks:
1. Generate `QA.md` only when policy requires QA.
2. Add `requires_qa` and `qa_status` to snapshot.
3. Update `job finish` to block when `requires_qa=true` and QA is not passed.
4. Add policy:
   - docs-only/simple: no separate QA role required,
   - code/user-visible: QA or reviewer required,
   - shell/security/permissions: security review required.
5. Show QA requirement and status in UI.

Acceptance criteria:
- Simple job can finish without QA.md.
- User-visible code job cannot finish until required QA report/status exists.
- Finish failure message names the missing QA gate.

### Slice 5 — Dependency and blocker model

Files likely touched:
- `bin/agentdock`
- `src-ui/model/snapshot.ts`
- `src-ui/components/TeamActivityPanel.tsx`
- `src-ui/scene/SceneInspector.tsx`

Tasks:
1. Add optional `DEPENDENCIES.json`.
2. Detect dependency hints from task cards and reports.
3. Snapshot exposes role dependencies.
4. UI shows role blocked-by / waiting-on relationships.

Acceptance criteria:
- A role report containing blocker/dependency creates visible blocker context.
- UI can show “waiting on <role>” without raw file hunting.

### Slice 6 — TFT artifact engine

Files likely touched:
- `bin/agentdock`
- `src-ui/model/snapshot.ts`
- `src-ui/components/InterventionPanel.tsx`
- `src-ui/components/TeamActivityPanel.tsx`

Tasks:
1. Add `adock tft create` or `adock job tft create` command.
2. Store TFT files under `JOB/TFTS/`.
3. Extend snapshot `tfts[]` to read real TFT files first, legacy `TEAM.md` lines second.
4. Add TFT status: `proposed`, `active`, `blocked`, `closed`.
5. UI displays TFT members, goal, exit condition.
6. Initially require CEO/user controlled action to create TFT; do not auto-create silently.

Acceptance criteria:
- A TFT can be created without recruiting unrelated roles.
- Active TFT appears in snapshot/UI.
- Closed TFT no longer blocks finish unless marked blocking.

### Slice 7 — Meeting/debate artifacts

Files likely touched:
- `bin/agentdock`
- UI inspector or new panel later

Tasks:
1. Add `JOB/MEETINGS/` artifact template.
2. Add command candidate:
   - `adock meeting start`
   - `adock meeting conclude`
3. Keep meeting creation policy strict.
4. Record proposals, decision, rejected alternatives, action items.

Acceptance criteria:
- Meetings are not created for normal status updates.
- A concluded meeting produces a decision artifact visible in job history or inspector.

### Slice 8 — CEO tick loop

Files likely touched:
- `bin/agentdock`
- `src-tauri/src/lib.rs` later if UI action exposed

Tasks:
1. Add `adock job tick` read/plan/apply next-step command.
2. `tick` inspects orchestration, team, tasks, reports, blockers, QA, TFTs.
3. `tick` suggests the next smallest safe action.
4. Optional `--apply` can perform safe controlled actions.
5. No bulk recruit from `tick` unless policy and cap allow it.

Acceptance criteria:
- On simple job, `tick` does not create a team.
- On blocked standard job, `tick` suggests follow-up/TFT instead of random recruitment.
- On ready job, `tick` suggests finish.

### Slice 9 — UI visibility

Files likely touched:
- `src-ui/App.tsx`
- `src-ui/components/*`
- `src-ui/scene/*`
- `src-ui/styles.css`

Tasks:
1. Show orchestration mode and reason.
2. Show “simple job: no team needed” explicitly.
3. Show team cap and selected/rejected roles.
4. Show QA gate only when relevant.
5. Show TFTs as temporary focused teams, not permanent departments.
6. Keep UI compact and responsive.

Acceptance criteria:
- User can tell why a team was or was not created.
- Simple jobs do not look broken just because no team exists.
- QA/TFT panels are hidden or collapsed when not relevant.

## Test plan

Required automated checks:

```bash
bash -n bin/agentdock
python3 tests/fixtures/workspace/validate_workspace_fixtures.py
bash tests/workspace_desktop_no_write.sh
bash tests/workspace_job_create_bridge.sh
cargo test --manifest-path src-tauri/Cargo.toml
npm run build
```

New tests to add:

- `tests/workspace_adaptive_orchestration.sh`
  - simple request => solo/assisted mode, no team explosion,
  - medium request => standard mode with capped roles,
  - security request => critical/review gate.
- `tests/workspace_qa_gate.sh`
  - finish allowed without QA for simple docs job,
  - finish blocked when QA required and absent,
  - finish allowed after QA passed.
- `tests/workspace_tft_artifacts.sh`
  - create TFT,
  - snapshot exposes TFT,
  - close TFT.

## Rollout strategy

1. Ship artifact/schema first without changing existing behavior heavily.
2. Add classifier in advisory mode.
3. Add finish gates only after fixtures/tests cover simple-vs-standard distinction.
4. Add TFT creation as controlled action before automatic TFT suggestions.
5. Add `job tick` last, once contracts are stable.

## Definition of done

- Simple jobs remain lightweight and do not create unnecessary teams.
- Standard jobs produce explainable team plans.
- QA is required only when policy says so, but then it is enforced.
- TFTs are temporary, visible, and goal-bound.
- UI explains orchestration decisions in user-friendly Korean.
- No broad write bridge or arbitrary shell is introduced.

## Gap-review additions

### Slice 10 — Communication and audit protocol

Files likely touched:
- `bin/agentdock`
- `src-ui/model/snapshot.ts`
- `src-ui/components/ActionAuditPanel.tsx`
- `src-ui/components/TeamActivityPanel.tsx`

Tasks:
1. Standardize cross-role message metadata: job id, sender, receiver, action, related artifact, expected output.
2. Persist controlled action audit entries into job artifacts, not only UI state.
3. Add handoff artifact template under `JOB/HANDOFFS/`.
4. Snapshot exposes recent communication/audit events in bounded form.

Acceptance criteria:
- A follow-up/broadcast/reassign/TFT action can be traced from UI to job artifact.
- Cross-role coordination is not lost in tmux chat only.

### Slice 11 — Budget, authority, and approval gates

Files likely touched:
- `bin/agentdock`
- `src-ui/components/InterventionPanel.tsx`

Tasks:
1. Add orchestration `budget` fields: `max_roles`, `max_tfts`, `max_meetings`, `expected_minutes`.
2. Block or require explicit reason when exceeding budget.
3. Add approval-required classification for destructive/security/production/dependency/model-global changes.
4. Show escalation reason in UI before applying high-risk actions.

Acceptance criteria:
- Simple jobs cannot silently expand into multi-role teams.
- Critical actions are not performed by `job tick --apply` without authority.

### Slice 12 — Locks and write ownership

Files likely touched:
- `bin/agentdock`
- task card generators
- `src-ui/scene/SceneInspector.tsx`

Tasks:
1. Add `write_scope` and `shared_files` sections to task cards.
2. Read `.agent-work/LOCKS.md` into warnings when conflicts are detected.
3. Add shared-file conflict warning to snapshot.
4. Require CEO coordination for overlapping write scopes.

Acceptance criteria:
- Two roles assigned to the same file produce a visible coordination warning.
- TFT reassignment updates handoff/write ownership records.

### Slice 13 — Recovery and fallback paths

Files likely touched:
- `bin/agentdock`
- snapshot alert generation
- UI blocker surfaces

Tasks:
1. Define stale/offline/missing-report/QA-fail recovery order.
2. Add `recovery_suggestion` to blocker alerts.
3. Make `job tick` suggest follow-up/reassign/TFT/recruit in that order.
4. Do not recruit backup before follow-up unless capability is missing.

Acceptance criteria:
- Stale role produces a suggested follow-up before new recruitment.
- QA failure that crosses roles suggests TFT, not immediate finish.

### Slice 14 — Runtime model audit

Files likely touched:
- `bin/agentdock`
- `src-ui/model/snapshot.ts`
- job creation artifact writer

Tasks:
1. Copy current Hermes model/provider/source into `ORCHESTRATION.json` when a job starts.
2. Include runtime model in final report metadata.
3. Keep backward compatibility when model settings are unavailable.

Acceptance criteria:
- Job history can show which model/provider was active for that job.
- UI model changes are auditable across job runs.

### Slice 15 — Legacy compatibility

Files likely touched:
- `bin/agentdock`
- fixture tests
- snapshot model

Tasks:
1. Define fallback mode for jobs without `ORCHESTRATION.json`.
2. Keep legacy `TEAM.md` TFT parser.
3. Ensure old jobs still appear in history.
4. Add fixture for legacy job without new artifacts.

Acceptance criteria:
- Existing jobs do not disappear or fail snapshot parsing after adaptive orchestration ships.
