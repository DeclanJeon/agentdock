#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { echo "workspace model settings failed: $*" >&2; exit 1; }
TMP="$(mktemp -d)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

fakebin="$TMP/bin"
project="$TMP/project"
mkdir -p "$fakebin" "$project/.agentdock" "$project/.agent-work"
cat > "$fakebin/hermes" <<'SH'
#!/usr/bin/env bash
if [[ "$1 $2" == "config path" ]]; then echo "$HERMES_FAKE_CONFIG"; exit 0; fi
if [[ "$1 $2" == "config set" ]]; then echo "$3=$4" >> "$HERMES_FAKE_LOG"; exit 0; fi
exit 0
SH
chmod +x "$fakebin/hermes"
cat > "$fakebin/tmux" <<'SH'
#!/usr/bin/env bash
exit 1
SH
chmod +x "$fakebin/tmux"
cat > "$TMP/hermes.yaml" <<'YAML'
model:
  provider: openai-codex
  default: gpt-5.5
YAML
cat > "$project/.agentdock/config.runtime" <<EOF_RUNTIME
PROJECT_NAME=model-test
PROJECT_ROOT=$project
SESSION_NAME=model-test-agents
LAYOUT=tiled
ATTACH_ON_START=1
USE_WORKTREES=0
WORK_DIR=.agent-work
AGENT_IDS=orchestrator developer
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
EOF_RUNTIME

env PATH="$fakebin:$PATH" HERMES_FAKE_CONFIG="$TMP/hermes.yaml" HERMES_FAKE_LOG="$TMP/hermes.log" \
  ./bin/agentdock workspace model --json --project "$project" > "$TMP/get.json"
python3 -m json.tool "$TMP/get.json" >/dev/null
grep -q '"source": "hermes-config"\|"source":"hermes-config"' "$TMP/get.json" || fail "model get did not read Hermes config fallback"

env PATH="$fakebin:$PATH" HERMES_FAKE_CONFIG="$TMP/hermes.yaml" HERMES_FAKE_LOG="$TMP/hermes.log" \
  ./bin/agentdock workspace model set --model gpt-5.3-codex --provider openai-codex --apply-running --global --json --project "$project" > "$TMP/set.json"
python3 -m json.tool "$TMP/set.json" >/dev/null
grep -q '"ok": true\|"ok":true' "$TMP/set.json" || fail "model set did not return ok"
grep -q '^HERMES_MODEL=gpt-5.3-codex$' "$project/.agentdock/config.runtime" || fail "runtime missing HERMES_MODEL"
grep -q '^HERMES_PROVIDER=openai-codex$' "$project/.agentdock/config.runtime" || fail "runtime missing HERMES_PROVIDER"
grep -q '^AGENT_orchestrator_CMD="HERMES_INFERENCE_MODEL=gpt-5.3-codex HERMES_INFERENCE_PROVIDER=openai-codex hermes"$' "$project/.agentdock/config.runtime" || fail "orchestrator command does not carry Hermes env override"
grep -q '^AGENT_developer_CMD="HERMES_INFERENCE_MODEL=gpt-5.3-codex HERMES_INFERENCE_PROVIDER=openai-codex hermes"$' "$project/.agentdock/config.runtime" || fail "developer command does not carry Hermes env override"
grep -q 'model.default=gpt-5.3-codex' "$TMP/hermes.log" || fail "Hermes global model was not persisted"
grep -q 'model.provider=openai-codex' "$TMP/hermes.log" || fail "Hermes global provider was not persisted"

echo "workspace model settings ok"
