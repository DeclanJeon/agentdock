#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${1:-$ROOT/.agent-work/11_ARCHIVE/native-screenshot-fixture-projects}"
mkdir -p "$OUT_DIR"

python3 - "$ROOT" "$OUT_DIR" <<'PY'
import json, os, stat, sys
from pathlib import Path
root = Path(sys.argv[1])
out = Path(sys.argv[2])
fixtures = root / 'tests' / 'fixtures' / 'workspace'
state_to_fixture = {
    'live-normal': 'active-normal.json',
    'missing-reports': 'missing-reports.json',
    'blocker-present': 'blocker-present.json',
    'final-ready': 'final-ready.json',
    'dense-20': 'dense-20-roles.json',
    'dense-50-search-filter': 'dense-50-roles.json',
    'stale-last-good': 'stale-last-good.json',
    'error-state': 'error-state.json',
    'keyboard-focus': 'active-normal.json',
    'reduced-motion': 'active-normal.json',
    'read-only-security': 'secret-redaction.json',
}
created = []
for state, fixture_name in state_to_fixture.items():
    fixture_path = fixtures / fixture_name
    data = json.loads(fixture_path.read_text(encoding='utf-8'))
    data['project']['name'] = f'agentdock-native-evidence-{state}'
    data['project']['root'] = str(out / state)
    data['project']['session'] = f'native-evidence-{state}'
    data['project']['session_name'] = f'native-evidence-{state}'
    data.setdefault('evidence_state', state)
    if state == 'keyboard-focus':
        data.setdefault('warnings', []).append({'severity':'info','type':'keyboard_focus','message':'Use Tab to focus a role station before capturing this state.'})
    if state == 'reduced-motion':
        data.setdefault('warnings', []).append({'severity':'info','type':'reduced_motion','message':'Capture with reduced-motion mode enabled at OS/browser environment if available.'})
    project = out / state
    (project / 'bin').mkdir(parents=True, exist_ok=True)
    (project / '.agentdock' / 'state').mkdir(parents=True, exist_ok=True)
    (project / '.agent-work' / '07_JOBS' / data['job']['id']).mkdir(parents=True, exist_ok=True)
    (project / '.agent-work' / '14_SHARED_CONTEXT').mkdir(parents=True, exist_ok=True)
    (project / '.agent-work' / '12_INBOX').mkdir(parents=True, exist_ok=True)
    (project / '.agent-work' / '11_ARCHIVE').mkdir(parents=True, exist_ok=True)
    (project / '.agentdock' / 'config.runtime').write_text(
        f'PROJECT_NAME={data["project"]["name"]}\nPROJECT_ROOT={project}\nSESSION_NAME={data["project"]["session_name"]}\nAGENT_IDS="' + ' '.join(r['id'] for r in data.get('roles', [])) + '"\n',
        encoding='utf-8'
    )
    (project / '.agent-work' / '07_JOBS' / 'CURRENT.md').write_text(f'Active job: {project}/.agent-work/07_JOBS/{data["job"]["id"]}/README.md\n', encoding='utf-8')
    (project / '.agent-work' / '07_JOBS' / data['job']['id'] / 'README.md').write_text(f'# {data["job"]["id"]}\n\nNative evidence fixture: {state}\n', encoding='utf-8')
    (project / '.agent-work' / '14_SHARED_CONTEXT' / 'BROADCASTS.md').write_text('# Broadcasts\n', encoding='utf-8')
    (project / '.agent-work' / 'LOCKS.md').write_text('# AgentDock Locks\n', encoding='utf-8')
    snapshot_path = project / 'snapshot.json'
    snapshot_path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    agentdock = project / 'bin' / 'agentdock'
    agentdock.write_text(f'''#!/usr/bin/env bash
set -euo pipefail
if [[ "${{1:-}} ${{2:-}} ${{3:-}}" == "workspace snapshot --json" ]]; then
  cat "$(dirname "$0")/../snapshot.json"
  exit 0
fi
if [[ "${{1:-}}" == "workspace" && "${{2:-}}" == "snapshot" ]]; then
  cat "$(dirname "$0")/../snapshot.json"
  exit 0
fi
if [[ "${{1:-}}" == "version" || "${{1:-}}" == "--version" ]]; then
  echo "agentdock fixture {state}"
  exit 0
fi
echo "fixture agentdock only supports workspace snapshot --json" >&2
exit 1
''', encoding='utf-8')
    agentdock.chmod(agentdock.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
    created.append({'state': state, 'project': str(project), 'fixture': str(fixture_path)})
manifest = {'fixtureProjects': created}
(out / 'fixture-projects-manifest.json').write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
print(f'prepared {len(created)} native screenshot fixture project(s) under {out}')
for item in created:
    print(f"{item['state']} {item['project']}")
PY
