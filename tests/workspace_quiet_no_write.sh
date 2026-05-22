#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { echo "workspace quiet no-write failed: $*" >&2; exit 1; }
TMP="$(mktemp -d)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

hash_tree() {
  local base="$1" out="$2"
  (cd "$base" && find .agentdock .agent-work \
    -path './.agentdock/state/panes.lock' -prune -o \
    -path './.agent-work/10_REPORTS/*' -prune -o \
    -path './.agent-work/07_JOBS/*/REPORTS/*' -prune -o \
    -path './.agent-work/07_JOBS/*/OUTPUTS/qa-logs/*' -prune -o \
    -type f -print0 | sort -z | xargs -0 sha256sum) > "$out"
}

mkdir -p ".agent-work/07_JOBS/JOB-260522190004397678/OUTPUTS/qa-logs"
REPORT=".agent-work/07_JOBS/JOB-260522190004397678/OUTPUTS/qa-logs/quiet-no-write-report.md"

hash_tree "$ROOT" "$TMP/before.sha256"
./bin/agentdock workspace snapshot --json --project "$ROOT" > "$TMP/snapshot.json"
python3 -m json.tool "$TMP/snapshot.json" >/dev/null
./bin/agentdock workspace export --out "$TMP/workspace.html" --project "$ROOT" >/dev/null
hash_tree "$ROOT" "$TMP/after.sha256"

if ! diff -u "$TMP/before.sha256" "$TMP/after.sha256" > "$TMP/quiet.diff"; then
  cp "$TMP/quiet.diff" ".agent-work/07_JOBS/JOB-260522190004397678/OUTPUTS/qa-logs/quiet-no-write.diff"
  fail "read-only snapshot/export mutated coordination files; diff saved"
fi

cat > "$REPORT" <<EOF
# Quiet no-write proof

- Project: $ROOT
- Operations: workspace snapshot --json; workspace export to /tmp only
- Scope hashed: .agentdock and .agent-work excluding volatile report/log output dirs and panes.lock
- Result: PASS — no main coordination-file mutation observed
EOF

echo "workspace quiet no-write ok; report=$REPORT"
