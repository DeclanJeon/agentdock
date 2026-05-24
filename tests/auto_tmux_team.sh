#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { echo "auto tmux team failed: $*" >&2; exit 1; }
TMP="$(mktemp -d)"
SESSION=""
cleanup() {
  if [[ -n "${SESSION:-}" ]] && command -v tmux >/dev/null 2>&1; then
    tmux kill-session -t "$SESSION" 2>/dev/null || true
  fi
  rm -rf "$TMP"
}
trap cleanup EXIT

for tool in tmux python3; do
  command -v "$tool" >/dev/null 2>&1 || fail "missing required tool: $tool"
done

fakebin="$TMP/bin"
project="$TMP/project"
mkdir -p "$fakebin" "$project/.agentdock" "$project/.agent-work"
cat > "$fakebin/hermes" <<'SH'
#!/usr/bin/env bash
echo "hermes ready"
while IFS= read -r line; do echo "hermes: $line"; done
SH
chmod +x "$fakebin/hermes"
export PATH="$fakebin:$PATH"
export XDG_CONFIG_HOME="$TMP/config"
export AGENTDOCK_BOOT_WAIT_SECONDS=1

cat > "$project/.agentdock/config.runtime" <<EOF_RUNTIME
PROJECT_NAME=auto-team-test
PROJECT_ROOT=$project
SESSION_NAME=auto-team-test-$$
LAYOUT=tiled
ATTACH_ON_START=1
USE_WORKTREES=0
WORK_DIR=.agent-work
AGENT_IDS=ceo-orchestrator developer qa
AGENT_ceo_orchestrator_DISPLAY_NAME=CEO Orchestrator
AGENT_ceo_orchestrator_CLI=hermes
AGENT_ceo_orchestrator_CMD=hermes
AGENT_ceo_orchestrator_PROMPT=.agentdock/prompts/ceo-orchestrator.md
AGENT_ceo_orchestrator_BOOT=.agentdock/generated/boot-ceo-orchestrator.md
AGENT_ceo_orchestrator_WINDOW=agents
AGENT_ceo_orchestrator_CWD_MODE=project_root
AGENT_developer_DISPLAY_NAME=Developer
AGENT_developer_CLI=hermes
AGENT_developer_CMD=hermes
AGENT_developer_PROMPT=.agentdock/prompts/developer.md
AGENT_developer_BOOT=.agentdock/generated/boot-developer.md
AGENT_developer_WINDOW=agents
AGENT_developer_CWD_MODE=project_root
AGENT_qa_DISPLAY_NAME=QA
AGENT_qa_CLI=hermes
AGENT_qa_CMD=hermes
AGENT_qa_PROMPT=.agentdock/prompts/qa.md
AGENT_qa_BOOT=.agentdock/generated/boot-qa.md
AGENT_qa_WINDOW=agents
AGENT_qa_CWD_MODE=project_root
EOF_RUNTIME
SESSION="auto-team-test-$$"

./bin/agentdock start --bootstrap-only --no-attach --project "$project" >/dev/null
before_count="$(tmux list-panes -t "$SESSION" -F '#{pane_id}' | wc -l | tr -d ' ')"
[[ "$before_count" == "1" ]] || fail "bootstrap-only should start only coordinator pane, got $before_count"

./bin/agentdock job --no-attach --project "$project" "백엔드 API를 구현하고 QA 테스트까지 진행해줘" >/dev/null
job="$(sed -n 's/^Active job: //p' "$project/.agent-work/07_JOBS/CURRENT.md" | xargs dirname)"
[[ -d "$job" ]] || fail "job directory missing"

python3 - <<PY
import json, pathlib
job = pathlib.Path('$job')
data = json.loads((job/'ORCHESTRATION.json').read_text())
assert data['mode'] == 'standard_team', data
assert data['requires_qa'] is True, data
roles = data.get('selected_roles') or []
assert 'ceo-orchestrator' in roles, roles
assert 'developer' in roles, roles
assert 'qa' in roles, roles
PY

grep -q '^PANE_developer=' "$project/.agentdock/state/panes.env" || fail "developer was selected but no tmux pane was recorded"
grep -q '^PANE_qa=' "$project/.agentdock/state/panes.env" || fail "qa was selected but no tmux pane was recorded"

developer_pane="$(sed -n 's/^PANE_developer=//p' "$project/.agentdock/state/panes.env" | tail -1)"
qa_pane="$(sed -n 's/^PANE_qa=//p' "$project/.agentdock/state/panes.env" | tail -1)"
tmux list-panes -t "$SESSION" -F '#{pane_id}' | grep -Fxq "$developer_pane" || fail "developer pane is not live in tmux"
tmux list-panes -t "$SESSION" -F '#{pane_id}' | grep -Fxq "$qa_pane" || fail "qa pane is not live in tmux"

grep -q 'Auto-started tmux/Hermes role panes' "$job/LIFECYCLE.md" || fail "lifecycle did not record auto tmux team startup"

tmux kill-session -t "$SESSION" 2>/dev/null || true
SESSION=""

project="$TMP/intake-project"
mkdir -p "$project/.agentdock" "$project/.agent-work"
cat > "$project/.agentdock/config.runtime" <<EOF_RUNTIME
PROJECT_NAME=auto-intake-test
PROJECT_ROOT=$project
SESSION_NAME=auto-intake-test-$$
LAYOUT=tiled
ATTACH_ON_START=1
USE_WORKTREES=0
WORK_DIR=.agent-work
AGENT_IDS=ceo-orchestrator developer qa
AGENT_ceo_orchestrator_DISPLAY_NAME=CEO Orchestrator
AGENT_ceo_orchestrator_CLI=hermes
AGENT_ceo_orchestrator_CMD=hermes
AGENT_ceo_orchestrator_PROMPT=.agentdock/prompts/ceo-orchestrator.md
AGENT_ceo_orchestrator_BOOT=.agentdock/generated/boot-ceo-orchestrator.md
AGENT_ceo_orchestrator_WINDOW=agents
AGENT_ceo_orchestrator_CWD_MODE=project_root
AGENT_developer_DISPLAY_NAME=Developer
AGENT_developer_CLI=hermes
AGENT_developer_CMD=hermes
AGENT_developer_PROMPT=.agentdock/prompts/developer.md
AGENT_developer_BOOT=.agentdock/generated/boot-developer.md
AGENT_developer_WINDOW=agents
AGENT_developer_CWD_MODE=project_root
AGENT_qa_DISPLAY_NAME=QA
AGENT_qa_CLI=hermes
AGENT_qa_CMD=hermes
AGENT_qa_PROMPT=.agentdock/prompts/qa.md
AGENT_qa_BOOT=.agentdock/generated/boot-qa.md
AGENT_qa_WINDOW=agents
AGENT_qa_CWD_MODE=project_root
EOF_RUNTIME
SESSION="auto-intake-test-$$"

./bin/agentdock start --bootstrap-only --no-attach --project "$project" >/dev/null
./bin/agentdock intake --from ceo-orchestrator --request "API 변경을 구현하고 QA 검증까지 진행해줘" --project "$project" >/dev/null
job="$(sed -n 's/^Active job: //p' "$project/.agent-work/07_JOBS/CURRENT.md" | xargs dirname)"
[[ -d "$job" ]] || fail "intake job directory missing"
grep -q '^PANE_developer=' "$project/.agentdock/state/panes.env" || fail "intake did not auto-start developer tmux pane"
grep -q '^PANE_qa=' "$project/.agentdock/state/panes.env" || fail "intake did not auto-start qa tmux pane"
grep -q 'Auto-started tmux/Hermes role panes' "$job/LIFECYCLE.md" || fail "intake lifecycle did not record auto tmux team startup"

echo "auto tmux team ok"
