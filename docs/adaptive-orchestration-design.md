# Adaptive Orchestration Design (CLI-only)

AgentDock routes every `adock job "..."` through the CEO Hermes role. The CEO chooses the smallest useful execution shape instead of always creating a team.

Direct user work given to a live coordinator Hermes tmux pane after a prior job finishes uses the same classifier through `agentdock intake --from <role> --request "..."` (`adock-delegate` / `agentdock delegate` remain compatibility aliases). Finished jobs are historical: `CURRENT.md` is cleared on finish, and `LAST_FINISHED.md` stores the most recent completed job/final-report pointer.

## Modes

| Mode | When to use | Behavior |
| --- | --- | --- |
| `solo` | Simple, low-risk tasks | CEO executes or delegates to one existing role only if clearly useful. |
| `focused` | One specialist improves outcome | Reuse/recruit at most one helper and require a report. |
| `standard_team` | Multiple parallel lanes or review needed | Small capped team with task cards, role reports, and CEO synthesis. |
| `critical` | High-risk, broad, security/release-sensitive | Explicit QA/review gates, blockers/TFT records, and final report evidence. |

## Runtime Artifacts

- `ORCHESTRATION.json` records mode, complexity, selected/rejected roles, QA/security policy, gates, runtime model, and worktree hints.
- `TASKS/<role>.md` stores each selected role's bounded assignment.
- `REPORTS/*.md` stores role reports used for finalization.
- `TFTS/*.md` and `MEETINGS/*.md` store cross-role blockers and decisions only when needed.
- `.agent-work/15_STATUS/*.json` stores lightweight live role summaries for CLI snapshots.

## UX Boundary

The supported interface is the terminal. `workspace snapshot/export` are read-only diagnostics, not a second control plane.
