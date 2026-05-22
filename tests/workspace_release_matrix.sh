#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

JOB_ID="${AGENTDOCK_RELEASE_MATRIX_JOB_ID:-JOB-260522190004397678}"
OUT_DIR="${1:-$ROOT/.agent-work/07_JOBS/$JOB_ID/OUTPUTS/release-matrix}"
mkdir -p "$OUT_DIR"
JSON="$OUT_DIR/workspace-release-matrix.json"
MD="$OUT_DIR/workspace-release-matrix.md"
LOG="$OUT_DIR/workspace-release-matrix.log"
: > "$LOG"
LIVE_CLICK_EVIDENCE_DIR="$ROOT/.agent-work/07_JOBS/$JOB_ID/OUTPUTS/live-click-evidence"
NATIVE_EVIDENCE_DIR="$ROOT/.agent-work/07_JOBS/$JOB_ID/OUTPUTS/native-evidence"
LIVE_CLICK_EVIDENCE_JSON="$LIVE_CLICK_EVIDENCE_DIR/live-click-evidence.json"
NATIVE_MANIFEST_JSON="$NATIVE_EVIDENCE_DIR/workspace-native-screenshot-manifest.json"

source_stamp() {
  find bin src-ui tests src-tauri \
    \( -path 'src-tauri/target' -o -path 'src-tauri/target/*' \) -prune -o \
    -type f -printf '%T@ %p\n' | sort -n | tail -1
}

source_stamp_before="$(source_stamp)"

declare -a names cmds statuses durations
run_gate() {
  local name="$1" cmd="$2" start end status
  names+=("$name")
  cmds+=("$cmd")
  start="$(date +%s)"
  echo "===== $name =====" >> "$LOG"
  set +e
  timeout 600 bash -lc "$cmd" >> "$LOG" 2>&1
  status=$?
  set -e
  end="$(date +%s)"
  statuses+=("$status")
  durations+=("$((end-start))")
  echo "===== $name status=$status =====" >> "$LOG"
}

run_gate "bash syntax" "bash -n bin/agentdock tests/*.sh"
run_gate "version" "./bin/agentdock version >/dev/null && ./bin/agentdock help >/dev/null"
run_gate "workspace job create bridge" "bash tests/workspace_job_create_bridge.sh"
if [[ "${AGENTDOCK_RUN_LIVE_CLICK:-0}" == "1" ]]; then
  run_gate "live click job create" "bash tests/workspace_live_click_job_create.sh '$LIVE_CLICK_EVIDENCE_DIR'"
else
  echo "===== live click job create skipped: set AGENTDOCK_RUN_LIVE_CLICK=1 with AGENTDOCK_LIVE_CLICK_DRIVER_CMD =====" >> "$LOG"
  run_gate "live click job create" "bash tests/workspace_live_click_job_create.sh '$LIVE_CLICK_EVIDENCE_DIR'"
fi
run_gate "desktop no-write" "bash tests/workspace_desktop_no_write.sh"
run_gate "quiet no-write" "bash tests/workspace_quiet_no_write.sh"
run_gate "security redaction" "bash tests/workspace_security_redaction.sh"
run_gate "desktop app" "bash tests/workspace_desktop_app.sh"
run_gate "reference a11y" "bash tests/workspace_reference_a11y.sh"
run_gate "visual fixtures" "bash tests/workspace_visual_fixtures.sh"
run_gate "visual scene" "bash tests/workspace_visual_scene.sh"
run_gate "timeline" "bash tests/workspace_timeline.sh"
run_gate "action audit" "bash tests/workspace_action_audit.sh"
run_gate "workspace p0.5" "bash tests/workspace_p05.sh"
run_gate "smoke" "bash tests/smoke.sh"
run_gate "npm build" "npm run build"
run_gate "cargo check" "cargo check --manifest-path src-tauri/Cargo.toml"
run_gate "cargo test" "cargo test --manifest-path src-tauri/Cargo.toml"
if [[ "${AGENTDOCK_SKIP_TAURI_BUILD:-0}" == "1" ]]; then
  names+=("tauri build")
  cmds+=("npm run tauri:build")
  statuses+=("125")
  durations+=("0")
  echo "===== tauri build skipped by AGENTDOCK_SKIP_TAURI_BUILD =====" >> "$LOG"
else
  run_gate "tauri build" "npm run tauri:build"
fi
run_gate "package artifacts" "bash tests/workspace_package_artifacts.sh"
if [[ "${AGENTDOCK_REQUIRE_RELEASE_PROOF:-0}" == "1" ]]; then
  run_gate "native screenshots releaseProof" "AGENTDOCK_REQUIRE_RELEASE_PROOF=1 bash tests/workspace_native_screenshots.sh '$NATIVE_EVIDENCE_DIR'"
else
  run_gate "native screenshots manifest" "bash tests/workspace_native_screenshots.sh '$NATIVE_EVIDENCE_DIR'"
fi

source_stamp_after="$(source_stamp)"
stale=false
[[ "$source_stamp_before" == "$source_stamp_after" ]] || stale=true

python3 - "$JSON" "$MD" "$LOG" "$stale" "$JOB_ID" "$LIVE_CLICK_EVIDENCE_JSON" "$NATIVE_MANIFEST_JSON" "${names[@]}" -- "${statuses[@]}" -- "${durations[@]}" -- "${cmds[@]}" <<'PY'
import json, sys, datetime
from pathlib import Path
json_path, md_path, log_path, stale, job_id, live_click_path, native_manifest_path = sys.argv[1:8]
parts=[]; cur=[]
for arg in sys.argv[8:]:
    if arg == '--':
        parts.append(cur); cur=[]
    else:
        cur.append(arg)
parts.append(cur)
names, statuses, durations, cmds = parts
results=[]
for name, status, duration, cmd in zip(names, statuses, durations, cmds):
    status_i=int(status)
    results.append({"name": name, "command": cmd, "status": status_i, "passed": status_i == 0, "durationSeconds": int(duration)})
overall=all(r['passed'] for r in results) and stale == 'false'
evidence={"jobId": job_id, "liveClickEvidencePath": live_click_path, "liveClickEvidencePresent": Path(live_click_path).exists(), "nativeManifestPath": native_manifest_path, "nativeManifestPresent": Path(native_manifest_path).exists()}
for key, path in [("liveClickEvidence", live_click_path), ("nativeManifest", native_manifest_path)]:
    p = Path(path)
    if p.exists():
        try:
            evidence[key] = json.loads(p.read_text(encoding="utf-8"))
        except Exception as exc:
            evidence[key] = {"readbackError": str(exc)}
summary={"schema":"workspace.release-matrix.v1","generatedAt":datetime.datetime.now(datetime.timezone.utc).isoformat(),"overallPass":overall,"staleDuringRun":stale == 'true',"logPath":log_path,"evidence":evidence,"results":results}
open(json_path,'w').write(json.dumps(summary, indent=2)+"\n")
lines=["# Workspace release matrix", "", f"- Overall: {'PASS' if overall else 'FAIL'}", f"- Stale during run: {stale}", f"- Log: `{log_path}`", f"- Live-click evidence: `{live_click_path}` ({'present' if evidence['liveClickEvidencePresent'] else 'missing'})", f"- Native manifest: `{native_manifest_path}` ({'present' if evidence['nativeManifestPresent'] else 'missing'})", "", "| Gate | Result | Seconds |", "|---|---:|---:|"]
for r in results:
    lines.append(f"| {r['name']} | {'PASS' if r['passed'] else 'FAIL '+str(r['status'])} | {r['durationSeconds']} |")
open(md_path,'w').write("\n".join(lines)+"\n")
print(f"release matrix {'PASS' if overall else 'FAIL'} json={json_path} md={md_path}")
raise SystemExit(0 if overall else 1)
PY
