#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ -n "${AGENTDOCK_NATIVE_EVIDENCE_JOB_ID:-}" ]]; then
  JOB_ID="$AGENTDOCK_NATIVE_EVIDENCE_JOB_ID"
elif [[ -f .agent-work/07_JOBS/CURRENT.md ]]; then
  JOB_ID="$(python3 - <<'PY'
from pathlib import Path
import re
text = Path('.agent-work/07_JOBS/CURRENT.md').read_text(encoding='utf-8', errors='ignore')
match = re.search(r'(JOB-[0-9]+)', text)
print(match.group(1) if match else 'unknown')
PY
)"
else
  JOB_ID="unknown"
fi
OUTPUT_DIR="${1:-$ROOT/.agent-work/07_JOBS/$JOB_ID/OUTPUTS/native-evidence}"
FIXTURE_DIR="${AGENTDOCK_NATIVE_FIXTURE_PROJECT_DIR:-$ROOT/.agent-work/11_ARCHIVE/native-screenshot-fixture-projects}"
APP_BIN="${AGENTDOCK_NATIVE_APP_BIN:-$ROOT/src-tauri/target/release/agentdock-workspace}"
mkdir -p "$OUTPUT_DIR"

"$ROOT/tests/workspace_native_prepare_fixture_projects.sh" "$FIXTURE_DIR" >/tmp/agentdock-native-fixtures.out
cat /tmp/agentdock-native-fixtures.out

CAPTURE_TEMPLATE="${AGENTDOCK_NATIVE_SCREENSHOT_CMD:-}"
if [[ -z "$CAPTURE_TEMPLATE" ]]; then
  if command -v gnome-screenshot >/dev/null 2>&1; then
    CAPTURE_TEMPLATE='gnome-screenshot -f {path}'
  elif command -v grim >/dev/null 2>&1; then
    CAPTURE_TEMPLATE='grim {path}'
  elif command -v scrot >/dev/null 2>&1; then
    CAPTURE_TEMPLATE='scrot {path}'
  elif command -v spectacle >/dev/null 2>&1; then
    CAPTURE_TEMPLATE='spectacle -b -n -o {path}'
  elif command -v gdbus >/dev/null 2>&1 && python3 - <<'PY' >/dev/null 2>&1
try:
    import gi
    gi.require_version('Gio', '2.0')
    gi.require_version('GLib', '2.0')
except Exception:
    raise SystemExit(1)
PY
  then
    CAPTURE_TEMPLATE='python3 tests/workspace_portal_screenshot.py {path}'
  fi
fi

PLAN="$OUTPUT_DIR/native-capture-plan.md"
if [[ ! -x "$APP_BIN" ]]; then
  cat > "$PLAN" <<EOF
# Native capture plan

BLOCKED: native binary is missing or not executable:
$APP_BIN

Run npm run tauri:build, then rerun this script.
EOF
  echo "native capture blocked: app binary missing; plan=$PLAN" >&2
  exit 2
fi

if [[ -z "$CAPTURE_TEMPLATE" ]]; then
  cat > "$PLAN" <<EOF
# Native capture plan

Prepared fixture projects:
$FIXTURE_DIR

Native app binary:
$APP_BIN

Automatic capture is blocked because no screenshot command is available in PATH and AGENTDOCK_NATIVE_SCREENSHOT_CMD is unset.

Install one of:
- gnome-screenshot
- grim
- scrot
- spectacle

Or provide a command template, for example:

AGENTDOCK_NATIVE_SCREENSHOT_CMD='gnome-screenshot -f {path}' \
  bash tests/workspace_native_capture_driver.sh "$OUTPUT_DIR"

Manual fallback:
1. Launch each project with:
   $APP_BIN --project "$FIXTURE_DIR/<state>"
2. Save a PNG named <state>.png into:
   $OUTPUT_DIR
3. Import/verify with:
   AGENTDOCK_NATIVE_SCREENSHOT_IMPORT_DIR="$OUTPUT_DIR" AGENTDOCK_NATIVE_RUNTIME_CONFIRMED=1 \
     bash tests/workspace_native_screenshots.sh "$OUTPUT_DIR"

Required states:
- live-normal
- missing-reports
- blocker-present
- final-ready
- dense-20
- dense-50-search-filter
- stale-last-good
- demo-fallback
- error-state
- keyboard-focus
- reduced-motion
- read-only-security
EOF
  echo "native capture blocked: screenshot command missing; plan=$PLAN" >&2
  bash tests/workspace_native_screenshots.sh "$OUTPUT_DIR"
  exit 3
fi

python3 - "$APP_BIN" "$FIXTURE_DIR" "$OUTPUT_DIR" "$CAPTURE_TEMPLATE" <<'PY'
import os, shlex, signal, subprocess, sys, time
from pathlib import Path
app = Path(sys.argv[1])
fixtures = Path(sys.argv[2])
out = Path(sys.argv[3])
template = sys.argv[4]
states = [
  'live-normal', 'missing-reports', 'blocker-present', 'final-ready',
  'dense-20', 'dense-50-search-filter', 'stale-last-good', 'demo-fallback',
  'error-state', 'keyboard-focus', 'reduced-motion', 'read-only-security',
]
out.mkdir(parents=True, exist_ok=True)
for state in states:
    project = fixtures / state
    png = out / f'{state}.png'
    env = os.environ.copy()
    env['AGENTDOCK_BIN'] = str(project / 'bin' / 'agentdock')
    if state == 'reduced-motion':
        env['GTK_ENABLE_ANIMATIONS'] = '0'
    env['AGENTDOCK_NATIVE_EVIDENCE_CAPTURE'] = '1'
    proc = subprocess.Popen([str(app), '--project', str(project)], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        time.sleep(4)
        cmd = template.format(id=shlex.quote(state), path=shlex.quote(str(png)), project=shlex.quote(str(project)))
        print(f'capture {state}: {cmd}')
        subprocess.run(cmd, shell=True, check=True, timeout=20, env=env)
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait(timeout=5)
PY

AGENTDOCK_NATIVE_SCREENSHOT_IMPORT_DIR="$OUTPUT_DIR" AGENTDOCK_NATIVE_RUNTIME_CONFIRMED=1 AGENTDOCK_NATIVE_APP_RUNTIME="$APP_BIN" \
  bash tests/workspace_native_screenshots.sh "$OUTPUT_DIR"
