#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { echo "workspace status/worktree/perf failed: $*" >&2; exit 1; }
TMP="$(mktemp -d)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

fakebin="$TMP/bin"
mkdir -p "$fakebin"
cat > "$fakebin/tmux" <<'SH'
#!/usr/bin/env bash
case "${1:-}" in
  has-session) exit 1 ;;
  list-panes) exit 0 ;;
  *) exit 0 ;;
esac
SH
chmod +x "$fakebin/tmux"

project="$TMP/project"
mkdir -p "$project/.agentdock" "$project/.agent-work"
cat > "$project/.agentdock/config.runtime" <<EOF_RUNTIME
PROJECT_NAME=test
PROJECT_ROOT=$project
SESSION_NAME=test-agents
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

env PATH="$fakebin:$PATH" ./bin/agentdock status set --project "$project" --role developer --state working --summary "implementing latency fixes" --progress 42 >/dev/null
snapshot="$(env PATH="$fakebin:$PATH" ./bin/agentdock workspace snapshot --json --project "$project")"
python3 - <<PY
import json
data=json.loads('''$snapshot''')
role=next(r for r in data['roles'] if r['id']=='developer')
assert role['status'] == 'working', role
assert role['live_status']['summary'] == 'implementing latency fixes', role
assert role['live_status']['progress'] == 42, role
PY

perf="$(env PATH="$fakebin:$PATH" ./bin/agentdock workspace perf --json --project "$project")"
python3 - <<PY
import json
data=json.loads('''$perf''')
assert data['schema_version'] == 'agentdock.workspace_perf.v1', data
assert data['snapshot_duration_ms'] >= 0, data
PY

git -C "$project" init -q
git -C "$project" config user.email test@example.com
git -C "$project" config user.name Test
touch "$project/README.md"
git -C "$project" add .
git -C "$project" commit -q -m initial

worktree_config="$(env PATH="$fakebin:$PATH" ./bin/agentdock worktree init --json --project "$project")"
python3 - <<PY
import json
data=json.loads('''$worktree_config''')
assert data['enabled'] is True, data
PY

worktree="$(env PATH="$fakebin:$PATH" ./bin/agentdock worktree create --role developer --json --project "$project")"
python3 - <<PY
import json, pathlib
data=json.loads('''$worktree''')
assert data['role'] == 'developer', data
assert pathlib.Path(data['path']).exists(), data
PY

worktree_status="$(env PATH="$fakebin:$PATH" ./bin/agentdock worktree status --role developer --json --project "$project")"
python3 - <<PY
import json
data=json.loads('''$worktree_status''')
assert data['role'] == 'developer', data
assert data['exists'] is True, data
assert data['status'] in {'ready','dirty'}, data
PY

merge_preview="$(env PATH="$fakebin:$PATH" ./bin/agentdock worktree merge --role developer --dry-run --json --project "$project")"
python3 - <<PY
import json
data=json.loads('''$merge_preview''')
assert data['role'] == 'developer', data
assert data['ready'] is True, data
PY

list_json="$(env PATH="$fakebin:$PATH" ./bin/agentdock worktree list --json --project "$project")"
python3 - <<PY
import json
data=json.loads('''$list_json''')
assert any(item.get('role') == 'developer' for item in data['items']), data
PY

snapshot_with_worktree="$(env PATH="$fakebin:$PATH" ./bin/agentdock workspace snapshot --json --cache-ms 700 --project "$project")"
python3 - <<PY
import json
data=json.loads('''$snapshot_with_worktree''')
assert any(item.get('role') == 'developer' for item in data.get('worktrees', {}).get('items', [])), data.get('worktrees')
role=next(r for r in data['roles'] if r['id']=='developer')
assert role['worktree']['branch'], role
PY

env PATH="$fakebin:$PATH" ./bin/agentdock worktree remove --role developer --yes --project "$project" >/dev/null

echo "workspace status/worktree/perf ok"
