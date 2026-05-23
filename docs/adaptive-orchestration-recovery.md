# Adaptive Orchestration Recovery Orders

Use these recovery orders before expanding a team. The CEO should prefer follow-up and handoff clarity before recruiting backups.

## Stale role
1. Send a focused follow-up with the task-card path and requested report command.
2. Check whether the role has a blocker/dependency in its latest report.
3. If the same capability exists in another configured role, reassign only after recording the reason in `TEAM.md` or `LIFECYCLE.md`.
4. Recruit only when no configured/running role can cover the capability within the orchestration cap.

## Offline pane
1. Keep the job artifact as the source of truth; do not rely only on tmux chat.
2. Send an inbox message; if pane state is missing, restart/recruit the same role name when safe.
3. Preserve existing task/report paths so final aggregation remains recoverable.

## Missing report
1. Ask the selected role to run `agentdock job report --from <role> --summary "..."`.
2. If the role is blocked, record `blocked by <role>` or create a bounded TFT only for cross-role blockers.
3. If work is actually out of scope, remove or update the role selection with a reason.

## QA failure
1. Keep `QA.md` failed until evidence proves the fix.
2. Assign the owning implementation role to fix the failure.
3. Create a blocking TFT only when the fix crosses role boundaries.
4. Require a new passing QA/review report before `job finish`.
