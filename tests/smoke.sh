#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"

if (( BASH_VERSINFO[0] < 4 )); then
  echo "smoke test requires Bash 4+" >&2
  exit 1
fi
for tool in tmux awk sed grep find sort cksum mktemp; do
  command -v "$tool" >/dev/null 2>&1 || { echo "missing required tool: $tool" >&2; exit 1; }
done
if ! command -v python3 >/dev/null 2>&1 && ! command -v node >/dev/null 2>&1; then
  echo "smoke test requires python3 or node for JSON validation" >&2
  exit 1
fi

json_validate() {
  if command -v python3 >/dev/null 2>&1; then
    python3 -m json.tool >/dev/null
  else
    node -e 'let s="";process.stdin.on("data",d=>s+=d);process.stdin.on("end",()=>JSON.parse(s));'
  fi
}

replace_in_file() {
  local expr="$1" file="$2" tmp
  tmp="$(mktemp "${TMPDIR:-/tmp}/agentdock-sed.XXXXXX")"
  sed "$expr" "$file" > "$tmp"
  mv "$tmp" "$file"
}

cleanup() {
  if command -v tmux >/dev/null 2>&1; then
    [[ -n "${SESSION:-}" ]] && tmux kill-session -t "$SESSION" 2>/dev/null || true
    tmux kill-session -t project-agents 2>/dev/null || true
  fi
  rm -rf "$TMP"
}
trap cleanup EXIT

FAKE="$TMP/fakebin"
mkdir -p "$FAKE" "$TMP/project"
cat > "$FAKE/fakeai" <<'EOF'
#!/usr/bin/env bash
echo "fakeai ready"
while IFS= read -r line; do echo "fakeai: $line"; done
EOF
chmod +x "$FAKE/fakeai"
cat > "$FAKE/hermes" <<'EOF'
#!/usr/bin/env bash
echo "hermes ready"
while IFS= read -r line; do echo "hermes: $line"; done
EOF
chmod +x "$FAKE/hermes"

cat > "$FAKE/hangai" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "--version" ]]; then
  sleep 30
  exit 0
fi
echo "hangai ready"
while IFS= read -r line; do echo "hangai: $line"; done
EOF
chmod +x "$FAKE/hangai"

export PATH="$FAKE:$PATH"
export XDG_CONFIG_HOME="$TMP/config"
export AGENTDOCK_ADAPTER_VERSION_TIMEOUT="1s"
tmux kill-session -t project-agents 2>/dev/null || true
"$ROOT/bin/agentdock" version | grep -q 'agentdock 0.3.1'
ln -sf "$ROOT/bin/agentdock" "$FAKE/adock"
ln -sf "$ROOT/bin/agentdock" "$FAKE/adock-delegate"
adock version | grep -q 'agentdock 0.3.1'

MISS="$TMP/missing-hermes"
mkdir -p "$MISS/fakebin" "$MISS/project"
cat > "$MISS/fakebin/tmux" <<'EOF'
#!/usr/bin/env bash
echo "tmux 3.4"
EOF
chmod +x "$MISS/fakebin/tmux"
(
  cd "$MISS/project"
  PATH="$MISS/fakebin:/usr/bin:/bin" "$ROOT/bin/agentdock" init >/dev/null
  if PATH="$MISS/fakebin:/usr/bin:/bin" "$ROOT/bin/agentdock" start --no-attach > "$MISS/start.out" 2>&1; then
    echo "start should fail when hermes is missing" >&2
    exit 1
  fi
  grep -q 'github.com/nousresearch/hermes-agent' "$MISS/start.out"
  grep -q 'raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh' "$MISS/start.out"
)

"$ROOT/bin/agentdock" cli add --id fakeai --command fakeai --install "true"
"$ROOT/bin/agentdock" install fakeai --yes | grep -q 'fakeai'
"$ROOT/bin/agentdock" cli add --id hangai --command hangai --install "true"
HANG_START="$(date +%s)"
"$ROOT/bin/agentdock" install hangai --yes > "$TMP/hangai-install.out"
HANG_ELAPSED="$(( $(date +%s) - HANG_START ))"
test "$HANG_ELAPSED" -lt 10
grep -q 'hangai' "$TMP/hangai-install.out"
grep -q 'unknown' "$TMP/hangai-install.out"
"$ROOT/bin/agentdock" cli add --id unsafe --command missingunsafe --install "rm -rf /" >/dev/null
if "$ROOT/bin/agentdock" install unsafe --yes > "$TMP/unsafe.out" 2>&1; then
  echo "unsupported install command should fail" >&2
  exit 1
fi
grep -q 'unsupported install command pattern' "$TMP/unsafe.out"
"$ROOT/bin/agentdock" setup --skip-cli --yes > "$TMP/setup.out"
grep -q 'AgentDock Doctor' "$TMP/setup.out"
grep -q 'Agent CLI:' "$TMP/setup.out"
grep -q 'OK  hermes' "$TMP/setup.out"
! grep -q '^OK  codex' "$TMP/setup.out"
"$ROOT/bin/agentdock" doctor --json | grep -q '"system"'
"$ROOT/bin/agentdock" doctor --json | grep -q '"agent_cli"'
"$ROOT/bin/agentdock" doctor --json | json_validate

mkdir -p "$TMP/collision-a/project" "$TMP/collision-b/project"
( cd "$TMP/collision-a/project" && "$ROOT/bin/agentdock" init >/dev/null )
( cd "$TMP/collision-b/project" && "$ROOT/bin/agentdock" init >/dev/null )
SESSION_A="$(cd "$TMP/collision-a/project" && bash -c 'source .agentdock/config.runtime; printf "%s" "$SESSION_NAME"')"
SESSION_B="$(cd "$TMP/collision-b/project" && bash -c 'source .agentdock/config.runtime; printf "%s" "$SESSION_NAME"')"
[[ "$SESSION_A" != "$SESSION_B" ]]
[[ "$SESSION_A" == project-*-agents ]]
[[ "$SESSION_B" == project-*-agents ]]

SPECIAL="$TMP/json \"quoted\" path/project"
mkdir -p "$SPECIAL"
( cd "$SPECIAL" && "$ROOT/bin/agentdock" init >/dev/null && "$ROOT/bin/agentdock" report --json | json_validate )

! grep -R 'sed -''i' "$ROOT/bin/agentdock" "$ROOT/tests/smoke.sh"
! grep -n '\beval\b' "$ROOT/bin/agentdock"

cd "$TMP/project"
"$ROOT/bin/agentdock" init
SESSION="$(bash -c 'source .agentdock/config.runtime; printf "%s" "$SESSION_NAME"')"
ROOT_HASH="$(printf '%s' "$PWD" | cksum | awk '{print $1}')"
[[ "$SESSION" == "project-$ROOT_HASH-agents" ]]
"$ROOT/bin/agentdock" role add legacy-codex --cli hermes >/dev/null
replace_in_file 's/^AGENT_legacy_codex_CLI=.*/AGENT_legacy_codex_CLI=codex/' .agentdock/config.runtime
replace_in_file 's/^AGENT_legacy_codex_CMD=.*/AGENT_legacy_codex_CMD=codex/' .agentdock/config.runtime
"$ROOT/bin/agentdock" assign ceo-orchestrator hermes
if "$ROOT/bin/agentdock" assign ceo-orchestrator codex 2>/dev/null; then
  echo "codex assignment should be rejected in Hermes-only runtime" >&2
  exit 1
fi
test -f .agentdock/config.yml
test -f .agentdock/config.runtime
test -f .agentdock/generated/boot-ceo-orchestrator.md
grep -q "Codex native subagents" .agentdock/generated/boot-ceo-orchestrator.md
grep -q "adock-delegate --from ceo-orchestrator" .agentdock/generated/boot-ceo-orchestrator.md
"$ROOT/bin/agentdock" team > "$TMP/team.out"
grep -q ceo-orchestrator "$TMP/team.out"
"$ROOT/bin/agentdock" roles list > "$TMP/roles.out"
grep -q bmad-agent-dev "$TMP/roles.out"
grep -q agentdock-qa "$TMP/roles.out"
"$ROOT/bin/agentdock" roles sync bmad --offline --yes
test -f "$XDG_CONFIG_HOME/agentdock/roles/bmad/bmad-agent-dev.md"
BMAD_FIXTURE="$TMP/bmad-source"
for path in \
  src/bmm-skills/1-analysis/bmad-agent-analyst/SKILL.md \
  src/bmm-skills/1-analysis/bmad-agent-tech-writer/SKILL.md \
  src/bmm-skills/2-plan-workflows/bmad-agent-pm/SKILL.md \
  src/bmm-skills/2-plan-workflows/bmad-agent-ux-designer/SKILL.md \
  src/bmm-skills/3-solutioning/bmad-agent-architect/SKILL.md \
  src/bmm-skills/4-implementation/bmad-agent-dev/SKILL.md; do
  mkdir -p "$BMAD_FIXTURE/$(dirname "$path")"
  {
    printf '%s\n' '---'
    printf '%s\n' 'name: fixture-bmad-agent'
    printf '%s\n' 'description: Fixture BMAD agent prompt for AgentDock sync tests.'
    printf '%s\n' '---'
    printf '%s\n\n' '# Fixture BMAD Agent'
    printf '%s\n' 'Agent persona role commands activation Developer Architect Analyst Product Manager UX Technical Writer.'
    printf 'Fixture prompt body %.0s' {1..80}
    printf '\n'
  } > "$BMAD_FIXTURE/$path"
done
XDG_CONFIG_HOME="$TMP/bmad-sync-config" "$ROOT/bin/agentdock" roles sync bmad --yes --url "$BMAD_FIXTURE"
test -f "$TMP/bmad-sync-config/agentdock/roles/bmad/bmad-agent-dev.md"
grep -q 'Fixture BMAD Agent' "$TMP/bmad-sync-config/agentdock/roles/bmad/bmad-agent-dev.md"
grep -q 'src/bmm-skills/4-implementation/bmad-agent-dev/SKILL.md' "$TMP/bmad-sync-config/agentdock/roles/bmad/bmad-agent-dev.md"
(
  mkdir -p "$TMP/recruit-sync-project"
  cd "$TMP/recruit-sync-project"
  XDG_CONFIG_HOME="$TMP/recruit-sync-config" "$ROOT/bin/agentdock" init --roles orchestrator >/dev/null
  XDG_CONFIG_HOME="$TMP/recruit-sync-config" "$ROOT/bin/agentdock" recruit api-dev --template bmad-agent-dev --sync-template --template-url "$BMAD_FIXTURE" --skip-missing --mission "Fixture mission" >/dev/null
  grep -q 'Fixture BMAD Agent' .agentdock/prompts/api-dev.md
  grep -q 'Fixture mission' .agentdock/prompts/api-dev.md
)
"$ROOT/bin/agentdock" start --no-attach --skip-missing
grep -Eq '^AGENT_ceo_orchestrator_CLI="?hermes"?$' .agentdock/config.runtime
grep -q 'Assigned CLI: hermes' .agentdock/generated/boot-legacy-codex.md
tmux has-session -t "$SESSION"
test -s .agentdock/state/panes.env
test "$(wc -l < .agentdock/state/panes.env)" -eq 2
tmux list-windows -t "$SESSION" -F '#{window_name}' | grep -qx ceo-orchestrator
grep -q PANE_legacy_codex .agentdock/state/panes.env
tmux capture-pane -p -S -2000 -t "$SESSION:ceo-orchestrator.0" | grep -F "$TMP/project/.agentdock/generated/boot-ceo-orchestrator.md"
tmux capture-pane -p -S -2000 -t "$SESSION:ceo-orchestrator.0" | grep -F -- "--- BEGIN AGENTDOCK BOOT ceo-orchestrator ---"
"$ROOT/bin/agentdock" recruit analyst reviewer --template bmad-agent-dev --cli hermes --mission "Analyze implementation options for the active job." --instructions "Produce concise tradeoffs and hand off execution tasks."
"$ROOT/bin/agentdock" recruit qa-check --template qa --cli hermes --mission "Verify acceptance criteria and regression risk." --instructions "Report risks and validation evidence."
grep -q PANE_analyst .agentdock/state/panes.env
grep -q PANE_reviewer .agentdock/state/panes.env
grep -q PANE_qa_check .agentdock/state/panes.env
grep -q PANE_ceo_orchestrator .agentdock/state/panes.env
tmux capture-pane -p -S -2000 -t "$SESSION:reviewer.0" | grep -F -- "--- BEGIN AGENTDOCK BOOT reviewer ---"
tmux capture-pane -p -S -2000 -t "$SESSION:qa-check.0" | grep -F -- "--- BEGIN AGENTDOCK BOOT qa-check ---"
grep -q 'Fast Worker Boot: reviewer' .agentdock/generated/boot-reviewer.md
grep -q "Analyze implementation options" .agentdock/prompts/analyst.md
grep -q "Analyze implementation options" .agentdock/prompts/reviewer.md
grep -q "QA / Quality Engineer" .agentdock/prompts/qa-check.md
"$ROOT/bin/agentdock" broadcast --from ceo-orchestrator "Shared decision: use the faster team broadcast path"
grep -q 'Shared decision: use the faster team broadcast path' .agent-work/14_SHARED_CONTEXT/BROADCASTS.md
grep -q 'Shared decision: use the faster team broadcast path' .agent-work/12_INBOX/analyst/*.md
"$ROOT/bin/agentdock" send all "Shared update through send all"
grep -q 'Shared update through send all' .agent-work/14_SHARED_CONTEXT/BROADCASTS.md
grep -q 'Shared update through send all' .agent-work/12_INBOX/reviewer/*.md
"$ROOT/bin/agentdock" inbox > "$TMP/inbox.out"
grep -q 'AgentDock Inbox Digest' "$TMP/inbox.out"
"$ROOT/bin/agentdock" inbox analyst --limit 2 > "$TMP/inbox-analyst.out"
grep -q 'Shared' "$TMP/inbox-analyst.out"
"$ROOT/bin/agentdock" inbox analyst --mark-read > "$TMP/inbox-mark.out"
grep -q 'Marked read for analyst' "$TMP/inbox-mark.out"
"$ROOT/bin/agentdock" broadcast --to analyst "Targeted analyst-only broadcast"
"$ROOT/bin/agentdock" inbox analyst --unread > "$TMP/inbox-unread.out"
grep -q 'Targeted analyst-only broadcast' "$TMP/inbox-unread.out"
! grep -q 'Targeted analyst-only broadcast' .agent-work/12_INBOX/reviewer/*.md
AGENTDOCK_BROADCAST_MAX_BYTES=1 "$ROOT/bin/agentdock" broadcast --to analyst "Rotate broadcast log"
find .agent-work/11_ARCHIVE -maxdepth 1 -type f -name 'BROADCASTS-*.md' | grep -q BROADCASTS
"$ROOT/bin/agentdock" broadcast "@reviewer mention-routed broadcast"
grep -q 'mention-routed broadcast' .agent-work/12_INBOX/reviewer/*.md
! grep -q 'mention-routed broadcast' .agent-work/12_INBOX/analyst/*.md
"$ROOT/bin/agentdock" broadcast "@qa alias-routed broadcast"
grep -q 'alias-routed broadcast' .agent-work/12_INBOX/qa-check/*.md
"$ROOT/bin/agentdock" report --fast > "$TMP/report-fast.out"
grep -q 'AgentDock Fast Report' "$TMP/report-fast.out"
"$ROOT/bin/agentdock" watch reviewer --once --limit 2 > "$TMP/watch-reviewer.out"
grep -q 'mention-routed broadcast' "$TMP/watch-reviewer.out"
"$ROOT/bin/agentdock" inbox reviewer --unread > "$TMP/reviewer-unread-after-watch.out"
! grep -q 'mention-routed broadcast' "$TMP/reviewer-unread-after-watch.out"
"$ROOT/bin/agentdock" task "Smoke test job"
grep -q 'Job task kickoff:' .agent-work/14_SHARED_CONTEXT/BROADCASTS.md
test -f .agent-work/07_JOBS/CURRENT.md
JOB_README="$(sed -n 's/^Active job: //p' .agent-work/07_JOBS/CURRENT.md)"
JOB_DIR="$(dirname "$JOB_README")"
test -f "$JOB_DIR/SELECTED_ROLES"
grep -q '^qa-check$' "$JOB_DIR/SELECTED_ROLES"
test -f "$JOB_DIR/TEAM.md"
test -f "$JOB_DIR/LIFECYCLE.md"
test -f "$JOB_DIR/TASKS/README.md"
test -f "$JOB_DIR/TASKS/ceo-orchestrator.md"
test -f "$JOB_DIR/TASKS/analyst.md"
test -f "$JOB_DIR/TASKS/reviewer.md"
test -f "$JOB_DIR/TASKS/qa-check.md"
test -f "$JOB_DIR/TASKS/legacy-codex.md"
grep -q 'Status: executing' "$JOB_DIR/LIFECYCLE.md"
grep -q 'task cards dispatched' "$JOB_DIR/LIFECYCLE.md"
grep -q "$JOB_DIR/TASKS/analyst.md" .agent-work/12_INBOX/analyst/*.md
grep -q "$JOB_DIR/TASKS/reviewer.md" .agent-work/12_INBOX/reviewer/*.md
grep -q "$JOB_DIR/TASKS/qa-check.md" .agent-work/12_INBOX/qa-check/*.md
BEFORE_QA="$(find .agent-work/12_INBOX/qa-check -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')"
adock-delegate --from ceo-orchestrator --request "CEO-pane delegated job"
grep -q 'Job kickoff:' .agent-work/14_SHARED_CONTEXT/BROADCASTS.md
AFTER_QA="$(find .agent-work/12_INBOX/qa-check -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')"
test "$AFTER_QA" -eq "$BEFORE_QA"
test -f .agent-work/07_JOBS/CURRENT.md
JOB_README="$(sed -n 's/^Active job: //p' .agent-work/07_JOBS/CURRENT.md)"
JOB_DIR="$(dirname "$JOB_README")"
test -f "$JOB_DIR/TASKS/ceo-orchestrator.md"
grep -q 'Required CEO-led flow' "$JOB_README"
grep -q 'Existing configured/running team' "$JOB_DIR/TEAM.md"
grep -q '| analyst | analyst | running' "$JOB_DIR/TEAM.md"
grep -q 'Reuse these roles when their capability fits the job' "$JOB_DIR/TEAM.md"
grep -q 'agentdock recruit' "$JOB_DIR/TASKS/ceo-orchestrator.md"
grep -q 'Reuse suitable existing roles' "$JOB_DIR/TASKS/ceo-orchestrator.md"
grep -q 'Created by' "$JOB_DIR/README.md"
grep -q 'ceo-orchestrator' "$JOB_DIR/README.md"
cat > "$JOB_DIR/TASKS/reviewer.md" <<EOF
# Task: reviewer

Owner: reviewer
Status: assigned
EOF
if "$ROOT/bin/agentdock" job finish --summary "Should not finish" > "$TMP/premature-finish.out" 2>&1; then
  echo "job finish should fail when a selected worker task has no role report" >&2
  exit 1
fi
grep -q 'selected role task card(s) have no job report: reviewer' "$TMP/premature-finish.out"
"$ROOT/bin/agentdock" job report --from analyst --summary "Analyst completed the assigned investigation"
grep -q 'Role report submitted by analyst' .agent-work/14_SHARED_CONTEXT/BROADCASTS.md
AFTER_REPORT_QA="$(find .agent-work/12_INBOX/qa-check -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')"
test "$AFTER_REPORT_QA" -eq "$BEFORE_QA"
LONG_SUMMARY="$(printf 'x%.0s' {1..1200})"
"$ROOT/bin/agentdock" job report --from analyst --summary "$LONG_SUMMARY"
grep -q 'truncated' .agent-work/14_SHARED_CONTEXT/BROADCASTS.md
"$ROOT/bin/agentdock" job report --from analyst --summary "Analyst completed a second same-role report without overwriting the first"
"$ROOT/bin/agentdock" job report --from reviewer --summary "Reviewer completed the assigned review"
test "$(find "$JOB_DIR/REPORTS" -maxdepth 1 -type f -name '*-analyst.md' | wc -l | tr -d ' ')" -eq 3
grep -q 'Analyst completed the assigned investigation' "$JOB_DIR"/REPORTS/*-analyst.md
grep -q 'Analyst completed a second same-role report' "$JOB_DIR"/REPORTS/*-analyst.md
ROLE_REPORT="$(find "$JOB_DIR/REPORTS" -maxdepth 1 -type f -name '*-analyst.md' | sort | tail -1)"
test -f "$ROLE_REPORT"
basename "$ROLE_REPORT" | grep -Eq '^[0-9]{8}:[0-9]{2}:[0-9]{2}\.[0-9]+-analyst\.md$'
grep -q 'Analyst completed a second same-role report' "$ROLE_REPORT"
grep -q "$ROLE_REPORT" .agent-work/12_INBOX/ceo-orchestrator/*.md
test -f ".agent-work/10_REPORTS/analyst/$(basename "$ROLE_REPORT")"
"$ROOT/bin/agentdock" job finish --summary "Delegate job complete"
FINAL_REPORT="$(find "$JOB_DIR/REPORTS" -maxdepth 1 -type f -name '*-final.md' | sort | tail -1)"
test -f "$FINAL_REPORT"
basename "$FINAL_REPORT" | grep -Eq '^[0-9]{8}:[0-9]{2}:[0-9]{2}\.[0-9]+-final\.md$'
grep -q 'Delegate job complete' "$FINAL_REPORT"
grep -q 'Analyst completed the assigned investigation' "$FINAL_REPORT"
grep -q 'Reviewer completed the assigned review' "$FINAL_REPORT"
grep -q 'Team Teardown' "$FINAL_REPORT"
grep -q 'Disbanded completed worker role pane' "$FINAL_REPORT"
grep -q 'Kept unfinished/unreported worker pane' "$FINAL_REPORT"
grep -q 'teardown: disbanded completed worker panes after CEO aggregation' "$JOB_DIR/LIFECYCLE.md"
grep -q 'teardown: kept unfinished/unreported worker panes active' "$JOB_DIR/LIFECYCLE.md"
test -f ".agent-work/10_REPORTS/ceo-orchestrator/$(basename "$FINAL_REPORT")"
grep -q PANE_ceo_orchestrator .agentdock/state/panes.env
! grep -q PANE_analyst .agentdock/state/panes.env
! grep -q PANE_reviewer .agentdock/state/panes.env
grep -q PANE_qa_check .agentdock/state/panes.env
grep -q PANE_legacy_codex .agentdock/state/panes.env
"$ROOT/bin/agentdock" report > "$TMP/report.out"
grep -q 'AgentDock Report' "$TMP/report.out"
grep -q 'Current team plan' "$TMP/report.out"
"$ROOT/bin/agentdock" report --json | json_validate

coordination_checksum() {
  find .agent-work .agentdock -type f \
    ! -path './.agent-work/11_ARCHIVE/workspace.html' \
    ! -path '.agent-work/11_ARCHIVE/workspace.html' \
    -print | sort | while IFS= read -r file; do
    cksum "$file"
  done
}

coordination_checksum > "$TMP/workspace-before.cksum"
"$ROOT/bin/agentdock" workspace snapshot --json > "$TMP/workspace-state.json"
json_validate < "$TMP/workspace-state.json"
grep -q '"schema_version"' "$TMP/workspace-state.json"
grep -q '"final_ready"' "$TMP/workspace-state.json"
grep -q '"missing_roles"' "$TMP/workspace-state.json"
grep -q '"logical_node"' "$TMP/workspace-state.json"
grep -q '"manager_chain"' "$TMP/workspace-state.json"
"$ROOT/bin/agentdock" workspace export --out .agent-work/11_ARCHIVE/workspace.html
test -s .agent-work/11_ARCHIVE/workspace.html
grep -q 'AgentDock Visual Office' .agent-work/11_ARCHIVE/workspace.html
grep -q 'Read-only observer' .agent-work/11_ARCHIVE/workspace.html
grep -q 'Final readiness' .agent-work/11_ARCHIVE/workspace.html
grep -q 'Reports' .agent-work/11_ARCHIVE/workspace.html
grep -q 'Product Bay' .agent-work/11_ARCHIVE/workspace.html
grep -q 'Engineering Bay' .agent-work/11_ARCHIVE/workspace.html
grep -q 'Blocker Desk' .agent-work/11_ARCHIVE/workspace.html
grep -q 'Report Desk' .agent-work/11_ARCHIVE/workspace.html
grep -q 'Status reason' .agent-work/11_ARCHIVE/workspace.html
coordination_checksum > "$TMP/workspace-after.cksum"
cmp "$TMP/workspace-before.cksum" "$TMP/workspace-after.cksum"
"$ROOT/bin/agentdock" cli list --json | json_validate
"$ROOT/bin/agentdock" stop --yes
! tmux has-session -t "$SESSION" 2>/dev/null
grep -Eq '^AGENT_legacy_codex_CLI="?hermes"?$' .agentdock/config.runtime
"$ROOT/bin/agentdock" job --no-attach "CEO-led smoke job"
tmux has-session -t "$SESSION"
grep -q 'Do not stop at READY' .agent-work/12_INBOX/ceo-orchestrator/*.md
grep -q 'start execution now' .agent-work/12_INBOX/ceo-orchestrator/*.md
JOB_README="$(sed -n 's/^Active job: //p' .agent-work/07_JOBS/CURRENT.md)"
JOB_DIR="$(dirname "$JOB_README")"
test -f "$JOB_DIR/TASKS/ceo-orchestrator.md"
grep -q 'Required CEO-led flow' "$JOB_README"
grep -q 'Existing configured/running team' "$JOB_DIR/TEAM.md"
grep -q '| analyst | analyst | configured' "$JOB_DIR/TEAM.md"
grep -q 'agentdock job finish' "$JOB_DIR/TASKS/ceo-orchestrator.md"
"$ROOT/bin/agentdock" job report --from ceo-orchestrator --summary "CEO coordinated the smoke job"
"$ROOT/bin/agentdock" job finish --summary "CEO-led smoke done"
FINAL_REPORT="$(find "$JOB_DIR/REPORTS" -maxdepth 1 -type f -name '*-final.md' | sort | tail -1)"
grep -q 'CEO-led smoke done' "$FINAL_REPORT"
grep -q 'CEO coordinated the smoke job' "$FINAL_REPORT"
"$ROOT/bin/agentdock" stop --yes
"$ROOT/bin/agentdock" start --no-attach --skip-missing > "$TMP/start-all.out"
grep -Eq '^AGENT_legacy_codex_CLI="?hermes"?$' .agentdock/config.runtime
"$ROOT/bin/agentdock" stop --yes

echo "smoke ok"
