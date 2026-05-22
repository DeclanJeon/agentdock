#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

OUT_DIR="${1:-.agent-work/07_JOBS/${AGENTDOCK_CONTROLLED_ACTIONS_JOB_ID:-${AGENTDOCK_RELEASE_MATRIX_JOB_ID:-JOB-260522190004397678}}/OUTPUTS/controlled-actions-native-matrix}"
mkdir -p "$OUT_DIR"
ABS_OUT_DIR="$(cd "$OUT_DIR" && pwd)"

/usr/bin/python3 - "$ROOT" "$ABS_OUT_DIR" <<'PY'
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

import gi

gi.require_version('Atspi', '2.0')
from gi.repository import Atspi  # noqa: E402

ROOT = Path(sys.argv[1]).resolve()
OUT_DIR = Path(sys.argv[2]).resolve()
APP = ROOT / 'src-tauri' / 'target' / 'release' / 'agentdock-workspace'
RESULT = OUT_DIR / 'controlled-actions-native-matrix.json'
PROJECT = OUT_DIR / 'sandbox-project'
JOB_ID = 'JOB-MATRIX'
JOB_PATH = PROJECT / '.agent-work' / '07_JOBS' / JOB_ID
LOG_PATH = PROJECT / 'actions.jsonl'

BUTTONS = [
    ('followup', 'Send follow-up'),
    ('broadcast', 'Broadcast to selected team'),
    ('role_send', 'Send to role'),
    ('recruit_preview', 'Preview'),
    ('recruit', 'Recruit'),
    ('task_proposal', 'Send proposal'),
    ('job_report', 'Submit report'),
    ('finish_preview', 'Preview finish'),
    ('finish', 'Finish job'),
]
EXPECTED_COMMANDS = {
    'followup': ['send', 'ceo-orchestrator'],
    'broadcast': ['broadcast', '--from', 'user', '--selected'],
    'role_send': ['send', 'ceo-orchestrator'],
    'recruit': ['recruit', 'frontend-developer', '--template', 'agency-frontend-developer'],
    'task_proposal': ['send', 'ceo-orchestrator'],
    'job_report': ['job', 'report', '--from', 'analyst'],
    'finish': ['job', 'finish'],
}


def write_result(payload: dict) -> None:
    payload.setdefault('schema', 'workspace.controlled-actions-native-matrix.v1')
    payload.setdefault('generatedAt', time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()))
    payload.setdefault('project', str(PROJECT))
    payload.setdefault('jobId', JOB_ID)
    RESULT.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')


def safe(call, default=None):
    try:
        return call()
    except Exception:
        return default


def walk(obj):
    if obj is None:
        return
    yield obj
    count = safe(lambda: obj.get_child_count(), 0) or 0
    for index in range(count):
        child = safe(lambda index=index: obj.get_child_at_index(index), None)
        yield from walk(child)


def desktop_apps():
    desktop = Atspi.get_desktop(0)
    count = safe(lambda: desktop.get_child_count(), 0) or 0
    for index in range(count):
        app = safe(lambda index=index: desktop.get_child_at_index(index), None)
        if app is not None:
            yield app


def find_agentdock_root(pid: int, timeout: float = 30.0):
    deadline = time.time() + timeout
    while time.time() < deadline:
        for app in desktop_apps():
            app_name = safe(lambda app=app: app.get_name() or '', '')
            app_pid = safe(lambda app=app: app.get_process_id(), -1)
            if app_name != 'agentdock-workspace' or app_pid != pid:
                continue
            for obj in walk(app):
                if safe(lambda obj=obj: obj.get_role_name() or '', '') == 'frame':
                    return obj
            return app
        time.sleep(0.25)
    return None


def find_within(root, name: str, role: str | None = None, timeout: float = 8.0):
    deadline = time.time() + timeout
    while time.time() < deadline:
        for obj in walk(root):
            obj_name = safe(lambda obj=obj: obj.get_name() or '', '')
            obj_role = safe(lambda obj=obj: obj.get_role_name() or '', '')
            if obj_name != name:
                continue
            if role is not None and obj_role != role:
                continue
            return obj
        time.sleep(0.2)
    return None


def extents(obj) -> tuple[int, int, int, int] | None:
    if obj is None:
        return None
    ext = safe(lambda: Atspi.Component.get_extents(obj, Atspi.CoordType.SCREEN), None)
    if ext is None:
        return None
    return (ext.x, ext.y, ext.width, ext.height)


def is_enabled(obj) -> bool:
    states = safe(lambda: obj.get_state_set(), None)
    if states is None:
        return False
    return bool(Atspi.StateSet.contains(states, Atspi.StateType.ENABLED) and Atspi.StateSet.contains(states, Atspi.StateType.SENSITIVE))


def portal_capture(path: Path) -> bool:
    helper = ROOT / 'tests' / 'workspace_portal_screenshot.py'
    if not helper.exists():
        return False
    try:
        subprocess.run(['/usr/bin/python3', str(helper), str(path)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=30, check=False)
    except Exception:
        return False
    return path.exists() and path.stat().st_size > 0


def prepare_project() -> None:
    if PROJECT.exists():
        shutil.rmtree(PROJECT)
    (PROJECT / '.agentdock').mkdir(parents=True)
    JOB_PATH.mkdir(parents=True)
    (PROJECT / 'bin').mkdir()
    snapshot = {
        'schema_version': 'workspace.snapshot.v1',
        'generated_at': '2026-05-23T00:00:00Z',
        'project': {'name': 'AgentDock controlled action matrix', 'root': str(PROJECT), 'session': 'matrix'},
        'job': {
            'id': JOB_ID,
            'path': str(JOB_PATH),
            'readme_path': str(JOB_PATH / 'README.md'),
            'lifecycle': 'active',
            'lifecycle_status': 'active',
            'final_ready': True,
            'final_ready_reason': 'matrix ready',
        },
        'reports': {
            'submitted': 2,
            'required': 2,
            'submitted_selected_roles': 2,
            'required_selected_roles': 2,
            'selected_roles': 2,
            'missing_roles': [],
        },
        'roles': [
            {
                'id': 'ceo-orchestrator',
                'display_name': 'CEO Orchestrator',
                'department': 'Command',
                'selected': True,
                'configured': True,
                'status': 'working',
                'status_reason': 'coordinating controlled-action matrix',
            },
            {
                'id': 'analyst',
                'display_name': 'Analyst',
                'department': 'Quality',
                'selected': True,
                'configured': True,
                'status': 'reported',
                'status_reason': 'ready to submit matrix report',
            },
        ],
        'alerts': [],
        'warnings': [],
        'commands': {
            'mode': 'controlled-actions',
            'write_bridge_enabled': False,
            'allowed_actions': ['send', 'broadcast', 'recruit', 'job report', 'job finish'],
        },
        'layout': {'role_count': 2, 'density': 'normal'},
        'team_plan': {
            'coordinator': 'ceo-orchestrator',
            'selected_roles': ['ceo-orchestrator', 'analyst'],
            'required_worker_reports': 1,
            'submitted_worker_reports': 1,
            'recommendations': [
                {
                    'template_id': 'agency-frontend-developer',
                    'display_name': 'Frontend Developer',
                    'department': 'Engineering',
                    'archetype': 'UI implementer',
                    'score': 0.91,
                    'reason': 'Need UI',
                }
            ],
            'policy': 'Native matrix uses snapshot-derived recommendations only.',
        },
        'tfts': [{'name': 'Controlled Action TFT', 'status': 'active', 'members': ['ceo-orchestrator', 'analyst'], 'goal': 'prove GUI controlled actions'}],
        'history': {'active_job_id': JOB_ID, 'recent_jobs': [{'id': JOB_ID, 'path': str(JOB_PATH), 'lifecycle': 'active', 'report_count': 2}]},
    }
    (PROJECT / 'snapshot.json').write_text(json.dumps(snapshot, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    (JOB_PATH / 'README.md').write_text('# JOB-MATRIX\n', encoding='utf-8')
    fake = PROJECT / 'bin' / 'agentdock'
    fake.write_text(
        "#!/usr/bin/env python3\n"
        "import json, os, sys\n"
        "root = os.getcwd()\n"
        "if sys.argv[1:3] == ['workspace', 'snapshot']:\n"
        "    print(open(os.path.join(root, 'snapshot.json'), encoding='utf-8').read())\n"
        "    raise SystemExit(0)\n"
        "with open(os.path.join(root, 'actions.jsonl'), 'a', encoding='utf-8') as f:\n"
        "    f.write(json.dumps(sys.argv[1:], ensure_ascii=False) + '\\n')\n"
        "print('ok')\n",
        encoding='utf-8',
    )
    fake.chmod(0o755)


def read_commands() -> list[list[str]]:
    if not LOG_PATH.exists():
        return []
    commands: list[list[str]] = []
    for line in LOG_PATH.read_text(encoding='utf-8').splitlines():
        if line.strip():
            commands.append(json.loads(line))
    return commands


def command_contains(command: list[str], expected: list[str]) -> bool:
    cursor = 0
    for token in expected:
        try:
            found = command.index(token, cursor)
        except ValueError:
            return False
        cursor = found + 1
    return True


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    if not APP.exists():
        write_result({'status': 'blocked', 'reason': f'release app missing: {APP}', 'nativeClick': False})
        return 2
    prepare_project()
    clicked = []
    screenshots = {}
    proc = None
    try:
        env = os.environ.copy()
        env['AGENTDOCK_NATIVE_EVIDENCE_CAPTURE'] = '1'
        proc = subprocess.Popen([str(APP), '--project', str(PROJECT)], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        frame = find_agentdock_root(proc.pid, timeout=30)
        if frame is None:
            write_result({'status': 'fail', 'reason': 'AgentDock native frame not found via AT-SPI', 'nativeClick': False})
            return 3
        Atspi.Component.grab_focus(frame)
        time.sleep(1.5)
        if portal_capture(OUT_DIR / 'controlled-actions-before.png'):
            screenshots['before'] = str(OUT_DIR / 'controlled-actions-before.png')
        for key, label in BUTTONS:
            button = find_within(frame, label, 'button', timeout=10)
            record = {'key': key, 'label': label, 'found': button is not None, 'enabledBefore': False, 'extentsBefore': extents(button)}
            if button is None:
                clicked.append(record)
                continue
            safe(lambda button=button: Atspi.Component.scroll_to_point(button, Atspi.CoordType.SCREEN, 40, 220), False)
            time.sleep(0.45)
            button = find_within(frame, label, 'button', timeout=4) or button
            record['extentsAfterScroll'] = extents(button)
            record['enabledBefore'] = is_enabled(button)
            record['nativeActionCount'] = safe(lambda button=button: Atspi.Action.get_n_actions(button), 0) or 0
            if record['enabledBefore'] and record['nativeActionCount'] > 0:
                record['clicked'] = bool(Atspi.Action.do_action(button, 0))
                time.sleep(1.0)
            else:
                record['clicked'] = False
            record['commandCountAfter'] = len(read_commands())
            clicked.append(record)
        if portal_capture(OUT_DIR / 'controlled-actions-after.png'):
            screenshots['after'] = str(OUT_DIR / 'controlled-actions-after.png')
    finally:
        if proc and proc.poll() is None:
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait(timeout=5)

    commands = read_commands()
    validation = []
    command_index = 0
    for key, expected in EXPECTED_COMMANDS.items():
        matched_command = None
        while command_index < len(commands):
            candidate = commands[command_index]
            command_index += 1
            if command_contains(candidate, expected):
                matched_command = candidate
                break
        validation.append({'key': key, 'expectedSubsequence': expected, 'matched': matched_command is not None, 'command': matched_command})

    errors = []
    for record in clicked:
        if not record.get('found'):
            errors.append(f"button not found: {record['label']}")
        elif not record.get('enabledBefore'):
            errors.append(f"button disabled before click: {record['label']}")
        elif not record.get('clicked'):
            errors.append(f"native action did not click: {record['label']}")
    for item in validation:
        if not item['matched']:
            errors.append(f"expected command not observed: {item['key']} {item['expectedSubsequence']}")
    if len(commands) != len(EXPECTED_COMMANDS):
        errors.append(f'observed {len(commands)} CLI commands, expected {len(EXPECTED_COMMANDS)} non-preview commands')

    status = 'pass' if not errors else 'fail'
    write_result({
        'status': status,
        'nativeClick': status == 'pass',
        'releaseApp': str(APP),
        'buttons': clicked,
        'observedCommands': commands,
        'validation': validation,
        'screenshots': screenshots,
        'errors': errors,
    })
    print(f'workspace controlled-actions native matrix {status}: {RESULT}')
    if errors:
        for error in errors:
            print(f'- {error}')
        return 4
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
PY
