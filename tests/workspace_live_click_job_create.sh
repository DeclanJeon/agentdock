#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

resolve_current_job_id() {
  if [[ -n "${AGENTDOCK_LIVE_CLICK_EVIDENCE_JOB_ID:-}" ]]; then
    printf '%s\n' "$AGENTDOCK_LIVE_CLICK_EVIDENCE_JOB_ID"
    return
  fi
  if [[ -n "${AGENTDOCK_RELEASE_MATRIX_JOB_ID:-}" ]]; then
    printf '%s\n' "$AGENTDOCK_RELEASE_MATRIX_JOB_ID"
    return
  fi
  if [[ -f "$ROOT/.agent-work/07_JOBS/CURRENT.md" ]]; then
    python3 - "$ROOT/.agent-work/07_JOBS/CURRENT.md" <<'PY'
from pathlib import Path
import re
import sys
text = Path(sys.argv[1]).read_text(encoding="utf-8", errors="ignore")
match = re.search(r"(JOB-[A-Za-z0-9][A-Za-z0-9_-]*)", text)
print(match.group(1) if match else "")
PY
  fi
}

JOB_ID="$(resolve_current_job_id)"
if [[ -n "$JOB_ID" ]]; then
  DEFAULT_OUT_DIR="$ROOT/.agent-work/07_JOBS/$JOB_ID/OUTPUTS/live-click-evidence"
else
  DEFAULT_OUT_DIR="$ROOT/.agent-work/11_ARCHIVE/live-click-evidence/no-current-job-$(date +%Y%m%d%H%M%S)"
fi
OUT_DIR="${1:-$DEFAULT_OUT_DIR}"
mkdir -p "$OUT_DIR"
EVIDENCE="$OUT_DIR/live-click-evidence.json"
RESULT="$OUT_DIR/live-click-result.json"
LOG="$OUT_DIR/live-click.log"
SANDBOX="$(mktemp -d /tmp/agentdock-live-click-XXXXXX)"
sandbox_hash_before="missing"
sandbox_hash_after="missing"

main_current="$ROOT/.agent-work/07_JOBS/CURRENT.md"
main_hash_before="missing"
[[ -f "$main_current" ]] && main_hash_before="$(sha256sum "$main_current" | awk '{print $1}')"

fail_json() {
  local reason="$1" code="${2:-2}"
  local main_hash_after="missing"
  local sandbox_current="$SANDBOX/.agent-work/07_JOBS/CURRENT.md"
  [[ -f "$main_current" ]] && main_hash_after="$(sha256sum "$main_current" | awk '{print $1}')"
  [[ -f "$sandbox_current" ]] && sandbox_hash_after="$(sha256sum "$sandbox_current" | awk '{print $1}')"
  python3 - "$EVIDENCE" "$SANDBOX" "$JOB_ID" "$OUT_DIR" "$RESULT" "$main_current" "$main_hash_before" "$main_hash_after" "$sandbox_hash_before" "$sandbox_hash_after" "$reason" <<'PY'
import json, sys, datetime
(
    path,
    sandbox,
    job_id,
    out_dir,
    result_path,
    main_current_path,
    main_before,
    main_after,
    sandbox_before,
    sandbox_after,
    reason,
) = sys.argv[1:]
json.dump({
  "schema": "workspace.live-click-job-create.v1",
  "status": "blocked",
  "blockedReason": reason,
  "generatedAt": datetime.datetime.now(datetime.timezone.utc).isoformat(),
  "evidenceJobId": job_id or "unknown",
  "outputDirectory": out_dir,
  "sandboxProject": sandbox,
  "mainCurrentPath": main_current_path,
  "mainCurrentHashBefore": main_before,
  "mainCurrentHashAfter": main_after,
  "mainNoMutation": main_before == main_after,
  "sandboxCurrentHashBefore": sandbox_before,
  "sandboxCurrentHashAfter": sandbox_after,
  "nativeClick": False,
  "sandboxMutation": False,
  "uiSuccess": False,
  "uiResultPath": result_path,
  "uiResultPresent": False,
  "notes": [
    "This harness is fail-closed: fake bridge/source proof is not accepted as native live-click evidence.",
    "Run with AGENTDOCK_LIVE_CLICK_DRIVER_CMD to perform a real native UI click.",
    "The driver must write JSON to AGENTDOCK_LIVE_CLICK_RESULT proving the UI success state."
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

sandbox_hash_before="$(sha256sum "$SANDBOX/.agent-work/07_JOBS/CURRENT.md" | awk '{print $1}')"

if [[ -z "${AGENTDOCK_LIVE_CLICK_DRIVER_CMD:-}" ]]; then
  fail_json "AGENTDOCK_LIVE_CLICK_DRIVER_CMD is unset; no native UI automation driver is configured" 3
fi

set +e
AGENTDOCK_BIN="$SANDBOX/bin/agentdock" AGENTDOCK_LIVE_CLICK_PROJECT="$SANDBOX" AGENTDOCK_LIVE_CLICK_RESULT="$RESULT" AGENTDOCK_LIVE_CLICK_EVIDENCE_DIR="$OUT_DIR" bash -lc "$AGENTDOCK_LIVE_CLICK_DRIVER_CMD" > "$LOG" 2>&1
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
[[ -s "$RESULT" ]] || fail_json "driver completed but did not write UI success evidence to AGENTDOCK_LIVE_CLICK_RESULT" 4
python3 - "$RESULT" "$created_job" <<'PY' || fail_json "driver UI success evidence is invalid or does not match sandbox-created job" 4
import json
import sys
from pathlib import Path
path = Path(sys.argv[1])
created_job = sys.argv[2]
try:
    data = json.loads(path.read_text(encoding="utf-8"))
except Exception as exc:
    print(f"invalid JSON: {exc}", file=sys.stderr)
    raise SystemExit(1)
ok = data.get("ok")
if ok is None:
    ok = data.get("uiSuccess")
if ok is not True:
    print("expected ok=true or uiSuccess=true", file=sys.stderr)
    raise SystemExit(1)
reported = data.get("job_id") or data.get("jobId") or data.get("createdJobId")
if reported and reported != created_job:
    print(f"reported job {reported} != sandbox current job {created_job}", file=sys.stderr)
    raise SystemExit(1)
PY

python3 - "$EVIDENCE" "$SANDBOX" "$JOB_ID" "$OUT_DIR" "$RESULT" "$created_job" "$main_hash_before" "$main_hash_after" "$sandbox_hash_before" "$sandbox_hash_after" <<'PY'
import json, sys, datetime
path, sandbox, evidence_job, out_dir, result_path, job, main_before, main_after, sandbox_before, sandbox_after = sys.argv[1:]
with open(result_path, encoding="utf-8") as f:
    ui_result = json.load(f)
json.dump({
  "schema": "workspace.live-click-job-create.v1",
  "status": "pass",
  "generatedAt": datetime.datetime.now(datetime.timezone.utc).isoformat(),
  "evidenceJobId": evidence_job or "unknown",
  "outputDirectory": out_dir,
  "sandboxProject": sandbox,
  "createdJobId": job,
  "mainCurrentHashBefore": main_before,
  "mainCurrentHashAfter": main_after,
  "mainNoMutation": main_before == main_after,
  "sandboxCurrentHashBefore": sandbox_before,
  "sandboxCurrentHashAfter": sandbox_after,
  "nativeClick": True,
  "sandboxMutation": True,
  "uiSuccess": True,
  "uiResultPath": result_path,
  "uiResult": ui_result
}, open(path, 'w'), indent=2)
print()
PY

echo "workspace live-click job create ok; evidence=$EVIDENCE"
