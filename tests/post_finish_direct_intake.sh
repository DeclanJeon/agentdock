#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { echo "post-finish direct intake failed: $*" >&2; exit 1; }
TMP="$(mktemp -d)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

fakebin="$TMP/bin"
mkdir -p "$fakebin"
cat > "$fakebin/tmux" <<'SH'
#!/usr/bin/env bash
log="${AGENTDOCK_FAKE_TMUX_LOG:-/tmp/agentdock-fake-tmux.log}"
printf '%s\n' "$*" >> "$log"
case "${1:-}" in
  has-session) exit 0 ;;
  list-panes)
    if [[ "${AGENTDOCK_FAKE_TMUX_LIST_PANES:-}" == "with-orchestrator" ]]; then
      echo "%100"
    fi
    exit 0
    ;;
  display-message) echo "%100"; exit 0 ;;
  new-window|split-window) echo "%100"; exit 0 ;;
  select-layout|select-pane|send-keys|kill-pane|load-buffer|paste-buffer) exit 0 ;;
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
  local project="$1" roles="${2:-orchestrator developer agentdock-qa system-architect}"
  mkdir -p "$project/.agentdock" "$project/.agent-work" "$project/.agentdock/prompts" "$project/.agentdock/generated"
  cat > "$project/.agentdock/config.runtime" <<EOF_RUNTIME
PROJECT_NAME=test
PROJECT_ROOT=$project
SESSION_NAME=test-agents
LAYOUT=windows
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
AGENT_developer_DISPLAY_NAME=developer
AGENT_developer_CLI=hermes
AGENT_developer_CMD=hermes
AGENT_developer_PROMPT=.agentdock/prompts/developer.md
AGENT_developer_BOOT=.agentdock/generated/boot-developer.md
AGENT_developer_WINDOW=agents
AGENT_developer_CWD_MODE=project_root
AGENT_agentdock_qa_DISPLAY_NAME=agentdock-qa
AGENT_agentdock_qa_CLI=hermes
AGENT_agentdock_qa_CMD=hermes
AGENT_agentdock_qa_PROMPT=.agentdock/prompts/agentdock-qa.md
AGENT_agentdock_qa_BOOT=.agentdock/generated/boot-agentdock-qa.md
AGENT_agentdock_qa_WINDOW=agents
AGENT_agentdock_qa_CWD_MODE=project_root
AGENT_system_architect_DISPLAY_NAME=system-architect
AGENT_system_architect_CLI=hermes
AGENT_system_architect_CMD=hermes
AGENT_system_architect_PROMPT=.agentdock/prompts/system-architect.md
AGENT_system_architect_BOOT=.agentdock/generated/boot-system-architect.md
AGENT_system_architect_WINDOW=agents
AGENT_system_architect_CWD_MODE=project_root
EOF_RUNTIME
}

job_dir_for() {
  sed -n 's/^Active job: //p' "$1/.agent-work/07_JOBS/CURRENT.md" | head -1 | xargs dirname
}

json_field() {
  python3 - "$1" "$2" <<'PY'
import json, sys
path, field = sys.argv[1:3]
data = json.load(open(path, encoding='utf-8'))
value = data
for part in field.split('.'):
    value = value[part]
if isinstance(value, bool):
    print('true' if value else 'false')
else:
    print(value)
PY
}

project="$TMP/finish-clears-current"
make_project "$project"
env PATH="$fakebin:$PATH" ./bin/agentdock job --no-attach --project "$project" "문서 오타를 수정해줘" >/dev/null
job="$(job_dir_for "$project")"
env PATH="$fakebin:$PATH" ./bin/agentdock job finish --project "$project" --summary "solo docs done" >/dev/null
[[ -f "$project/.agent-work/07_JOBS/LAST_FINISHED.md" ]] || fail "LAST_FINISHED.md not written"
[[ ! -f "$project/.agent-work/07_JOBS/CURRENT.md" ]] || fail "CURRENT.md should be cleared after finish"
grep -q "Final report:" "$project/.agent-work/07_JOBS/LAST_FINISHED.md" || fail "LAST_FINISHED.md missing final report path"

project="$TMP/completed-current"
make_project "$project"
completed="$project/.agent-work/07_JOBS/JOB-completed"
mkdir -p "$completed/TASKS" "$completed/REPORTS"
printf '# done\n' > "$completed/README.md"
printf '# Lifecycle\n\nStatus: complete\n' > "$completed/LIFECYCLE.md"
printf 'Active job: %s\n' "$completed/README.md" > "$project/.agent-work/07_JOBS/CURRENT.md"
env PATH="$fakebin:$PATH" ./bin/agentdock intake --from orchestrator --project "$project" --request "문서 오타를 수정해줘" >/dev/null
new_job="$(job_dir_for "$project")"
[[ "$new_job" != "$completed" ]] || fail "completed CURRENT blocked new intake"
[[ "$(json_field "$new_job/ORCHESTRATION.json" mode)" == "solo_direct" ]] || fail "intake did not classify simple request as solo_direct"

project="$TMP/failed-current"
make_project "$project"
failed="$project/.agent-work/07_JOBS/JOB-failed"
mkdir -p "$failed/TASKS" "$failed/REPORTS"
printf '# failed\n' > "$failed/README.md"
printf '# Lifecycle\n\nStatus: Failed\n' > "$failed/LIFECYCLE.md"
printf 'Active job: %s\n' "$failed/README.md" > "$project/.agent-work/07_JOBS/CURRENT.md"
env PATH="$fakebin:$PATH" ./bin/agentdock intake --from orchestrator --project "$project" --request "문서 오타를 수정해줘" >/dev/null
new_job="$(job_dir_for "$project")"
[[ "$new_job" != "$failed" ]] || fail "failed CURRENT blocked new intake"

project="$TMP/team-intake"
make_project "$project"
env PATH="$fakebin:$PATH" ./bin/agentdock intake --from orchestrator --project "$project" --request "CLI 흐름과 QA 게이트를 구현하고 테스트해줘" >/dev/null
job="$(job_dir_for "$project")"
[[ "$(json_field "$job/ORCHESTRATION.json" mode)" == "standard_team" ]] || fail "intake did not classify implementation QA request as standard_team"
[[ "$(json_field "$job/ORCHESTRATION.json" requires_qa)" == "true" ]] || fail "standard team intake should require QA"
[[ -f "$job/QA.md" ]] || fail "QA.md missing for QA-required intake"

project="$TMP/security-intake"
make_project "$project"
env PATH="$fakebin:$PATH" ./bin/agentdock intake --from orchestrator --project "$project" --request "권한과 토큰 보안 로직을 수정하고 검토해줘" >/dev/null
job="$(job_dir_for "$project")"
[[ "$(json_field "$job/ORCHESTRATION.json" mode)" == "critical_review" ]] || fail "security intake should classify as critical_review"
[[ "$(json_field "$job/ORCHESTRATION.json" requires_security_review)" == "true" ]] || fail "security intake should require security review"

project="$TMP/unfinished-active"
make_project "$project"
env PATH="$fakebin:$PATH" ./bin/agentdock job --no-attach --project "$project" "CLI 흐름을 구현해줘" >/dev/null
set +e
out="$(env PATH="$fakebin:$PATH" ./bin/agentdock intake --from orchestrator --project "$project" --request "새 문서 작업" 2>&1)"
status=$?
set -e
[[ "$status" -ne 0 ]] || fail "unfinished active job should block silent intake overwrite"
printf '%s' "$out" | grep -q "active unfinished job exists" || fail "unfinished active job refusal should be explicit"

project="$TMP/boot-prompt"
make_project "$project"
env PATH="$fakebin:$PATH" ./bin/agentdock start --bootstrap-only --no-attach --project "$project" >/dev/null
boot="$project/.agentdock/generated/boot-orchestrator.md"
grep -q "unfinished" "$boot" || fail "boot prompt must mention unfinished active jobs"
grep -q "agentdock intake" "$boot" || fail "boot prompt must mention agentdock intake"
grep -q "agentdock recruit" "$boot" || fail "boot prompt must preserve tmux recruit semantics"
grep -q "native subagents" "$boot" || fail "boot prompt must forbid native subagents"
! grep -q "If \.agent-work/07_JOBS/CURRENT.md exists and your role is CEO/orchestrator" "$boot" || fail "boot prompt still treats raw CURRENT.md existence as active"

project="$TMP/stale-pane"
make_project "$project"
mkdir -p "$project/.agentdock/state"
printf 'PANE_orchestrator=%%999\n' > "$project/.agentdock/state/panes.env"
env PATH="$fakebin:$PATH" ./bin/agentdock send orchestrator "hello" --project "$project" >/dev/null
! grep -q '%999' "$project/.agentdock/state/panes.env" || fail "stale pane mapping was not removed"
compgen -G "$project/.agent-work/12_INBOX/orchestrator/*" >/dev/null || fail "inbox message was not written when pane was stale"

echo "post-finish direct intake ok"
