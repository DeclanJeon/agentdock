#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
fail() { echo "workspace controlled-actions contract failed: $*" >&2; exit 1; }

for name in \
  agentdock_job_followup \
  agentdock_team_broadcast \
  agentdock_role_send \
  agentdock_recruit_preview \
  agentdock_recruit_role \
  agentdock_task_proposal \
  agentdock_job_report \
  agentdock_finish_preview \
  agentdock_job_finish; do
  grep -q "fn $name" src-tauri/src/lib.rs || fail "missing Tauri command $name"
  grep -q "$name" src-ui/model/actions.ts || fail "missing UI action type $name"
  grep -q "$name" src-ui/components/InterventionPanel.tsx || fail "missing InterventionPanel wiring $name"
done

grep -q 'runControlledAction' src-ui/App.tsx || fail "App missing controlled action runner"
grep -q 'JobHistoryPanel' src-ui/App.tsx || fail "job history panel not mounted"
grep -q 'history' src-ui/model/snapshot.ts || fail "snapshot history type missing"
grep -q 'stale_role' src-ui/components/TopHud.tsx || fail "stale heartbeat badge missing"
grep -q 'agentdock job report --from <role>' bin/agentdock || fail "snapshot allowed_actions missing job report"

if grep -Eq 'sh -c|bash -c|/bin/sh|/bin/bash' src-tauri/src/lib.rs; then
  fail "Tauri bridge must not invoke a shell"
fi

echo "workspace controlled-actions contract ok"
