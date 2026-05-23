#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { echo "workspace tft artifacts failed: $*" >&2; exit 1; }
TMP="$(mktemp -d)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

fakebin="$TMP/bin"
project="$TMP/project"
mkdir -p "$fakebin" "$project/.agentdock" "$project/.agent-work"
cat > "$fakebin/tmux" <<'SH'
#!/usr/bin/env bash
case "${1:-}" in
  has-session) exit 0 ;;
  list-panes) exit 0 ;;
  send-keys) exit 0 ;;
  kill-pane) exit 0 ;;
  *) exit 0 ;;
esac
SH
chmod +x "$fakebin/tmux"
cat > "$fakebin/hermes" <<'SH'
#!/usr/bin/env bash
exit 0
SH
chmod +x "$fakebin/hermes"
cat > "$project/.agentdock/config.runtime" <<EOF_RUNTIME
PROJECT_NAME=tft-test
PROJECT_ROOT=$project
SESSION_NAME=tft-test-agents
LAYOUT=tiled
ATTACH_ON_START=1
USE_WORKTREES=0
WORK_DIR=.agent-work
AGENT_IDS=orchestrator developer qa-specialist
AGENT_orchestrator_DISPLAY_NAME=orchestrator
AGENT_orchestrator_CLI=hermes
AGENT_orchestrator_CMD=hermes
AGENT_orchestrator_PROMPT=.agentdock/prompts/orchestrator.md
AGENT_orchestrator_BOOT=.agentdock/generated/boot-orchestrator.md
AGENT_orchestrator_WINDOW=agents
AGENT_orchestrator_CWD_MODE=project_root
AGENT_developer_DISPLAY_NAME=developer
AGENT_developer_CLI=hermes
AGENT_developer_CMD=hermes
AGENT_developer_PROMPT=.agentdock/prompts/developer.md
AGENT_developer_BOOT=.agentdock/generated/boot-developer.md
AGENT_developer_WINDOW=agents
AGENT_developer_CWD_MODE=project_root
AGENT_qa_specialist_DISPLAY_NAME=qa specialist
AGENT_qa_specialist_CLI=hermes
AGENT_qa_specialist_CMD=hermes
AGENT_qa_specialist_PROMPT=.agentdock/prompts/qa-specialist.md
AGENT_qa_specialist_BOOT=.agentdock/generated/boot-qa-specialist.md
AGENT_qa_specialist_WINDOW=agents
AGENT_qa_specialist_CWD_MODE=project_root
EOF_RUNTIME

env PATH="$fakebin:$PATH" ./bin/agentdock job --no-attach --project "$project" "TFT가 필요한 복잡한 설계 검토와 팀 조율을 진행해줘" >/dev/null
env PATH="$fakebin:$PATH" ./bin/agentdock job tft create --name "UI Stabilization" --members orchestrator,developer,qa-specialist --goal "Fix layout blocker" --exit-condition "QA accepts UI" --blocking --project "$project" >/dev/null
env PATH="$fakebin:$PATH" ./bin/agentdock workspace snapshot --json --project "$project" > "$TMP/snapshot.json"
python3 - <<PY
import json
snap=json.load(open('$TMP/snapshot.json'))
tfts=snap.get('tfts') or []
assert any(t.get('name') == 'UI Stabilization' and t.get('status') == 'active' for t in tfts), tfts
assert any(a.get('type') == 'blocking_tft' for a in snap.get('alerts', [])), snap.get('alerts')
PY
if env PATH="$fakebin:$PATH" ./bin/agentdock job finish --summary done --project "$project" >"$TMP/finish.out" 2>"$TMP/finish.err"; then
  fail "finish should be blocked by active blocking TFT"
fi
grep -qi 'Blocking TFT is still active' "$TMP/finish.err" || fail "missing blocking TFT finish error"
env PATH="$fakebin:$PATH" ./bin/agentdock job tft close --name "UI Stabilization" --summary "Resolved" --project "$project" >/dev/null
env PATH="$fakebin:$PATH" ./bin/agentdock workspace snapshot --json --project "$project" > "$TMP/snapshot2.json"
python3 - <<PY
import json
snap=json.load(open('$TMP/snapshot2.json'))
tfts=snap.get('tfts') or []
assert any(t.get('name') == 'UI Stabilization' and t.get('status') == 'closed' for t in tfts), tfts
PY

echo "workspace tft artifacts ok"
