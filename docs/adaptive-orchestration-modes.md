# Adaptive Orchestration Modes

AgentDock uses the smallest coordination structure that can safely complete a job.

| Mode | Meaning | Team behavior | Finish gates |
|---|---|---|---|
| `solo_direct` | Small/read-only/docs/copy work. | No specialist team by default. | No separate QA gate unless the CEO adds one. |
| `assisted_single_lane` | Focused implementation where one specialist may help. | Reuse at most one suitable configured role. | QA optional unless risk policy requires it. |
| `standard_team` | Multi-capability/user-visible/code work. | Reuse a small configured team, capped by `team_cap`; recruit only missing capabilities. | QA/review required when code or user-facing behavior changes. |
| `tft_required` | Escalation state for cross-role blockers, conflicts, or failed QA. | Temporary TFT artifact with goal, members, status, and exit condition. | Blocking TFTs must close before finish. |
| `critical_review` | Security, permissions, deployment, destructive, or broad runtime risk. | Review/security/QA lanes required when available. | Required review/QA gates must pass; authority warnings are recorded. |

Simple jobs should not look broken just because no team exists. A missing team is valid when the mode says the coordination overhead would exceed the work.

`agentdock intake` uses the same mode classifier as `agentdock job`; it is the preferred direct-Hermes-pane entrypoint when no unfinished job is active. Completed jobs are tracked through `LAST_FINISHED.md`, not treated as active `CURRENT.md` work.
