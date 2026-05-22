# Workspace Snapshot UI Contract

Status: controlled-actions contract for the React + Tauri Visual Workspace.
Primary source of truth: `agentdock workspace snapshot --json` plus `.agent-work` files read by the CLI.
Runtime boundary: controlled desktop app. The UI and Tauri adapter must not expose arbitrary shell, broad file write, direct task-file mutation, or an unrestricted command bridge. Allowed actions are fixed-argv AgentDock operations advertised by `commands.allowed_actions` and implemented one slice at a time.

## Schema identity

Supported schema: `workspace.snapshot.v1`.

Unsupported schema behavior:
- Do not guess fields from unknown schemas.
- Show a recoverable UI error with the observed schema value.
- Preserve the last good snapshot if one exists.
- Do not mutate `.agent-work` or `.agentdock` while handling the error.

Backward compatibility rule:
- New snapshot fields are optional by default.
- Existing optional fields may be absent; UI must render safe fallback text.
- Required fields below are the minimum contract for 95% UI fixtures and release gates.

## Required fields

| Path | Type | Purpose | UI surface |
|---|---:|---|---|
| `schema_version` | string | Snapshot contract identifier. Must be `workspace.snapshot.v1`. | Adapter/schema guard |
| `generated_at` | string | Snapshot generation timestamp. | Live/stale HUD |
| `project.name` | string | Human-readable project name. | Top HUD |
| `project.root` | string | Canonical project root from CLI. | Runtime/Server Room details |
| `project.session` | string | AgentDock/tmux session identifier. | Runtime details |
| `project.session_name` | string | Backward-compatible session label. | Runtime details |
| `job.id` | string | Active job id. | CEO Office / Mission Wall |
| `job.path` | string | Active job directory. | Inspector/details |
| `job.readme_path` | string | Active job README path. | Inspector/details |
| `job.lifecycle` | string | Lifecycle phase. | Mission Wall |
| `job.lifecycle_status` | string | Backward-compatible lifecycle status. | Mission Wall |
| `job.final_ready` | boolean | Whether orchestrator can finish from report/readiness standpoint. | FinalReadinessPanel |
| `job.final_ready_reason` | string | Human-readable ready/blocking reason. | FinalReadinessPanel |
| `reports.submitted` | number | Submitted report count. | Report Desk |
| `reports.required` | number | Required report count. | Report Desk |
| `reports.submitted_selected_roles` | number | Submitted count among selected roles. | Report Desk |
| `reports.required_selected_roles` | number | Required count among selected non-coordinator worker roles. | Report Desk |
| `reports.selected_roles` | number | Total selected task roles including coordinator. | Team plan/diagnostics |
| `reports.missing_roles` | string[] | Selected non-coordinator worker roles blocking finish by missing reports. | Report Desk / role chips |
| `roles[].id` | string | Role id used by UI selection. | Room/role lookup |
| `roles[].role_id` | string | Backward-compatible role id alias. | Role lookup fallback |
| `roles[].department` | string | Department/room grouping. | Office room placement |
| `roles[].status` | string | Operator status (`assigned`, `working`, `reported`, `blocked`, `online`, etc.). | Role badge/avatar |
| `roles[].selected` | boolean | Whether role belongs to current active job team. | Filtering/report required logic |
| `roles[].configured` | boolean | Whether role prompt/config exists. | Inspector/runtime status |
| `roles[].running_pane` | boolean | Whether a tmux pane is running for the role. | Runtime status |
| `roles[].task_path` | string/null | Role task-card path if assigned. | Inspector |
| `roles[].latest_report_path` | string/null | Latest report path if submitted. | Inspector / Report Desk |
| `layout.role_count` | number | Number of roles in snapshot. | Density logic |
| `layout.density` | string | Snapshot-provided density (`normal`, `dense`, `crowded`). | Dense/compact controls |
| `layout.density_thresholds` | object | Threshold hints used by UI. | Dense/compact controls |
| `commands.mode` | string | `controlled-actions` when fixed-argv UI actions are available; `read-only` only for static fixture/demo modes. | Runtime/Server Room badge |
| `commands.write_bridge_enabled` | boolean | Must remain `false`; no broad write bridge is allowed. | Safety badge/release gate |
| `commands.allowed_read_commands` | string[] | Read-only command hints. | Runtime details |
| `commands.allowed_actions` | string[] | Fixed-argv controlled action hints, never shell strings to execute directly. | Intervention console |
| `alerts` | array | Blocking/warning/notice conditions. | Blocker Desk |
| `warnings` | array | Non-blocking warnings. | Blocker Desk / Runtime details |

## Optional fields

| Path | Type | Purpose | Fallback |
|---|---:|---|---|
| `status_taxonomy` | object | Display names/descriptions for statuses. | Built-in status labels |
| `support` | object | Platform support matrix. | Hide platform matrix |
| `org` | object | Organization/zones metadata. | Derive rooms from role departments |
| `events` | array | Recent workspace events. | Empty activity rail |
| `team_plan` | object | Coordinator, selected roles, report policy, and team-planning hints. | Intervention console / inspector |
| `team_plan.recommendations[]` | array | Optional curated Agency specialist hints derived from the active job request; UI should treat them as suggestions, not recruited roles. | Fall back to UI-local heuristic recommendations |
| `tfts` | array | Temporary focused teams discovered from `TEAM.md` or planner output. | Intervention console / team view |
| `history` | object | Bounded read-only recent job summaries; must not mutate `CURRENT.md`. | JobHistoryPanel |
| `locks` | object | Lockfile path/presence metadata. | Show lock status unknown |
| `roles[].display` | string | Human-friendly role label. | Title-case `id` |
| `roles[].status_reason` | string | Explanation for role status. | Generic status text |
| `roles[].pane_id` | string/null | tmux pane id. | Hide pane id |
| `roles[].logical_node` | string | Org graph node. | Use `department` |
| `roles[].logical_node_label` | string | Org graph label. | Use `department` |
| `roles[].tier` | string | Role tier. | Worker default |
| `roles[].manager_chain` | string[] | Manager/orchestrator path. | Empty chain |
| `roles[].avatar` | object | Avatar hint. | Default sprite |
| `roles[].template_id` | string | Role template id when known, including curated `agency-*` templates. | Hide template badge |
| `roles[].agency_profile` | object | Optional registry metadata for curated Agency roles. | Hide Agency detail card |
| `roles[].source_paths` | string[] | Prompt/config source paths. | Hide source list |

## Canonical fields vs UI-derived fields

Canonical fields are emitted by the CLI snapshot and must be treated as source of truth:
- `schema_version`, `generated_at`
- `project.*`
- `job.*`
- `reports.*`
- `roles[]` identity, status, selected/configured/running/report/task fields
- `alerts`, `warnings`
- `commands.mode`, `commands.write_bridge_enabled`, `commands.allowed_read_commands`, `commands.allowed_actions`
- `layout.role_count`, `layout.density`, `layout.density_thresholds`

UI-derived fields may be computed by React from canonical fields and fixtures:
- Room summaries: role count, missing count, blocked count by `department`.
- Display labels from `roles[].display` or title-cased `roles[].id` fallback.
- Status severity grouping from `roles[].status`, `alerts[].severity`, and missing report membership.
- Dense/compact visual mode from `layout.density` plus actual role count.
- Final CTA wording from `job.final_ready` and `job.final_ready_reason`.
- Live/stale/demo/error mode from adapter result, snapshot age, last-good state, and schema support.

Derived fields must never override canonical readiness/report data. If canonical fields are contradictory, the UI should show a contract warning rather than silently repair the data.

## Fixture strategy

Fixtures live under `tests/fixtures/workspace/` and are validated by:

```bash
python3 tests/fixtures/workspace/validate_workspace_fixtures.py
```

The desktop regression script also runs the fixture validator:

```bash
bash tests/workspace_desktop_app.sh
```

Required fixture set:
- `active-normal.json`: active job with normal density and no missing-report blocker.
- `missing-reports.json`: active job blocked by missing selected-role reports.
- `final-ready.json`: selected roles reported and `job.final_ready=true`.
- `dense-50-roles.json`: exactly 50 roles for dense/crowded UI validation.

Fixture safety rules:
- Fixtures are static JSON; validation does not shell out or mutate project state.
- Static read-only fixtures may use `commands.mode=read-only`; live controlled fixtures use `commands.mode=controlled-actions`.
- Fixture `commands.write_bridge_enabled` must be `false`.
- `allowed_read_commands` must not advertise finish/report/send/recruit/edit/exec actions.
- `allowed_actions` may advertise only fixed AgentDock argv slices such as job create, coordinator send, selected broadcast, selected-role send, recruit, role report submit, and finish gate.
