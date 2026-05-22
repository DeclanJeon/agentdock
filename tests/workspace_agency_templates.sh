#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { echo "workspace agency templates test failed: $*" >&2; exit 1; }

[[ -f .agentdock/agency/registry.json ]] || fail "agency registry missing"
python3 - <<'PY'
import json
from pathlib import Path
reg = json.loads(Path('.agentdock/agency/registry.json').read_text(encoding='utf-8'))
items = reg.get('templates', [])
assert reg.get('schema_version') == 'agentdock.agency.registry.v1'
assert len(items) == 15, len(items)
seen = set()
for item in items:
    ident = item['id']
    assert ident.startswith('agency-'), ident
    assert ident not in seen, ident
    seen.add(ident)
    assert item.get('license') == 'MIT'
    assert Path(item['prompt_file']).is_file(), item['prompt_file']
    text = Path(item['prompt_file']).read_text(encoding='utf-8')
    assert 'AgentDock authority wrapper' in text
    assert 'agentdock job report --from <role>' in text
    assert 'Do not bypass read-only/write-bridge boundaries' in text
print('agency registry contract ok')
PY

roles_list="$(./bin/agentdock roles list)"
grep -q 'agency-frontend-developer' <<<"$roles_list" || fail "roles list missing agency frontend template"
grep -q 'Agency' <<<"$roles_list" || fail "roles list missing Agency source"
recommend_json="$(./bin/agentdock roles recommend 'UI 반응형 버튼 캐릭터 애니메이션 테스트 검증' --limit 6 --json)"
python3 - <<'PY' "$recommend_json"
import json, sys
rows = json.loads(sys.argv[1])
ids = {row.get('template_id') for row in rows}
assert 'agency-frontend-developer' in ids, rows
assert 'agency-whimsy-injector' in ids, rows
assert 'agency-qa-specialist' in ids, rows
assert all(str(row.get('template_id', '')).startswith('agency-') for row in rows), rows
print('agency recommendation command ok')
PY
grep -q 'Recommended curated agency specialists' bin/agentdock || fail "job TEAM plan recommendation section missing"

TMP="$(mktemp -d)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT
PROJECT="$TMP/project"
mkdir -p "$PROJECT"
cp -R .agentdock "$PROJECT/.agentdock"
mkdir -p "$PROJECT/.agent-work"
(
  cd "$PROJECT"
  AGENTDOCK_NO_AUTO_START=1 "$ROOT/bin/agentdock" recruit demo-frontend --template agency-frontend-developer --skip-missing --project "$PROJECT" >/tmp/agency-recruit.out
)
[[ -f "$PROJECT/.agentdock/prompts/demo-frontend.md" ]] || fail "agency recruit did not write prompt"
grep -q 'AgentDock template_id: agency-frontend-developer' "$PROJECT/.agentdock/prompts/demo-frontend.md" || fail "agency prompt missing template id marker"
grep -q 'AgentDock authority wrapper' "$PROJECT/.agentdock/prompts/demo-frontend.md" || fail "agency prompt missing authority wrapper"
"$ROOT/bin/agentdock" recruit demo-ui --template agency-ui-designer --skip-missing --project "$PROJECT" >/tmp/agency-recruit-project.out
grep -q 'AgentDock template_id: agency-ui-designer' "$PROJECT/.agentdock/prompts/demo-ui.md" || fail "agency recruit --project did not use project registry"
if (cd "$PROJECT" && "$ROOT/bin/agentdock" recruit bad-role --template agency-not-real --skip-missing --project "$PROJECT" >/tmp/agency-bad.out 2>/tmp/agency-bad.err); then
  fail "unknown agency template should fail closed"
fi
JOB="$PROJECT/.agent-work/07_JOBS/JOB-agency-recommend"
mkdir -p "$JOB/TASKS" "$JOB/REPORTS" "$JOB/LOGS" "$JOB/HANDOFFS" "$JOB/OUTPUTS"
cat > "$PROJECT/.agent-work/07_JOBS/CURRENT.md" <<EOF
Active job: $JOB/README.md
EOF
cat > "$JOB/README.md" <<'EOF'
# JOB-agency-recommend

## User request (untrusted)
BEGIN_UNTRUSTED_USER_REQUEST
> UI 반응형 버튼 정렬을 개선하고 캐릭터 애니메이션을 테스트 검증하라.
END_UNTRUSTED_USER_REQUEST

## Status
planning
EOF
cat > "$JOB/LIFECYCLE.md" <<'EOF'
# Lifecycle

Status: planning
EOF
cat > "$JOB/TEAM.md" <<'EOF'
# Team Plan

TFT: visual-ui-squad | members: demo-frontend | goal: responsive UI and animation verification | status: planned
EOF
cat > "$JOB/TASKS/demo-frontend.md" <<'EOF'
# Task: demo-frontend

Owner: demo-frontend
Status: assigned
EOF

snapshot="$(cd "$PROJECT" && "$ROOT/bin/agentdock" workspace snapshot --json --project "$PROJECT")"
python3 - <<'PY' "$snapshot"
import json, sys
snap = json.loads(sys.argv[1])
role = next((r for r in snap.get('roles', []) if r.get('id') == 'demo-frontend'), None)
assert role, 'demo-frontend role missing from snapshot'
assert role.get('template_id') == 'agency-frontend-developer', role
profile = role.get('agency_profile') or {}
assert profile.get('source', '').endswith('engineering/frontend-developer.md'), profile
assert role.get('department') == 'Engineering Bay', role
assert role.get('avatar', {}).get('style') == 'keyboard-pet', role.get('avatar')
recs = snap.get('team_plan', {}).get('recommendations', [])
rec_ids = {item.get('template_id') for item in recs}
assert 'agency-frontend-developer' in rec_ids, recs
assert 'agency-whimsy-injector' in rec_ids, recs
assert snap.get('tfts'), 'expected TFT extraction from TEAM.md'
print('agency snapshot metadata ok')
PY

echo "workspace agency templates ok"
