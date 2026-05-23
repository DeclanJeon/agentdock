# Agency Agents Integration Design (CLI-only)

AgentDock uses a curated subset of agency-style specialist templates as Hermes role prompts. Templates support CEO team selection, but they must not cause role explosion.

## Rules

- Prefer existing/running roles before recruiting.
- Recruit agency roles only when their capability matches a concrete task lane.
- Keep simple jobs solo.
- Store selected/rejected rationale in `ORCHESTRATION.json`.
- Surface role metadata through CLI snapshots and task/report files.

## Included Role Families

- Product/planning
- Engineering/architecture
- QA/review
- Research/analysis
- Delivery/documentation
