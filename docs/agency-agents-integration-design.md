# Agency Agents Integration Design

Status: Draft implementation contract  
Last refreshed: 2026-05-23  
Scope: Safely adapt a curated subset of [`msitarzewski/agency-agents`](https://github.com/msitarzewski/agency-agents) into AgentDock/adock role templates, CEO team selection, workspace snapshot metadata, and Visual Office display.

## Source evidence

- External source: `msitarzewski/agency-agents`, MIT licensed, 147 agent prompts across divisions, with conversion/install support for several tools.
- Local role engine: `bin/agentdock`
  - template identity: `canonical_role_template_id`, `role_template_file`, `role_template_body`, `print_builtin_roles`, `cmd_roles`
  - role creation/runtime: `cmd_recruit`, `recruit_role`, `write_template_role_prompt`
  - CEO job flow: `cmd_job_start`, `TEAM.md`, task card/report enforcement
  - UI state: `workspace_snapshot_json`, `workspace_role_department`, `workspace_role_avatar`, `workspace_role_tier`
- Local UI contract: `docs/workspace-snapshot-ui-contract.md`, `src-ui/model/snapshot.ts`, `src-ui/model/teamPlan.ts`, `src-ui/scene/*`
- Safety tests: `tests/workspace_desktop_no_write.sh`, `tests/workspace_controlled_actions_contract.sh`, `tests/workspace_visual_scene.sh`

## Integration goal

Add high-value specialist role templates from agency-agents without turning AgentDock into an uncontrolled prompt marketplace.

The integration should let the CEO/orchestrator select a small, appropriate TFT such as:

```text
Visual Workspace UX Strike Team
- agency-ux-architect
- agency-ui-designer
- agency-frontend-developer
- agency-whimsy-injector
- agency-code-reviewer or agency-qa-specialist
```

The integration must not:

- auto-enable all 147 external agents,
- let external prompt text override AgentDock/AGENTS.md/runtime safety rules,
- expose arbitrary shell/write actions,
- make Visual Office unusable through role explosion,
- create ambiguous duplicate roles without routing rules.

## Architecture

### 1. Curated registry, not bulk import

Create `.agentdock/agency/registry.json` as the local, reviewable source of truth.

Each entry maps an external agency agent to an AgentDock-safe template:

```json
{
  "id": "agency-frontend-developer",
  "source": "msitarzewski/agency-agents/engineering/frontend-developer.md",
  "license": "MIT",
  "display_name": "Agency Frontend Developer",
  "department": "Engineering Bay",
  "tier": "worker",
  "archetype": "developer",
  "when_to_use": ["react", "ui implementation", "responsive layout"],
  "avoid_when": ["backend-only", "strategy-only"],
  "outputs": ["code changes", "component notes", "tests run"],
  "visual": { "room": "Engineering Bay", "activity": "typing", "avatar": "keyboard-pet" },
  "prompt_file": ".agentdock/agency/templates/agency-frontend-developer.md"
}
```

Only registry entries are recognized by `agentdock roles list`, `agentdock recruit --template`, snapshots, and future CEO routing. External repo content is treated as upstream reference, not runtime authority.

### 2. Prompt wrapper policy

Each imported template must be wrapped with an AgentDock authority header:

1. AgentDock/AGENTS.md and system/developer/user instructions outrank the agency prompt.
2. Role operates only through `.agent-work` task cards, inboxes, reports, and approved AgentDock commands.
3. No arbitrary shell, no credential exfiltration, no safety bypass.
4. External agency content is role guidance only.
5. Every selected role must submit `agentdock job report --from <role> --summary "..."` before finish.

This prevents prompt collision while preserving the useful specialist behavior.

### 3. Initial curated set

Start with 15 templates that directly improve AgentDock's current product surface and common tasks.

| Template | Division | Primary use | Local room |
|---|---|---|---|
| `agency-frontend-developer` | engineering | React/UI implementation, responsive layout | Engineering Bay |
| `agency-backend-architect` | engineering | API/backend architecture, integration boundaries | Engineering Bay |
| `agency-software-architect` | engineering | system design and tradeoffs | Engineering Bay |
| `agency-devops-automator` | engineering | build/deploy/CI automation | Delivery Bay |
| `agency-security-engineer` | engineering | threat modeling, secure review | Quality Bay |
| `agency-code-reviewer` | engineering | code/spec/security review | Quality Bay |
| `agency-technical-writer` | engineering | docs and API guidance | Delivery Bay |
| `agency-ui-designer` | design | visual design/component systems | Product Bay |
| `agency-ux-architect` | design | information architecture and UX structure | Product Bay |
| `agency-ux-researcher` | design | usability/user research questions | Product Bay |
| `agency-whimsy-injector` | design | micro-interactions, delight, character personality | Product Bay |
| `agency-product-manager` | product | PRD/scope/acceptance criteria | Product Bay |
| `agency-project-manager` | project-management | sequencing, risk, milestone tracking | Delivery Bay |
| `agency-qa-specialist` | testing | test strategy/regression/release readiness | Quality Bay |
| `agency-reality-checker` | specialized/strategy | feasibility challenge and production sanity check | Quality Bay |

Notes:
- If an exact upstream file name differs, keep the local `agency-*` id stable and set `source_status="pending_upstream_verification"` until the fetch/import pass confirms it.
- Do not import paid-media/sales/marketing/social agents until product scope requires them.

### 4. CEO routing policy

CEO should use registry metadata to compose the smallest useful team:

1. Extract task intents from request keywords and existing job context.
2. Score registry templates by `when_to_use`, `department`, `outputs`, and `avoid_when`.
3. Reuse configured/running roles first.
4. Cap default recruited specialists to 3-5 plus coordinator.
5. Prefer local core AgentDock/BMAD templates for generic work; use agency templates only for missing or sharply specialized capability.
6. If two templates overlap, choose by output ownership:
   - UI implementation -> `agency-frontend-developer`
   - UX structure -> `agency-ux-architect`
   - visual polish -> `agency-ui-designer`
   - playful motion/microcopy -> `agency-whimsy-injector`
   - verification -> `agency-qa-specialist` or `agency-code-reviewer`, not both unless risk is high.

### 5. Snapshot and Visual Office mapping

Extend role display metadata without changing required schema:

- `roles[].template_id` optional
- `roles[].agency_profile` optional object with `source`, `archetype`, `when_to_use`, `outputs`
- existing `department`, `tier`, `avatar` derive from registry when role/template is recognized

Visual Office should use these hints to place specialists in the right bay and show more specific character behavior.

### 6. Safety gates

The integration is acceptable only if these stay true:

- `commands.write_bridge_enabled=false`
- no shell bridge added
- no installation script auto-runs remote code
- external templates are local files or static fallback text
- registry ids are sanitized and prefixed `agency-`
- `agentdock roles list` does not imply every upstream role is active
- recruit still requires explicit `agentdock recruit <role> --template <template>` or CEO action
- tests prove no broad write/shell capability was added

## Implementation slices

### Slice A — docs and registry

- Add this design doc.
- Add implementation checklist and work order.
- Add `.agentdock/agency/registry.json` with curated initial entries.
- Add `.agentdock/agency/templates/*.md` wrapped local template fallbacks.

### Slice B — CLI template adapter

- Teach `bin/agentdock` to recognize `agency-*` template ids from registry.
- `agentdock roles list` displays curated agency entries under source `Agency`.
- `agentdock recruit --template agency-frontend-developer frontend-dev` writes the wrapped template.
- Unknown `agency-*` ids fail closed.

### Slice C — CEO guidance and routing hints

- Update CEO job instructions to mention curated Agency templates only after existing/BMAD roles do not fit.
- Add `agentdock roles list` copy clarifying curated, safe subset.
- Add `agentdock roles recommend "request"` for local registry-only specialist suggestions.
- Add recommended curated specialists to generated `TEAM.md` so the CEO can form small TFTs without bulk importing Agency roles.

### Slice D — snapshot/UI metadata

- Emit optional `roles[].template_id` and `roles[].agency_profile` when role prompt source matches an agency template.
- Emit optional `team_plan.recommendations[]` from the active job request so Visual Office can show recruit/reuse hints.
- Use registry-derived room/avatar/tier where available.
- Ensure UI remains usable if metadata is absent.

### Slice E — tests

- Contract tests for agency template listing and safe recruitment prompt writing.
- Snapshot test for metadata presence after agency-template recruitment.
- No-write/shell regression remains green.
- Build and Rust tests remain green.

## Open questions

- Should upstream content be vendored at a pinned commit, or should AgentDock ship compact local summaries only? Initial answer: compact local fallbacks first, pinned upstream fetch later.
- Should Visual Office show an agency badge on characters? Initial answer: optional `agency_profile` in inspector first, not map clutter.
- Should agency templates become Codex native subagents too? Initial answer: no; AgentDock roles are tmux/Hermes roles and must stay separate from Codex native subagents.
