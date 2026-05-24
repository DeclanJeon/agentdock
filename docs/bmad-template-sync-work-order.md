# BMAD Template Sync Work Order

Status: Implemented; retained as historical work order and regression reference.

Implementation notes (2026-05-24):

- `roles sync bmad --source github --ref <ref> --yes` fetches BMAD templates from `bmad-code-org/BMAD-METHOD` and caches them under the user role-template directory.
- `roles sync bmad --offline --yes` installs bundled fallback templates without network access.
- `recruit --template <bmad-id> --sync-template` and `AGENTDOCK_BMAD_AUTO_SYNC=1` support explicit/opt-in recruit-time fetch.
- `recruit --require-template` fails if the required BMAD template cannot be fetched.
- Local user cache and bundled templates remain ahead of remote fetches in the resolution order.

## Goal

AgentDock should form teams from local prompt templates first, but when a needed BMAD role template is missing or stale, it should be able to fetch the official BMAD-METHOD prompt from GitHub, cache it locally, and then use the cached local copy for future `agentdock recruit` calls.

The intended user experience is:

1. `agentdock recruit api-dev --template bmad-agent-dev --mission "..."`
2. AgentDock resolves `bmad-agent-dev`.
3. If the template exists in the local user cache, use it.
4. If the template is missing and network sync is enabled, fetch the matching BMAD prompt from `https://github.com/bmad-code-org/BMAD-METHOD`.
5. Cache the fetched prompt under the user template directory.
6. Generate `.agentdock/prompts/<role>.md` from the cached prompt plus the mission override.

## Original State

At the time this work order was written, AgentDock exposed 11 template IDs in `agentdock roles list`:

- BMAD: `bmad-agent-dev`, `bmad-analyst`, `bmad-architect`, `bmad-pm`, `bmad-tech-writer`, `bmad-ux-designer`
- AgentDock supplemental: `agentdock-ceo`, `agentdock-cto`, `agentdock-marketing`, `agentdock-planner`, `agentdock-qa`

The original implementation was local-first and mostly static:

- `role_template_file` checks user template files first, then bundled repo template paths.
- `role_template_body` contains short built-in fallback summaries.
- `agentdock roles sync bmad` verifies a remote URL is reachable, but it writes AgentDock's bundled fallback summaries instead of installing the actual BMAD prompt files.
- `agentdock recruit --template ...` does not fetch from GitHub.

## Required Behavior

### Resolution Order

For BMAD templates, resolve in this order:

1. User cache: `${XDG_CONFIG_HOME:-$HOME/.config}/agentdock/roles/bmad/<id>.md`
2. Repo bundle: `<install-root>/roles/bmad/<id>.md`
3. Remote BMAD source, when explicitly enabled by sync/recruit policy
4. Built-in fallback body, only when remote is disabled or unavailable

For AgentDock supplemental templates, keep the current local behavior. Do not fetch these from BMAD because BMAD does not own AgentDock-specific CEO/CTO/marketing/planning/QA supplements.

### Commands

Keep existing commands compatible, then add clearer sync behavior:

```bash
agentdock roles sync bmad --yes
agentdock roles sync bmad --offline --yes
agentdock roles sync bmad --source github --ref main --yes
agentdock roles sync bmad --url <raw-or-api-base> --yes
```

`--offline` must never use the network.

`--source github` should fetch official BMAD-METHOD files from `bmad-code-org/BMAD-METHOD`.

`--ref` should default to `main`, but the implementation should allow tags or SHAs so releases can pin the source later.

`--url` should remain available for testing and mirrors.

### Recruit-Time Fetch Policy

Default behavior should stay deterministic and not surprise offline users:

- `agentdock recruit --template bmad-agent-dev` uses local cache/bundle/fallback.
- Add `AGENTDOCK_BMAD_AUTO_SYNC=1` to allow recruit-time fetch when the requested BMAD template is missing locally.
- Add `agentdock recruit --sync-template` as an explicit one-shot fetch option.

If remote fetch fails during recruit, the command should continue with a clear warning and use the built-in fallback if available. Team creation should not fail only because GitHub is unavailable, unless the user passes a strict option such as `--require-template`.

### Template Identity Map

Maintain an explicit map from AgentDock IDs to BMAD upstream candidates.

Initial mapping:

| AgentDock ID | BMAD upstream role | Notes |
| --- | --- | --- |
| `bmad-agent-dev` | `dev` / developer agent | Current README references Developer and `bmad-code-review`. |
| `bmad-analyst` | `analyst` | Discovery, brainstorming, research, briefs. |
| `bmad-architect` | `architect` | Architecture and solutioning. |
| `bmad-pm` | `pm` | PRD, epics, stories, product planning. |
| `bmad-tech-writer` | `tech-writer` | Documentation role. |
| `bmad-ux-designer` | `ux-designer` | UX/UI design workflows. |

Do not assume BMAD repository layout is permanently stable. The resolver should try a small ordered list of candidate paths and fail cleanly.

Candidate path strategy:

1. Prefer a manifest if BMAD exposes one in the repo or package.
2. Try known v6 module paths, such as `bmad/bmm/agents/<role>.md` or source equivalents.
3. Try legacy/v4 paths if present.
4. If no candidate works, report the checked paths and use fallback.

## Implementation Plan

### 1. Add Source Configuration

Add constants near the current template directory constants in `bin/agentdock`:

```bash
BMAD_GITHUB_OWNER="bmad-code-org"
BMAD_GITHUB_REPO="BMAD-METHOD"
BMAD_DEFAULT_REF="${AGENTDOCK_BMAD_REF:-main}"
BMAD_RAW_BASE="${AGENTDOCK_BMAD_RAW_BASE:-https://raw.githubusercontent.com/$BMAD_GITHUB_OWNER/$BMAD_GITHUB_REPO}"
```

Allow environment overrides for testing and corporate mirrors.

### 2. Add BMAD Role Metadata Helpers

Add functions:

```bash
is_bmad_template_id <id>
bmad_upstream_role <id>
bmad_candidate_paths <id>
bmad_remote_raw_url <ref> <path>
```

Keep the canonical ID conversion in `canonical_role_template_id`; do not spread aliases through fetch code.

### 3. Add Fetch + Cache Function

Add:

```bash
sync_bmad_template <id> <ref> <url_base_or_empty>
```

Responsibilities:

- Create `$USER_ROLE_TEMPLATE_DIR`.
- Fetch only the requested role.
- Validate the fetched file is non-empty and looks like an agent prompt or agent definition.
- Write to a temp file first, then atomically move it to `$USER_ROLE_TEMPLATE_DIR/<id>.md`.
- Add a source header with upstream URL, ref, sync timestamp, and AgentDock ID.
- Avoid executing or sourcing fetched content. Treat it as inert markdown/data.

Validation should be conservative:

- Minimum size greater than a small threshold, such as 200 bytes.
- Must contain role-ish markers such as `agent`, `persona`, `role`, `commands`, `activation`, `Developer`, `Architect`, `Analyst`, `Product Manager`, `UX`, or `Technical Writer`.
- Must not contain shell heredoc wrappers inserted by AgentDock.

### 4. Update `roles sync bmad`

Change `cmd_roles sync bmad` from "remote availability check + bundled fallback write" to actual template installation.

Expected behavior:

- With network: sync all known BMAD template IDs.
- With `--offline`: write bundled fallback templates exactly as today.
- With partial remote failure: install successful templates, report failures, and return non-zero unless `--best-effort` is passed.
- Preserve the existing `--yes` confirmation behavior.

### 5. Update Template Resolution

Do not make `role_template_file` perform network I/O by default.

Add a wrapper used by `write_template_role_prompt`:

```bash
ensure_role_template_available <template> <policy>
```

Policy values:

- `local`: current behavior.
- `auto`: if BMAD and missing locally, fetch then retry local resolution.
- `strict`: fetch if needed; fail if unavailable.

Wire policy from:

- `agentdock recruit --sync-template` => `auto`
- `AGENTDOCK_BMAD_AUTO_SYNC=1` => `auto`
- future `--require-template` => `strict`
- default => `local`

### 6. Preserve Offline and Security Properties

Security constraints:

- Never source fetched files.
- Never execute fetched files.
- Never support arbitrary `curl | bash` in template sync.
- Limit remote URLs to raw markdown/data fetches unless `--url` is explicitly provided by the operator.
- Store fetched files in user config, not project `.agentdock`, so one sync can serve many projects.

Offline constraints:

- `agentdock recruit` must still work without network via fallback.
- `agentdock roles list` must never require network.
- `agentdock roles sync bmad --offline --yes` must remain useful for air-gapped setups.

### 7. Documentation Updates

Update README sections:

- "Templates And Adapters"
- "Security / Trust Model"
- "Verify Locally"

Document:

- Local-first resolution order.
- `roles sync bmad --source github --ref <ref>`.
- `recruit --sync-template`.
- `AGENTDOCK_BMAD_AUTO_SYNC=1`.
- Offline fallback behavior.

### 8. Tests

Extend `tests/smoke.sh` with fake network fixtures instead of real GitHub access.

Minimum test cases:

1. `roles list` still prints all 11 templates without network.
2. `roles sync bmad --offline --yes` writes fallback files to a temp config home.
3. `roles sync bmad --source github --ref test --yes --url file://...` or a local fixture mode installs actual fixture content.
4. `recruit --template bmad-agent-dev` uses local fallback when no cache exists.
5. `recruit --template bmad-agent-dev --sync-template` fetches missing fixture content and writes `.agentdock/prompts/<role>.md` from it.
6. Failed fetch falls back with a warning in non-strict mode.
7. Strict mode fails when fetch fails and no local template exists.

Because the current project is Bash-only, avoid adding dependencies just to parse remote metadata. Use simple candidate URL fetches and fixture-backed tests.

## Acceptance Criteria

- `agentdock roles sync bmad --source github --ref main --yes` installs real BMAD role prompt files into the user template cache when network is available.
- `agentdock recruit <role> --template bmad-agent-dev --sync-template` fetches and caches a missing BMAD template, then generates the role prompt from that cached file.
- Existing offline usage remains functional.
- Existing template IDs and aliases remain compatible.
- No fetched content is executed or sourced.
- README explains when web access is used.
- `bash -n bin/agentdock install.sh tests/smoke.sh scripts/check-version.sh` passes.
- `bash tests/smoke.sh` passes.

## Open Risks

- BMAD-METHOD repository layout may change. Mitigate with candidate-path resolver, source ref pinning, and clear failure output.
- GitHub rate limits can affect unauthenticated sync. Mitigate with cache-first behavior and optional mirror/base URL override.
- Upstream BMAD prompt format may be YAML/TOML/Markdown depending on version. Treat fetched content as inert text and do not parse deeply unless a stable manifest is available.
- AgentDock currently has AgentDock-only supplemental roles that BMAD does not provide. Keep those templates owned locally.

## Stop Condition

This task is complete when the implementation can prove, through fixture-backed tests and documentation, that AgentDock uses local templates by default, can intentionally fetch missing BMAD templates from BMAD-METHOD, caches them safely, and preserves offline fallback behavior.
