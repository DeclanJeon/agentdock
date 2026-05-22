#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { echo "workspace security redaction test failed: $*" >&2; exit 1; }
TMP="$(mktemp -d)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

SECRET_TOKEN="sk-qa-redaction-1234567890abcdef"
SECRET_ENV="OPENAI_API_KEY=$SECRET_TOKEN"
PROJECT="$TMP/redaction project"
JOB="JOB-REDACTION"
JOB_DIR="$PROJECT/.agent-work/07_JOBS/$JOB"
mkdir -p "$PROJECT/.agentdock/state" "$PROJECT/.agent-work/07_JOBS" "$PROJECT/.agent-work/14_SHARED_CONTEXT" "$JOB_DIR/TASKS" "$JOB_DIR/REPORTS"
printf 'PROJECT_NAME=redaction-fixture\nPROJECT_ROOT=%s\nSESSION_NAME=redaction-session\nAGENT_IDS=orchestrator developer agentdock-qa\n' "$PROJECT" > "$PROJECT/.agentdock/config.runtime"
printf 'Active job: %s/README.md\n' "$JOB_DIR" > "$PROJECT/.agent-work/07_JOBS/CURRENT.md"
printf '# %s\n' "$JOB" > "$JOB_DIR/README.md"
printf 'Status: verifying\n' > "$JOB_DIR/LIFECYCLE.md"
printf '# Task\n' > "$JOB_DIR/TASKS/orchestrator.md"
printf '# Task\n' > "$JOB_DIR/TASKS/developer.md"
printf '# Task\n' > "$JOB_DIR/TASKS/agentdock-qa.md"
printf '# Report\n\nSummary: BLOCKED; leaked %s in raw tool output and bearer %s\n' "$SECRET_ENV" "$SECRET_TOKEN" > "$JOB_DIR/REPORTS/26052200:00:00.000000-agentdock-qa.md"

(cd "$PROJECT" && "$ROOT/bin/agentdock" workspace snapshot --json --project "$PROJECT" > "$TMP/snapshot.json")
python3 -m json.tool "$TMP/snapshot.json" >/dev/null
(cd "$PROJECT" && "$ROOT/bin/agentdock" workspace export --out .agent-work/11_ARCHIVE/workspace.html >/dev/null)

if grep -R --line-number -F "$SECRET_TOKEN" "$TMP/snapshot.json" "$PROJECT/.agent-work/11_ARCHIVE/workspace.html"; then
  fail "raw secret token leaked into snapshot/export"
fi
if grep -R --line-number -F "$SECRET_ENV" "$TMP/snapshot.json" "$PROJECT/.agent-work/11_ARCHIVE/workspace.html"; then
  fail "raw secret env assignment leaked into snapshot/export"
fi
# Redaction should preserve enough context to diagnose without exposing credential material.
grep -Eq '\[REDACTED|redacted|\*\*\*' "$TMP/snapshot.json" "$PROJECT/.agent-work/11_ARCHIVE/workspace.html" || fail "no redaction marker found"

echo "workspace security redaction ok"
