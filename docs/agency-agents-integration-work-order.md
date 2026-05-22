# Agency Agents Integration Work Order

Status: Ready for implementation  
Owner: AgentDock implementation lane  
Design source: `docs/agency-agents-integration-design.md`

## Objective

Integrate a curated, safe subset of agency-agents into AgentDock as role templates and optional UI metadata, while preserving AgentDock's CEO-led, tmux/Hermes, task-card/report workflow.

## Non-negotiable constraints

- No bulk activation of all upstream agents.
- No remote script execution.
- No arbitrary shell/write bridge.
- External agency prompt text never outranks AgentDock/AGENTS.md/system/developer/user instructions.
- Every imported role id is prefixed `agency-`.
- Unknown agency template ids fail closed.
- Existing BMAD and AgentDock templates continue to work.

## Work breakdown

### Team 1 — Registry and prompt adapter

Files:
- `.agentdock/agency/registry.json`
- `.agentdock/agency/templates/*.md`
- `bin/agentdock`

Tasks:
- Create curated registry with 15 initial templates.
- Create local wrapped fallback prompt files.
- Add registry parser helpers in `bin/agentdock`.
- Extend `canonical_role_template_id`, `role_template_file`, `print_builtin_roles`, and template prompt writing for `agency-*` ids.

Acceptance:
- `agentdock roles list` shows Agency entries.
- `agentdock recruit demo-frontend --template agency-frontend-developer --skip-missing` creates `.agentdock/prompts/demo-frontend.md` with wrapper header.
- Unknown `agency-*` template fails.

### Team 2 — CEO guidance and job-flow hints

Files:
- `bin/agentdock`
- `.agentdock/prompts/orchestrator.md` if needed
- generated prompt behavior via `generate_role_prompt` / `write_template_role_prompt`

Tasks:
- Update CEO job instructions to mention curated agency templates as a specialist option.
- Keep reuse-first/small-team policy explicit.
- Add local `agentdock roles recommend "request"` hints for UI/UX/animation/QA/security/docs/etc. jobs.
- Add generated `TEAM.md` recommendation tables that the CEO can convert into small TFTs only when a capability is missing.

Acceptance:
- New job README/CEO task card mentions curated Agency templates without instructing bulk import.
- `agentdock roles recommend ... --json` returns only curated `agency-*` templates.
- Existing job/report/finish behavior unchanged.

### Team 3 — Snapshot/UI metadata

Files:
- `bin/agentdock`
- `src-ui/model/snapshot.ts`
- `src-ui/scene/SceneInspector.tsx` or role metadata display surface

Tasks:
- Emit optional `template_id` and `agency_profile` for roles using agency templates.
- Emit optional `team_plan.recommendations[]` for active job request-derived specialist hints.
- Use registry-derived department/tier/avatar for agency roles.
- Show agency profile in inspector without cluttering map.

Acceptance:
- Snapshot remains `workspace.snapshot.v1`.
- Missing metadata is harmless.
- Visual Office still builds and renders.

### Team 4 — Tests and docs

Files:
- `tests/workspace_agency_templates.sh`
- existing desktop/no-write tests as needed
- `docs/agency-agents-integration-checklist.md`

Tasks:
- Add regression tests for listing, recruitment prompt wrapper, unknown-id fail closed, snapshot metadata.
- Run build/test suite.

Acceptance:
- `bash tests/workspace_agency_templates.sh` passes.
- `bash tests/workspace_desktop_no_write.sh` passes.
- `npm run build` passes.
- `cargo test --manifest-path src-tauri/Cargo.toml` passes.

## Delivery report

Final implementation report must include:

- registry entries added,
- files changed,
- commands run,
- test evidence,
- remaining risks/open questions.
