#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { echo "workspace orchestration contracts failed: $*" >&2; exit 1; }

grep -q 'agentdock status set --role' bin/agentdock || fail "live status command contract missing from CLI/prompts"
grep -q 'QA report contract' bin/agentdock || fail "QA report contract missing from job QA gate"
grep -q 'Summary: .*Files changed: .*Tests run:' bin/agentdock || fail "role report schema missing from task cards"
grep -q 'workspace-snapshot-cache.json' bin/agentdock || fail "snapshot cache contract missing"
grep -q -- '--cache-ms' bin/agentdock || fail "CLI snapshot cache option missing"
grep -q 'worktree merge --role' bin/agentdock || fail "worktree merge contract missing"
grep -q '"worktrees": %s' bin/agentdock || fail "workspace snapshot must expose worktrees"
grep -q '"worktree": {' bin/agentdock || fail "CLI snapshot role worktree payload missing"
! grep -q 'workspace app' bin/agentdock || fail "desktop app command must be removed"
[[ ! -e src-ui && ! -e src-tauri && ! -e package.json ]] || fail "desktop app source must be removed"

echo "workspace orchestration contracts ok"
