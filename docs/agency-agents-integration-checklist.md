# Agency Agents Integration Checklist

## Design and safety

- [x] External source reviewed from GitHub.
- [x] Integration strategy avoids bulk import.
- [x] Prompt authority wrapper defined.
- [x] Curated initial template list defined.
- [x] CEO routing policy defined.
- [x] Snapshot/UI optional metadata policy defined.

## Registry

- [x] `.agentdock/agency/registry.json` exists.
- [x] Registry contains only curated `agency-*` ids.
- [x] Registry entries include source, license, display, department, tier, archetype, when_to_use, outputs, visual, prompt_file.
- [x] Unknown `agency-*` templates fail closed.

## Templates

- [x] Wrapped fallback templates exist under `.agentdock/agency/templates/`.
- [x] Every template states AgentDock authority and report requirements.
- [x] No template instructs remote install, shell bypass, credential handling, or safety override.

## CLI adapter

- [x] `agentdock roles list` shows Agency templates.
- [x] `agentdock roles recommend "request"` returns local curated Agency suggestions.
- [x] `agentdock recruit --template agency-*` works for curated ids.
- [x] Existing BMAD/AgentDock template behavior still works.
- [x] CEO job text recommends curated Agency specialists only when useful.
- [x] Generated `TEAM.md` includes a recommendation table for missing specialist/TFT formation.

## Snapshot/UI

- [x] Snapshot emits optional `template_id` for agency roles.
- [x] Snapshot emits optional `agency_profile` for agency roles.
- [x] Snapshot emits optional `team_plan.recommendations[]` for active jobs.
- [x] Registry-derived department/tier/avatar are reflected.
- [x] UI handles missing metadata safely.
- [x] UI team plan can prefer snapshot-provided Agency recommendations over local heuristics.

## Tests

- [x] `tests/workspace_agency_templates.sh` exists.
- [x] Agency listing test passes.
- [x] Agency recommendation command test passes.
- [x] Agency recruitment wrapper test passes.
- [x] Unknown agency id fail-closed test passes.
- [x] Snapshot metadata test passes.
- [x] Existing no-write/shell tests pass.
- [x] Build and Rust tests pass.
