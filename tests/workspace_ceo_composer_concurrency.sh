#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { echo "workspace CEO composer concurrency test failed: $*" >&2; exit 1; }

[[ -f src-ui/components/CeoTaskComposer.tsx ]] || fail "CeoTaskComposer missing"
[[ -f src-ui/model/actions.ts ]] || fail "CEO action model missing"
[[ -f src-ui/App.tsx ]] || fail "App missing"

grep -q 'MAX_CEO_TASK_CHARS = 8000' src-ui/model/actions.ts || fail "overlong request limit missing"
grep -q 'Describe work for the CEO before sending' src-ui/model/actions.ts || fail "empty request validation missing"
grep -q 'CEO task request must be.*characters or fewer' src-ui/model/actions.ts || fail "overlong validation copy missing"
grep -q 'submitInFlightRef' src-ui/components/CeoTaskComposer.tsx || fail "duplicate submit ref guard missing"
grep -q 'duplicate submit locked while sending' src-ui/components/CeoTaskComposer.tsx || fail "duplicate-submit trust copy missing"
grep -q 'disabled={inFlight}' src-ui/components/CeoTaskComposer.tsx || fail "input must be disabled while request is in-flight"
grep -q "Snapshot refresh after create: {refreshStatus}" src-ui/components/CeoTaskComposer.tsx || fail "post-create refresh state copy missing"
grep -q "'pending'" src-ui/App.tsx || fail "post-create refresh pending state missing"
grep -q "'succeeded'" src-ui/App.tsx || fail "post-create refresh succeeded state missing"
grep -q "'failed'" src-ui/App.tsx || fail "post-create refresh failed state missing"
grep -q "SnapshotRefreshOutcome = 'succeeded' | 'failed' | 'skipped'" src-ui/App.tsx || fail "explicit refresh outcome contract missing"
grep -q "refreshInFlightRef.current) return 'skipped'" src-ui/App.tsx || fail "refresh-overlap skip must be distinct from failure"
grep -q "refreshOutcome === 'succeeded'" src-ui/App.tsx || fail "refresh result must drive succeeded/failed/pending state"
grep -q 'jobCreateErrorMessage' src-ui/components/CeoTaskComposer.tsx || fail "failure message must use redacted/actionable formatter"
if grep -E "invoke<.*\('(recruit|broadcast|finish|report|task|send)'" src-ui/App.tsx src-ui/components/CeoTaskComposer.tsx; then
  fail "CEO composer must not expose non-job-create action bridges"
fi

cargo test --manifest-path src-tauri/Cargo.toml job_create -- --nocapture

echo "workspace CEO composer concurrency ok"
