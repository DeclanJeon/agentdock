#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { echo "workspace action audit test failed: $*" >&2; exit 1; }
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
PROJECT_NAME=audit-test
PROJECT_ROOT=$project
SESSION_NAME=audit-test-agents
LAYOUT=tiled
ATTACH_ON_START=1
USE_WORKTREES=0
WORK_DIR=.agent-work
AGENT_IDS=orchestrator qa-specialist
AGENT_orchestrator_DISPLAY_NAME=orchestrator
AGENT_orchestrator_CLI=hermes
AGENT_orchestrator_CMD=hermes
AGENT_orchestrator_PROMPT=.agentdock/prompts/orchestrator.md
AGENT_orchestrator_BOOT=.agentdock/generated/boot-orchestrator.md
AGENT_orchestrator_WINDOW=agents
AGENT_orchestrator_CWD_MODE=project_root
AGENT_qa_specialist_DISPLAY_NAME=qa specialist
AGENT_qa_specialist_CLI=hermes
AGENT_qa_specialist_CMD=hermes
AGENT_qa_specialist_PROMPT=.agentdock/prompts/qa-specialist.md
AGENT_qa_specialist_BOOT=.agentdock/generated/boot-qa-specialist.md
AGENT_qa_specialist_WINDOW=agents
AGENT_qa_specialist_CWD_MODE=project_root
EOF_RUNTIME

env PATH="$fakebin:$PATH" ./bin/agentdock job --no-attach --project "$project" "CLI 보고서 흐름과 QA를 검증해줘" >/dev/null
job="$(sed -n 's/^Active job: //p' "$project/.agent-work/07_JOBS/CURRENT.md" | xargs dirname)"
[[ -f "$job/ACTIONS.md" ]] || fail "ACTIONS.md missing after job start"
grep -q '| .* | .* | job_start | ok |' "$job/ACTIONS.md" || fail "job_start audit missing"

env PATH="$fakebin:$PATH" ./bin/agentdock job report --from qa-specialist --summary "QA passed. token=SECRET should stay in raw report only." --project "$project" >/dev/null
grep -q '| .* | qa-specialist | job_report | ok |' "$job/ACTIONS.md" || fail "job_report audit missing"

env PATH="$fakebin:$PATH" ./bin/agentdock workspace snapshot --json --project "$project" > "$TMP/snapshot.json"
python3 - <<PY
import json
snap=json.load(open('$TMP/snapshot.json'))
items=snap.get('communications',{}).get('items',[])
assert any(i.get('action') == 'job_start' for i in items), items
assert any(i.get('action') == 'job_report' for i in items), items
PY

echo "workspace action audit ok"
