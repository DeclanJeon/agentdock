#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
cleanup() {
  if command -v tmux >/dev/null 2>&1; then
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

export PATH="$FAKE:$PATH"
export XDG_CONFIG_HOME="$TMP/config"
tmux kill-session -t project-agents 2>/dev/null || true
"$ROOT/bin/agentdock" version | grep -q 'agentdock 0.1.0'
ln -sf "$ROOT/bin/agentdock" "$FAKE/adock"
ln -sf "$ROOT/bin/agentdock" "$FAKE/adock-delegate"
adock version | grep -q 'agentdock 0.1.0'

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
"$ROOT/bin/agentdock" setup --skip-cli --yes > "$TMP/setup.out"
grep -q 'AgentDock Doctor' "$TMP/setup.out"
grep -q 'Agent CLI:' "$TMP/setup.out"
grep -q 'OK  hermes' "$TMP/setup.out"
! grep -q '^OK  codex' "$TMP/setup.out"
"$ROOT/bin/agentdock" doctor --json | grep -q '"system"'
"$ROOT/bin/agentdock" doctor --json | grep -q '"agent_cli"'

cd "$TMP/project"
"$ROOT/bin/agentdock" init
"$ROOT/bin/agentdock" role add legacy-codex --cli hermes >/dev/null
sed -i 's/^AGENT_legacy_codex_CLI=.*/AGENT_legacy_codex_CLI=codex/' .agentdock/config.runtime
sed -i 's/^AGENT_legacy_codex_CMD=.*/AGENT_legacy_codex_CMD=codex/' .agentdock/config.runtime
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
"$ROOT/bin/agentdock" start --no-attach --skip-missing
grep -Eq '^AGENT_ceo_orchestrator_CLI="?hermes"?$' .agentdock/config.runtime
tmux has-session -t project-agents
test -s .agentdock/state/panes.env
test "$(wc -l < .agentdock/state/panes.env)" -eq 2
grep -q PANE_legacy_codex .agentdock/state/panes.env
"$ROOT/bin/agentdock" recruit analyst reviewer --template bmad-agent-dev --cli hermes --mission "Analyze implementation options for the active job." --instructions "Produce concise tradeoffs and hand off execution tasks."
"$ROOT/bin/agentdock" recruit qa-check --template qa --cli hermes --mission "Verify acceptance criteria and regression risk." --instructions "Report risks and validation evidence."
grep -q PANE_analyst .agentdock/state/panes.env
grep -q PANE_reviewer .agentdock/state/panes.env
grep -q PANE_qa_check .agentdock/state/panes.env
grep -q PANE_ceo_orchestrator .agentdock/state/panes.env
grep -q "Analyze implementation options" .agentdock/prompts/analyst.md
grep -q "Analyze implementation options" .agentdock/prompts/reviewer.md
grep -q "QA / Quality Engineer" .agentdock/prompts/qa-check.md
"$ROOT/bin/agentdock" task "Smoke test job"
test -f .agent-work/07_JOBS/CURRENT.md
JOB_README="$(sed -n 's/^Active job: //p' .agent-work/07_JOBS/CURRENT.md)"
JOB_DIR="$(dirname "$JOB_README")"
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
adock-delegate --from ceo-orchestrator --request "CEO-pane delegated job"
test -f .agent-work/07_JOBS/CURRENT.md
JOB_README="$(sed -n 's/^Active job: //p' .agent-work/07_JOBS/CURRENT.md)"
JOB_DIR="$(dirname "$JOB_README")"
test -f "$JOB_DIR/TASKS/ceo-orchestrator.md"
test -f "$JOB_DIR/TASKS/analyst.md"
grep -q 'Created by' "$JOB_DIR/README.md"
grep -q 'ceo-orchestrator' "$JOB_DIR/README.md"
grep -q "$JOB_DIR/TASKS/analyst.md" .agent-work/12_INBOX/analyst/*.md
"$ROOT/bin/agentdock" report > "$TMP/report.out"
grep -q 'AgentDock Report' "$TMP/report.out"
grep -q 'Current team plan' "$TMP/report.out"
"$ROOT/bin/agentdock" stop --yes
! tmux has-session -t project-agents 2>/dev/null
grep -Eq '^AGENT_legacy_codex_CLI="?hermes"?$' .agentdock/config.runtime
"$ROOT/bin/agentdock" start --no-attach --skip-missing > "$TMP/start-all.out"
grep -Eq '^AGENT_legacy_codex_CLI="?hermes"?$' .agentdock/config.runtime
"$ROOT/bin/agentdock" stop --yes

echo "smoke ok"
