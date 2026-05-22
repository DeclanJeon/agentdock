# Workspace Snapshot UI Contract

Status: initial 95% contract for the React + Tauri Visual Workspace.
Primary source of truth: `agentdock workspace snapshot --json` plus `.agent-work` files read by the CLI.
Runtime boundary: read-only desktop app. The UI and Tauri adapter must not expose a write bridge, arbitrary command bridge, job finish, report submission, recruit, inbox send, or file edit action in the 95% scope.

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
| `reports.required_selected_roles` | number | Required count among selected roles. | Report Desk |
| `reports.missing_roles` | string[] | Selected roles blocking finish by missing reports. | Report Desk / role chips |
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
| `commands.mode` | string | Must remain `read-only` for 95%. | Runtime/Server Room badge |
| `commands.write_bridge_enabled` | boolean | Must remain `false` for 95%. | Safety badge/release gate |
| `commands.allowed_read_commands` | string[] | Read-only command hints only. | Runtime details |
| `alerts` | array | Blocking/warning/notice conditions. | Blocker Desk |
| `warnings` | array | Non-blocking warnings. | Blocker Desk / Runtime details |

## Optional fields

| Path | Type | Purpose | Fallback |
|---|---:|---|---|
| `status_taxonomy` | object | Display names/descriptions for statuses. | Built-in status labels |
| `support` | object | Platform support matrix. | Hide platform matrix |
| `org` | object | Organization/zones metadata. | Derive rooms from role departments |
| `events` | array | Recent workspace events. | Empty activity rail |
| `locks` | object | Lockfile path/presence metadata. | Show lock status unknown |
| `roles[].display` | string | Human-friendly role label. | Title-case `id` |
| `roles[].status_reason` | string | Explanation for role status. | Generic status text |
| `roles[].pane_id` | string/null | tmux pane id. | Hide pane id |
| `roles[].logical_node` | string | Org graph node. | Use `department` |
| `roles[].logical_node_label` | string | Org graph label. | Use `department` |
| `roles[].tier` | string | Role tier. | Worker default |
| `roles[].manager_chain` | string[] | Manager/orchestrator path. | Empty chain |
| `roles[].avatar` | object | Avatar hint. | Default sprite |
| `roles[].source_paths` | string[] | Prompt/config source paths. | Hide source list |

## Canonical fields vs UI-derived fields

Canonical fields are emitted by the CLI snapshot and must be treated as source of truth:
- `schema_version`, `generated_at`
- `project.*`
- `job.*`
- `reports.*`
- `roles[]` identity, status, selected/configured/running/report/task fields
- `alerts`, `warnings`
- `commands.mode`, `commands.write_bridge_enabled`, `commands.allowed_read_commands`
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
- Fixture `commands.mode` must be `read-only`.
- Fixture `commands.write_bridge_enabled` must be `false`.
- Fixture `allowed_read_commands` must not advertise finish/report/send/recruit/edit/exec actions.
