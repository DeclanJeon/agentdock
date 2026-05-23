#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { echo "workspace adaptive orchestration failed: $*" >&2; exit 1; }
TMP="$(mktemp -d)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

fakebin="$TMP/bin"
mkdir -p "$fakebin"
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
if [[ "${1:-} ${2:-}" == "config path" ]]; then echo "$TMP/hermes.yaml"; exit 0; fi
exit 0
SH
chmod +x "$fakebin/hermes"

make_project() {
  local project="$1" roles="${2:-orchestrator qa-specialist reviewer developer}"
  mkdir -p "$project/.agentdock" "$project/.agent-work"
  cat > "$project/.agentdock/config.runtime" <<EOF_RUNTIME
PROJECT_NAME=test
PROJECT_ROOT=$project
SESSION_NAME=test-agents
LAYOUT=tiled
ATTACH_ON_START=1
USE_WORKTREES=0
WORK_DIR=.agent-work
AGENT_IDS=$roles
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
AGENT_reviewer_DISPLAY_NAME=reviewer
AGENT_reviewer_CLI=hermes
AGENT_reviewer_CMD=hermes
AGENT_reviewer_PROMPT=.agentdock/prompts/reviewer.md
AGENT_reviewer_BOOT=.agentdock/generated/boot-reviewer.md
AGENT_reviewer_WINDOW=agents
AGENT_reviewer_CWD_MODE=project_root
AGENT_developer_DISPLAY_NAME=developer
AGENT_developer_CLI=hermes
AGENT_developer_CMD=hermes
AGENT_developer_PROMPT=.agentdock/prompts/developer.md
AGENT_developer_BOOT=.agentdock/generated/boot-developer.md
AGENT_developer_WINDOW=agents
AGENT_developer_CWD_MODE=project_root
EOF_RUNTIME
}

job_dir_for() {
  sed -n 's/^Active job: //p' "$1/.agent-work/07_JOBS/CURRENT.md" | xargs dirname
}

project="$TMP/solo"
make_project "$project"
env PATH="$fakebin:$PATH" ./bin/agentdock job --no-attach --project "$project" "문서 오타를 수정해줘" >/dev/null
job="$(job_dir_for "$project")"
[[ -f "$job/ORCHESTRATION.json" ]] || fail "solo job missing ORCHESTRATION.json"
python3 - <<PY
import json, pathlib, sys
job=pathlib.Path('$job')
data=json.loads((job/'ORCHESTRATION.json').read_text())
assert data['mode'] == 'solo_direct', data
assert data['requires_qa'] is False, data
team=(job/'TEAM.md').read_text()
assert 'No specialist recommendation' in team, team
PY

project="$TMP/team"
make_project "$project"
env PATH="$fakebin:$PATH" ./bin/agentdock job --no-attach --project "$project" "CLI 작업 흐름과 QA 게이트를 구현하고 테스트까지 진행해줘" >/dev/null
job="$(job_dir_for "$project")"
python3 - <<PY
import json, pathlib
job=pathlib.Path('$job')
data=json.loads((job/'ORCHESTRATION.json').read_text())
assert data['mode'] == 'standard_team', data
assert data['requires_qa'] is True, data
assert (job/'QA.md').exists()
PY

project="$TMP/security"
make_project "$project"
env PATH="$fakebin:$PATH" ./bin/agentdock job --no-attach --project "$project" "권한과 토큰 보안 로직을 수정하고 검토해줘" >/dev/null
job="$(job_dir_for "$project")"
python3 - <<PY
import json, pathlib
job=pathlib.Path('$job')
data=json.loads((job/'ORCHESTRATION.json').read_text())
assert data['mode'] == 'critical_review', data
assert data['requires_security_review'] is True, data
PY

echo "workspace adaptive orchestration ok"
