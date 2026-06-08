#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { echo "role model defaults failed: $*" >&2; exit 1; }
TMP="$(mktemp -d)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

fakebin="$TMP/bin"
project="$TMP/project"
mkdir -p "$fakebin" "$project"
cat > "$fakebin/hermes" <<'SH'
#!/usr/bin/env bash
if [[ "$1 $2" == "config path" ]]; then echo "$HERMES_FAKE_CONFIG"; exit 0; fi
exit 0
SH
chmod +x "$fakebin/hermes"
cat > "$TMP/hermes.yaml" <<'YAML'
model:
  provider: openai-codex
  default: gpt-5.5
YAML

env PATH="$fakebin:$PATH" HERMES_FAKE_CONFIG="$TMP/hermes.yaml" ./bin/agentdock init --roles ceo-orchestrator,ui-designer,developer --no-start --project "$project" >/dev/null

grep -q '^HERMES_MODEL=gpt-5.5$' "$project/.agentdock/config.runtime" || fail "project default model is not gpt-5.5"
grep -q '^HERMES_PROVIDER=openai-codex$' "$project/.agentdock/config.runtime" || fail "project default provider is not openai-codex"
grep -q '^AGENT_ui_designer_MODEL=mimo-v2.5-pro$' "$project/.agentdock/config.runtime" || fail "design role missing MiMo model"
grep -q '^AGENT_ui_designer_PROVIDER=xiaomi$' "$project/.agentdock/config.runtime" || fail "design role missing Xiaomi MiMo provider"
grep -q '^AGENT_developer_MODEL=gpt-5.5$' "$project/.agentdock/config.runtime" || fail "developer should use GPT-5.5"
grep -q '^AGENT_developer_PROVIDER=openai-codex$' "$project/.agentdock/config.runtime" || fail "developer should use openai-codex"
grep -q '^AGENT_ui_designer_CMD="HERMES_INFERENCE_MODEL=mimo-v2.5-pro HERMES_INFERENCE_PROVIDER=xiaomi hermes"$' "$project/.agentdock/config.runtime" || fail "design command does not carry role model override"
grep -q '^AGENT_developer_CMD="HERMES_INFERENCE_MODEL=gpt-5.5 HERMES_INFERENCE_PROVIDER=openai-codex hermes"$' "$project/.agentdock/config.runtime" || fail "developer command does not carry default model override"
grep -q 'model: mimo-v2.5-pro' "$project/.agentdock/config.yml" || fail "config yaml missing design model"
grep -q 'Assigned model: xiaomi / mimo-v2.5-pro' "$project/.agentdock/generated/boot-ui-designer.md" || fail "boot prompt missing design model"

echo "role model defaults ok"
