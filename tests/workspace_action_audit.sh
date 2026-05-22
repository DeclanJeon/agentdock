#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { echo "workspace action audit test failed: $*" >&2; exit 1; }

[[ -f src-ui/model/actionAudit.ts ]] || fail "action audit model missing"
[[ -f src-ui/components/ActionAuditPanel.tsx ]] || fail "ActionAuditPanel missing"
grep -q 'session-local' src-ui/components/ActionAuditPanel.tsx || fail "session-local audit copy missing"
grep -q 'redactText' src-ui/model/actionAudit.ts || fail "audit model must redact previews"
grep -q 'completeJobCreateAudit' src-ui/model/actionAudit.ts || fail "job create audit completion helper missing"
grep -q 'durationMs' src-ui/model/actionAudit.ts || fail "audit model must capture action duration"
grep -q 'durationMs' src-ui/components/ActionAuditPanel.tsx || fail "audit panel must display action duration"
grep -q 'redacted before display' src-ui/components/ActionAuditPanel.tsx || fail "audit panel missing redaction copy"
grep -q 'newAuditAttempt' src-ui/App.tsx || fail "App does not create audit attempts"
grep -q 'completeJobCreateAudit' src-ui/App.tsx || fail "App does not complete audit events"
grep -q 'ActionAuditPanel' src-ui/App.tsx || fail "audit panel not mounted"
if grep -R --line-number -E 'localStorage\.setItem\([^)]*audit|sessionStorage\.setItem\([^)]*audit' src-ui 2>/dev/null; then
  fail "session-local audit must not persist to browser storage"
fi

echo "workspace action audit ok"
