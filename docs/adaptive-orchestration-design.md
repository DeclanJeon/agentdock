# Adaptive CEO Orchestration Design

Status: Draft implementation contract  
Last refreshed: 2026-05-23  
Scope: AgentDock/adock job flow that scales from simple solo execution to CEO-led multi-team/TFT work without over-orchestrating small tasks.

## 1. Problem

AgentDock currently has the foundation for CEO-led jobs: job artifacts, role recruitment, task cards, reports, controlled UI actions, and final report gating. However, much of the “CEO analyzes the work, forms teams, coordinates TFTs, runs QA, and finalizes” behavior still depends on prompt compliance.

The target product behavior is:

- Simple work should stay simple.
- Complex work should get a real team.
- Risky/user-facing work should get QA/review.
- Blocked cross-functional work should be able to form temporary TFTs.
- Every significant decision should be observable in the UI and recoverable from job artifacts.

The design must avoid turning every request into a heavy “enterprise meeting” workflow.

## 2. Product principle

> AgentDock should use the smallest coordination structure that can safely complete the job.

This means the default is not “always create a team.” The default is:

1. classify the job,
2. choose the lightest valid execution mode,
3. add roles only when capability, risk, parallelism, or verification requires them,
4. escalate to TFT/meeting only when evidence shows cross-role coordination is needed.

## 3. Adaptive orchestration modes

### Mode A — `solo_direct`

Use for trivial or narrow tasks that one existing coordinator/worker can complete.

Examples:
- small text/copy change,
- one-file UI polish,
- simple config update,
- read-only explanation,
- small docs edit.

Behavior:
- No new team is recruited.
- CEO may execute directly or assign to one existing role.
- Minimal task card may be generated.
- QA is lightweight: build/test/check relevant to the touched area.
- Finish can happen after the single required report/check.

Hard caps:
- max selected workers: 0–1
- no TFT
- no meeting artifact unless blocker appears

### Mode B — `assisted_single_lane`

Use when one specialist is useful but a full team is unnecessary.

Examples:
- UI component implementation,
- isolated backend command addition,
- focused bug fix,
- test-only work.

Behavior:
- CEO + one specialist, preferably existing role reuse.
- One worker task card.
- QA can be self-verification or reviewer depending on risk.

Hard caps:
- max selected workers: 1
- QA optional unless policy requires it
- no TFT unless blocker/dependency detected

### Mode C — `standard_team`

Use when the work needs multiple capabilities or parallel lanes.

Examples:
- UI + backend bridge,
- CLI + Tauri + React feature,
- user-visible workflow change,
- non-trivial refactor,
- feature with docs/tests.

Behavior:
- CEO creates a small team plan.
- Reuse existing roles first.
- Recruit only missing capabilities.
- Task cards are required per selected role.
- QA/review gate required for code or user-facing behavior.

Hard caps:
- default selected workers: 2–4
- max selected workers without explicit escalation: 5
- at most one QA lane by default

### Mode D — `tft_required`

Use when execution reveals a cross-role blocker, dependency, conflict, or failed QA that cannot be solved by a single lane.

Examples:
- frontend blocked by backend contract,
- QA failure requiring developer + reviewer + UX decision,
- conflicting implementation proposals,
- security concern requiring architecture input.

Behavior:
- CEO creates a temporary focused team artifact.
- Only directly relevant members join.
- TFT has a concrete goal, expected output, and expiration condition.
- Meeting/debate artifact is created only if a decision is needed.

Hard caps:
- TFT default members: 2–4
- TFT must have `goal`, `members`, `status`, `exit_condition`
- no permanent role expansion unless CEO records reason

### Mode E — `critical_review`

Use for high-risk, production-impacting, destructive, security-sensitive, or broad architectural work.

Examples:
- auth/security/credential changes,
- release/deploy automation,
- broad CLI execution changes,
- destructive file operations,
- changes that affect user data.

Behavior:
- CEO requires explicit review lanes.
- QA/security/reality-check gates may become mandatory.
- Finish is blocked until required gates pass.

Hard caps:
- require review policy in `ORCHESTRATION.json`
- require final risk summary
- no destructive action without existing project policy/user authority

## 4. Classification model

Each job gets an adaptive orchestration record:

```json
{
  "schema_version": "agentdock.orchestration.v1",
  "job_id": "JOB-...",
  "mode": "solo_direct",
  "complexity": "small",
  "risk": "low",
  "intents": ["ui", "docs"],
  "requires_code_change": true,
  "requires_user_visible_change": true,
  "requires_qa": false,
  "requires_security_review": false,
  "team_cap": 1,
  "reason": "Narrow one-component UI copy/layout adjustment; no backend or security impact."
}
```

Suggested file:

```text
.agent-work/07_JOBS/JOB-*/ORCHESTRATION.json
```

The CLI should generate a first draft deterministically from the request, then allow the CEO to update it with recorded reasons.

## 5. Intent and complexity heuristics

### Complexity signals

Small:
- one or two files likely affected,
- no cross-component dependency,
- no new runtime behavior,
- no user data/security impact.

Medium:
- multiple layers affected,
- UI + backend bridge,
- new user-visible workflow,
- tests required.

Large:
- architecture changes,
- multiple subsystems,
- ambiguous requirements,
- cross-team dependencies.

Critical:
- security, credentials, destructive commands, production deployment, data loss risk.

### Team creation triggers

Create or expand a team only when at least one is true:

- required capability is missing from current roles,
- work can safely run in parallel,
- independent review is required,
- risk policy requires QA/security/reviewer,
- blocker/dependency requires another specialist,
- user explicitly asks for team/TFT/meeting.

### Anti-over-orchestration rules

Do not recruit a team when:

- the job can be completed by the CEO or one existing role,
- the only reason is “more agents might be helpful,”
- the added role has no distinct output,
- the job is mostly read-only explanation,
- the task is smaller than the coordination overhead.

## 6. Artifacts by mode

| Artifact | solo_direct | assisted_single_lane | standard_team | tft_required | critical_review |
|---|---:|---:|---:|---:|---:|
| `README.md` | required | required | required | required | required |
| `ORCHESTRATION.json` | required | required | required | required | required |
| `TEAM.md` | minimal | minimal | required | required | required |
| `TASKS/*.md` | optional/minimal | required | required | required | required |
| `DEPENDENCIES.json` | optional | optional | recommended | required | required |
| `TFTS/*.md` | no | no | optional | required | optional/required |
| `MEETINGS/*.md` | no | no | optional | if decision needed | if decision needed |
| `QA.md` | optional | optional/policy | required for code/user-visible | required if QA involved | required |
| final report | required | required | required | required | required |

## 7. Team planning policy

Team planner should produce:

```json
{
  "mode": "standard_team",
  "selected_roles": [
    {
      "role": "frontend-dev",
      "template": "agency-frontend-developer",
      "source": "reuse|recruit",
      "mission": "Implement the UI slice.",
      "distinct_output": "code changes + tests"
    },
    {
      "role": "qa-specialist",
      "template": "agency-qa-specialist",
      "source": "recruit",
      "mission": "Verify acceptance criteria and regression risk.",
      "distinct_output": "QA report"
    }
  ],
  "rejected_roles": [
    {
      "template": "agency-project-manager",
      "reason": "Coordination overhead exceeds task size."
    }
  ]
}
```

Every selected role must have a distinct output. If it does not, it should not be selected.

## 8. QA gate policy

QA should be adaptive, not always heavy.

### No separate QA role required

Allowed for:
- docs-only changes,
- tiny copy changes,
- read-only analysis,
- simple one-file low-risk changes.

Required validation can be local command evidence only.

### QA/reviewer required

Required for:
- user-visible UI workflow changes,
- CLI/Tauri bridge changes,
- multi-file code changes,
- bug fixes with regression risk,
- final release candidate.

### Security/reality review required

Required for:
- shell/command execution,
- credentials/secrets,
- permissions/ACL,
- filesystem mutation boundaries,
- destructive operations.

`job finish` should check `QA.md` only when policy says QA is required.

## 9. TFT policy

A TFT is not a normal team. It is a temporary problem-solving structure.

Create a TFT when:
- blocker cannot be solved by current owner alone,
- two or more roles have conflicting outputs,
- QA fails and remediation crosses role boundaries,
- a decision needs input from multiple capabilities.

Suggested file:

```text
JOB/TFTS/tft-<slug>.md
```

Template:

```md
# TFT: <name>

Status: active
Created by: ceo-orchestrator
Reason: <why normal execution is insufficient>
Goal: <specific outcome>
Exit condition: <when this TFT ends>

## Members
- role-a
- role-b

## Required output
- decision, patch plan, or unblock report

## Log
- ...
```

TFT must be closed when the exit condition is met.

## 10. Meeting/debate policy

Meetings are expensive. Do not create meetings for normal status updates.

Create a meeting only when:
- there are competing proposals,
- a product/architecture tradeoff must be decided,
- QA/security rejects current output,
- CEO needs a recorded consensus before proceeding.

Suggested file:

```text
JOB/MEETINGS/<timestamp>-<topic>.md
```

Required sections:
- question,
- participants,
- proposals,
- decision,
- rejected alternatives,
- action items.

## 11. CEO facilitation loop

The CEO loop should be deterministic enough to inspect:

1. read `ORCHESTRATION.json`, `TEAM.md`, `TASKS`, reports, alerts,
2. identify next missing artifact or blocked condition,
3. update lifecycle,
4. send follow-up/recruit/TFT/meeting only if policy allows,
5. require reports,
6. require QA if policy says so,
7. finish only when gates pass.

Future command candidate:

```bash
adock job tick --project <path>
```

`tick` should not blindly create roles. It should produce or apply the next smallest valid coordination action.

## 12. UI implications

Visual Office should show:

- orchestration mode: solo / assisted / team / TFT / critical,
- why this mode was selected,
- selected roles and rejected role suggestions,
- whether QA is required,
- whether TFT is active,
- next CEO action,
- blockers and stale roles,
- final gate reason.

For simple jobs, UI should explicitly reassure the user:

> “간단한 작업으로 판단되어 별도 팀 없이 진행 중입니다.”

This prevents users from assuming the team system failed.

## 13. Finish gates

`job finish` should require:

- all selected required reports submitted,
- no unresolved blocker alert,
- QA passed if `requires_qa=true`,
- security/review passed if policy requires it,
- active TFTs closed or explicitly marked non-blocking,
- final summary written.

For `solo_direct`, finish gate can be minimal:

- one completion report or CEO summary,
- relevant verification evidence.

## 14. Risks and mitigations

### Risk: Over-orchestration

Mitigation:
- mode classification,
- team caps,
- distinct-output requirement,
- rejected role reasons,
- no TFT without blocker/dependency.

### Risk: Under-orchestration

Mitigation:
- QA/security policies,
- blocker detection,
- stale role detection,
- finish gates.

### Risk: Cost and latency

Mitigation:
- reuse roles first,
- max default workers,
- no meeting for status updates,
- no bulk agency role import.

### Risk: Prompt drift

Mitigation:
- artifact contracts,
- CLI validation,
- snapshot/UI visibility,
- tests for finish gates and role caps.

## 15. Success criteria

- A simple job completes without recruiting unnecessary roles.
- A medium feature gets the minimum useful specialist set.
- A risky job cannot finish without required QA/review.
- A blocker can create a visible TFT with members, goal, and exit condition.
- UI explains why the current orchestration mode was chosen.
- Final report includes the team structure, reports, QA status, and open risks.

## 16. Additional required policies found during gap review

### 16.1 Communication protocol

Adaptive orchestration must define how agents communicate, not only how teams are selected.

Required channels:
- direct role inbox: `.agent-work/12_INBOX/<role>/`,
- shared broadcast log: `.agent-work/14_SHARED_CONTEXT/BROADCASTS.md`,
- handoffs: `JOB/HANDOFFS/`,
- reports: `JOB/REPORTS/`,
- decisions: `JOB/MEETINGS/` or `JOB/DECISIONS/`.

Every cross-role request should include:
- job id,
- sender,
- receiver,
- requested action,
- related task/report/TFT path,
- expected output,
- due condition or blocking reason.

This prevents “chat-only coordination” that cannot be inspected later.

### 16.2 Authority and approval policy

The CEO may adaptively manage the team within mode caps. User approval is not required for normal low-risk CEO facilitation, but escalation is required when a planned action exceeds policy.

Allowed without user approval:
- no-op planning artifacts,
- follow-up messages,
- role reuse,
- TFT creation within cap for an already selected team,
- QA/review request required by policy.

Requires explicit user approval or existing project policy:
- destructive operations,
- credential/security-sensitive operations,
- external production/deploy actions,
- large team expansion beyond cap,
- installing new tools/dependencies,
- changing model/provider globally if not already requested,
- expensive long-running multi-agent execution beyond budget.

### 16.3 Budget and latency guardrails

Each job should carry a coordination budget so simple work does not become slow or expensive.

Suggested fields in `ORCHESTRATION.json`:

```json
{
  "budget": {
    "max_roles": 1,
    "max_tfts": 0,
    "max_meetings": 0,
    "expected_minutes": 10,
    "escalation_requires_reason": true
  }
}
```

If the CEO wants to exceed budget, it must record:
- why the original mode is insufficient,
- what new role/TFT/meeting uniquely adds,
- whether user approval is required.

### 16.4 Locking and write ownership

Multi-agent jobs need explicit write ownership.

Rules:
- every task card that may edit files should declare `write_scope`,
- agents must check `.agent-work/LOCKS.md` before editing,
- overlapping write scopes require CEO coordination,
- TFTs must not silently overwrite ownership; they must update the task/handoff record.

Suggested task field:

```yaml
Write scope:
  - src-ui/components/ModelSettingsPanel.tsx
  - src-ui/styles.css
Shared files:
  - src-ui/App.tsx requires CEO coordination
```

### 16.5 Recovery, retry, and fallback

The orchestration engine should not assume every role completes successfully.

Required handling:
- stale role detected,
- report missing,
- role reports blocker,
- role pane offline,
- QA fails,
- task output conflicts with another task,
- required tool/model unavailable.

Recovery order:
1. follow up with current owner,
2. clarify blocker,
3. reassign within existing team,
4. create bounded TFT if cross-role,
5. recruit backup only if capability is missing,
6. escalate to user only for authority/scope/risk.

### 16.6 Model/runtime consistency

A job should record the runtime model context used by Hermes roles when available.

Suggested field:

```json
{
  "runtime": {
    "provider": "openai-codex",
    "model": "gpt-5.5",
    "source": "project|hermes-config|default"
  }
}
```

This helps explain why role behavior changed across jobs and ensures UI model changes are auditable in job history.

### 16.7 Decision quality requirements

A meeting/debate artifact is complete only when it includes:
- the exact question,
- proposals considered,
- decision,
- rejected alternatives,
- owner/action items,
- verification or follow-up needed.

A meeting without a decision should remain `status: unresolved` and must not unblock finish unless explicitly marked non-blocking.

### 16.8 Snapshot/UI observability

The UI should expose adaptive orchestration without clutter:
- mode badge,
- reason summary,
- budget/cap summary only in details,
- selected/rejected roles,
- active blockers,
- active TFTs,
- QA gate only when relevant,
- next CEO action.

For simple jobs, the absence of a team is a positive state, not an error.

### 16.9 Compatibility and migration

Existing jobs without `ORCHESTRATION.json`, `QA.md`, `TFTS/`, or `MEETINGS/` must keep working.

Fallback behavior:
- missing orchestration => infer `legacy_controlled_actions`,
- missing QA.md => use old report-based final readiness unless new policy says otherwise,
- legacy `TEAM.md` `TFT:` lines remain supported,
- snapshot fields remain optional.
