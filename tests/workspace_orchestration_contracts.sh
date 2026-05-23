#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { echo "workspace orchestration contracts failed: $*" >&2; exit 1; }

grep -q 'agentdock status set --role' bin/agentdock || fail "live status command contract missing from CLI/prompts"
grep -q 'QA report contract' bin/agentdock || fail "QA report contract missing from job QA gate"
grep -q 'Summary: .*Files changed: .*Tests run:' bin/agentdock || fail "role report schema missing from task cards"
grep -q 'workspace-snapshot-cache.json' src-tauri/src/lib.rs || fail "snapshot cache watcher exclusion missing"
grep -q -- '--cache-ms' src-tauri/src/lib.rs || fail "Tauri snapshot bridge must request short cache window"
grep -q 'worktree merge --role' bin/agentdock || fail "worktree merge contract missing"
grep -q '"worktrees": %s' bin/agentdock || fail "workspace snapshot must expose worktrees"
grep -q 'worktree?:' src-ui/model/snapshot.ts || fail "UI snapshot model missing role worktree field"
grep -q '작업공간' src-ui/components/TeamActivityPanel.tsx || fail "team activity panel must surface role worktree"

echo "workspace orchestration contracts ok"
