#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

JOB_ID="JOB-260522190004397678"
OUT_DIR="${1:-$ROOT/.agent-work/07_JOBS/$JOB_ID/OUTPUTS/live-click-evidence}"
mkdir -p "$OUT_DIR"
EVIDENCE="$OUT_DIR/live-click-evidence.json"
LOG="$OUT_DIR/live-click.log"
SANDBOX="$(mktemp -d /tmp/agentdock-live-click-XXXXXX)"

main_current="$ROOT/.agent-work/07_JOBS/CURRENT.md"
main_hash_before="missing"
[[ -f "$main_current" ]] && main_hash_before="$(sha256sum "$main_current" | awk '{print $1}')"

fail_json() {
  local reason="$1" code="${2:-2}"
  local main_hash_after="missing"
  [[ -f "$main_current" ]] && main_hash_after="$(sha256sum "$main_current" | awk '{print $1}')"
  python3 - "$EVIDENCE" "$SANDBOX" "$main_hash_before" "$main_hash_after" "$reason" <<'PY'
import json, sys, datetime
path, sandbox, before, after, reason = sys.argv[1:]
json.dump({
  "schema": "workspace.live-click-job-create.v1",
  "status": "blocked",
  "blockedReason": reason,
  "generatedAt": datetime.datetime.now(datetime.timezone.utc).isoformat(),
  "sandboxProject": sandbox,
  "mainCurrentHashBefore": before,
  "mainCurrentHashAfter": after,
  "mainNoMutation": before == after,
  "nativeClick": False,
  "sandboxMutation": False,
  "uiSuccess": False,
  "notes": [
    "This harness is fail-closed: fake bridge/source proof is not accepted as native live-click evidence.",
    "Run with AGENTDOCK_LIVE_CLICK_DRIVER_CMD to perform a real native UI click and write live-click-result.json."
  ]
}, open(path, 'w'), indent=2)
print()
PY
  echo "workspace live-click blocked: $reason; evidence=$EVIDENCE" | tee "$LOG" >&2
  exit "$code"
}

mkdir -p "$SANDBOX/.agentdock" "$SANDBOX/.agent-work/07_JOBS" "$SANDBOX/bin"
printf 'Active job: none\n' > "$SANDBOX/.agent-work/07_JOBS/CURRENT.md"
cat > "$SANDBOX/bin/agentdock" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ "${1:-}" == "job" && "${2:-}" == "--no-attach" ]]; then
  id="JOB-LIVECLICK$(date +%s%N)"
  dir="$ROOT/.agent-work/07_JOBS/$id"
  mkdir -p "$dir"
  printf 'Active job: %s/README.md\n' "$dir" > "$ROOT/.agent-work/07_JOBS/CURRENT.md"
  printf '# %s\n' "$id" > "$dir/README.md"
  echo "Job kickoff: $dir/README.md"
  exit 0
fi
if [[ "${1:-}" == "workspace" && "${2:-}" == "snapshot" ]]; then
  current="$(cat "$ROOT/.agent-work/07_JOBS/CURRENT.md" 2>/dev/null || true)"
  job="$(printf '%s' "$current" | grep -o 'JOB-[A-Za-z0-9]*' | head -1 || true)"
  printf '{"schema_version":"workspace.snapshot.v1","project":{"root":"%s"},"job":{"id":"%s","final_ready":false},"roles":[],"reports":{"submitted":0,"required":0},"commands":{"write_bridge_enabled":false,"allowed_actions":["job_create"]}}\n' "$ROOT" "$job"
  exit 0
fi
echo "fake agentdock unsupported: $*" >&2
exit 2
SH
chmod +x "$SANDBOX/bin/agentdock"

if [[ -z "${AGENTDOCK_LIVE_CLICK_DRIVER_CMD:-}" ]]; then
  fail_json "AGENTDOCK_LIVE_CLICK_DRIVER_CMD is unset; no native UI automation driver is configured" 3
fi

sandbox_hash_before="$(sha256sum "$SANDBOX/.agent-work/07_JOBS/CURRENT.md" | awk '{print $1}')"
set +e
AGENTDOCK_BIN="$SANDBOX/bin/agentdock" AGENTDOCK_LIVE_CLICK_PROJECT="$SANDBOX" bash -lc "$AGENTDOCK_LIVE_CLICK_DRIVER_CMD" > "$LOG" 2>&1
status=$?
set -e
if [[ "$status" -ne 0 ]]; then
  fail_json "native UI driver command failed with status $status; see live-click.log" "$status"
fi

sandbox_hash_after="$(sha256sum "$SANDBOX/.agent-work/07_JOBS/CURRENT.md" | awk '{print $1}')"
main_hash_after="missing"
[[ -f "$main_current" ]] && main_hash_after="$(sha256sum "$main_current" | awk '{print $1}')"
created_job="$(grep -o 'JOB-[A-Za-z0-9]*' "$SANDBOX/.agent-work/07_JOBS/CURRENT.md" | head -1 || true)"
[[ -n "$created_job" ]] || fail_json "driver completed but sandbox CURRENT.md has no JOB id" 4
[[ "$sandbox_hash_before" != "$sandbox_hash_after" ]] || fail_json "driver completed but sandbox CURRENT.md did not mutate" 4
[[ "$main_hash_before" == "$main_hash_after" ]] || fail_json "main CURRENT.md changed during sandbox live-click" 4

python3 - "$EVIDENCE" "$SANDBOX" "$created_job" "$main_hash_before" "$main_hash_after" <<'PY'
import json, sys, datetime
path, sandbox, job, before, after = sys.argv[1:]
json.dump({
  "schema": "workspace.live-click-job-create.v1",
  "status": "pass",
  "generatedAt": datetime.datetime.now(datetime.timezone.utc).isoformat(),
  "sandboxProject": sandbox,
  "createdJobId": job,
  "mainCurrentHashBefore": before,
  "mainCurrentHashAfter": after,
  "mainNoMutation": before == after,
  "nativeClick": True,
  "sandboxMutation": True,
  "uiSuccess": True
}, open(path, 'w'), indent=2)
print()
PY

echo "workspace live-click job create ok; evidence=$EVIDENCE"
