# Visual Workspace controlled actions

The Visual Workspace remains snapshot-first. `.agent-work` is still the source of truth and `write_bridge_enabled` stays `false` because there is no broad write bridge.

## Allowed in the first CEO Action Surface slice

- `workspace_snapshot`: read current workspace state through `agentdock workspace snapshot --json`.
- `agentdock_job_create`: create one CEO-led job by running AgentDock without a shell as argv:
  - `agentdock`
  - `job`
  - `--no-attach`
  - `<request>`

The UI labels this as `Send to CEO` and refreshes the snapshot after success so the new job state comes from AgentDock, not local UI cache.

## Forbidden in this slice

The desktop bridge and UI must not expose:

- arbitrary shell or command execution;
- broad write bridge semantics;
- direct `.agent-work` or `.agentdock` file mutation;
- recruit, send, broadcast, finish, report, or task-card editing controls;
- OpenAPI expansion.

## Evidence requirements

- Rust tests prove request validation, exact no-shell argv construction, job id/path parsing, fake-agentdock argv behavior, and redaction.
- `tests/workspace_desktop_no_write.sh` allows only `workspace_snapshot` and `agentdock_job_create` and keeps `write_bridge_enabled=false`.
- `tests/workspace_job_create_bridge.sh` runs the fake-agentdock bridge regression.
- QA/native evidence must be refreshed after final UI and bridge changes before a release-ready claim.
