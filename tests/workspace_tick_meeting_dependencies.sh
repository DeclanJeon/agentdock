#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { echo "workspace tick/meeting/dependencies failed: $*" >&2; exit 1; }
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
PROJECT_NAME=tick-test
PROJECT_ROOT=$project
SESSION_NAME=tick-test-agents
LAYOUT=tiled
ATTACH_ON_START=1
USE_WORKTREES=0
WORK_DIR=.agent-work
AGENT_IDS=orchestrator developer qa-specialist reviewer
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
AGENT_reviewer_DISPLAY_NAME=reviewer
AGENT_reviewer_CLI=hermes
AGENT_reviewer_CMD=hermes
AGENT_reviewer_PROMPT=.agentdock/prompts/reviewer.md
AGENT_reviewer_BOOT=.agentdock/generated/boot-reviewer.md
AGENT_reviewer_WINDOW=agents
AGENT_reviewer_CWD_MODE=project_root
EOF_RUNTIME

env PATH="$fakebin:$PATH" ./bin/agentdock job --no-attach --project "$project" "React UI와 Tauri bridge를 구현하고 테스트까지 진행해줘" >/dev/null
job="$(sed -n 's/^Active job: //p' "$project/.agent-work/07_JOBS/CURRENT.md" | xargs dirname)"
[[ -f "$job/DEPENDENCIES.json" ]] || fail "DEPENDENCIES.json missing"
grep -q '| developer | configured role | reuse |' "$job/TEAM.md" || fail "developer reuse row missing"
grep -q '| qa-specialist | configured role | reuse |' "$job/TEAM.md" || fail "qa reuse row missing"
[[ -f "$job/TASKS/developer.md" ]] || fail "developer task card missing"
cat >> "$job/TASKS/developer.md" <<'MD'

## Shared files
- src-ui/App.tsx
MD
cat >> "$job/TASKS/qa-specialist.md" <<'MD'

## Shared files
- src-ui/App.tsx
MD

env PATH="$fakebin:$PATH" ./bin/agentdock job report --from developer --summary "Implementation started; blocked by qa-specialist for test criteria." --project "$project" >/dev/null
env PATH="$fakebin:$PATH" ./bin/agentdock workspace snapshot --json --project "$project" > "$TMP/snapshot.json"
python3 - <<PY
import json
snap=json.load(open('$TMP/snapshot.json'))
items=snap.get('dependencies',{}).get('items',[])
assert any(i.get('role') == 'developer' and i.get('waiting_on') == 'qa-specialist' for i in items), items
assert any(a.get('type') == 'dependency' for a in snap.get('alerts', [])), snap.get('alerts')
conflicts=snap.get('write_conflicts',{}).get('items',[])
assert any(c.get('file') == 'src-ui/App.tsx' for c in conflicts), conflicts
assert any(a.get('type') == 'write_conflict' for a in snap.get('alerts', [])), snap.get('alerts')
assert snap.get('communications',{}).get('items'), snap.get('communications')
PY

env PATH="$fakebin:$PATH" ./bin/agentdock job meeting start --title "Bridge Contract" --reason tradeoff --proposals "Use event bridge;Use polling" --project "$project" >/dev/null
env PATH="$fakebin:$PATH" ./bin/agentdock job meeting conclude --title "Bridge Contract" --decision "Use event bridge with snapshot fallback" --rejected "Polling-only UI" --actions "Developer implements bridge;QA verifies" --project "$project" >/dev/null
env PATH="$fakebin:$PATH" ./bin/agentdock workspace snapshot --json --project "$project" > "$TMP/snapshot2.json"
python3 - <<PY
import json
snap=json.load(open('$TMP/snapshot2.json'))
meetings=snap.get('meetings',{}).get('items',[])
assert any(m.get('title') == 'Bridge Contract' and m.get('status') == 'concluded' and 'event bridge' in m.get('decision','') for m in meetings), meetings
PY

env PATH="$fakebin:$PATH" ./bin/agentdock job tick --json --project "$project" > "$TMP/tick.json"
python3 - <<PY
import json
j=json.load(open('$TMP/tick.json'))
assert j['action'] in {'request_qa_report','follow_up_missing_report','resolve_blocking_tft','suggest_finish'}, j
assert 'recruit' not in j.get('command','').lower(), j
PY

echo "workspace tick/meeting/dependencies ok"
