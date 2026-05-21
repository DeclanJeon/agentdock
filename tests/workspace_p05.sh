#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

json_get() {
  python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); exec(sys.argv[2])' "$1" "$2"
}

make_project() {
  local project="$1" roles="$2"
  mkdir -p "$project/.agentdock/state" "$project/.agent-work/07_JOBS" "$project/.agent-work/14_SHARED_CONTEXT" "$project/.agent-work/12_INBOX"
  {
    printf 'PROJECT_NAME=fixture\n'
    printf 'PROJECT_ROOT=%s\n' "$project"
    printf 'SESSION_NAME=fixture-session\n'
    printf 'AGENT_IDS=%s\n' "$roles"
  } > "$project/.agentdock/config.runtime"
  printf '# AgentDock Locks\n\n## Active locks\n\n| Role | Files | Reason | Since |\n|---|---|---|---|\n' > "$project/.agent-work/LOCKS.md"
  printf '# Broadcasts\n' > "$project/.agent-work/14_SHARED_CONTEXT/BROADCASTS.md"
}

make_job() {
  local project="$1" job="$2" status="$3" roles="$4"
  local job_dir="$project/.agent-work/07_JOBS/$job"
  mkdir -p "$job_dir/TASKS" "$job_dir/REPORTS"
  printf 'Active job: %s/README.md\n' "$job_dir" > "$project/.agent-work/07_JOBS/CURRENT.md"
  printf '# %s\n' "$job" > "$job_dir/README.md"
  printf 'Status: %s\n' "$status" > "$job_dir/LIFECYCLE.md"
  printf '# Team\n' > "$job_dir/TEAM.md"
  for role in $roles; do printf '# Task: %s\n' "$role" > "$job_dir/TASKS/$role.md"; done
  printf '%s\n' "$job_dir"
}

# old fixture remains readable for backward-compatible consumers
python3 - <<'PY' "$ROOT/tests/fixtures/workspace/old-p0-snapshot.json"
import json, sys
with open(sys.argv[1], encoding="utf-8") as fh:
    data = json.load(fh)
assert data["schema_version"] == "workspace.snapshot.v1"
assert data["job"]["final_ready"] is False
assert "developer" in data["reports"]["missing_roles"]
assert data.get("layout", {"density": "normal"}).get("density") in {"normal", "dense", "crowded"}
PY

# no active job remains backward-compatible and warns instead of failing
P0="$TMP/no-job"
make_project "$P0" "orchestrator developer"
(cd "$P0" && "$ROOT/bin/agentdock" workspace snapshot --json > "$TMP/no-job.json")
python3 -m json.tool "$TMP/no-job.json" >/dev/null
json_get "$TMP/no-job.json" 'assert d["schema_version"] == "workspace.snapshot.v1"; assert d["job"]["final_ready"] is False; assert "No active job found" in d["warnings"]'

# missing reports, blocker taxonomy, redaction, invalid config fallback warnings
P1="$TMP/active"
make_project "$P1" "orchestrator developer qa"
JOB_DIR="$(make_job "$P1" "JOB-P05" "executing" "orchestrator developer qa")"
mkdir -p "$P1/.agentdock/workspace"
printf 'not: [valid\n' > "$P1/.agentdock/workspace/org.yml"
printf 'bad_line_without_colon\n' > "$P1/.agentdock/workspace/characters.yml"
printf '# Report\n\nSummary: BLOCKED because OPENAI_API_KEY=sk-secret1234567890 and raw prompt %s\n' "$(printf 'x%.0s' {1..700})" > "$JOB_DIR/REPORTS/26052100:00:00.000000-qa.md"
(cd "$P1" && "$ROOT/bin/agentdock" workspace snapshot --json > "$TMP/active.json")
python3 -m json.tool "$TMP/active.json" >/dev/null
json_get "$TMP/active.json" 'assert d["job"]["final_ready"] is False; assert "developer" in d["reports"]["missing_roles"]; assert any(a.get("type")=="blocker" for a in d["alerts"]); assert any("org.yml" in w for w in d["warnings"]); assert any("characters.yml" in w for w in d["warnings"]); assert d["status_taxonomy"]["blocked"]'
! grep -q 'sk-secret1234567890' "$TMP/active.json"
! grep -q 'OPENAI_API_KEY=sk-' "$TMP/active.json"
(cd "$P1" && "$ROOT/bin/agentdock" workspace export --out .agent-work/11_ARCHIVE/workspace.html)
grep -q 'aria-label=' "$P1/.agent-work/11_ARCHIVE/workspace.html"
grep -q 'role="button"' "$P1/.agent-work/11_ARCHIVE/workspace.html"
! grep -q 'sk-secret1234567890' "$P1/.agent-work/11_ARCHIVE/workspace.html"

# safe --out policy: allow archive workspace export, reject coordination overwrite/traversal/symlink
if (cd "$P1" && "$ROOT/bin/agentdock" workspace export --out .agent-work/LOCKS.md >/tmp/p05-bad.out 2>&1); then
  echo 'expected export to reject coordination overwrite' >&2; exit 1
fi
if (cd "$P1" && "$ROOT/bin/agentdock" workspace export --out ../escape.html >/tmp/p05-bad.out 2>&1); then
  echo 'expected export to reject traversal' >&2; exit 1
fi
ln -s "$TMP/symlink-target.html" "$P1/symlink.html"
if (cd "$P1" && "$ROOT/bin/agentdock" workspace export --out symlink.html >/tmp/p05-bad.out 2>&1); then
  echo 'expected export to reject symlink' >&2; exit 1
fi

# final ready + 50-role density/export fixture
roles="orchestrator"
for i in $(seq -w 1 50); do roles="$roles role-$i"; done
P50="$TMP/fifty"
make_project "$P50" "$roles"
JOB50="$(make_job "$P50" "JOB-50" "executing" "$roles")"
for i in $(seq -w 1 50); do printf '# Report\n\nSummary: role %s done\n' "$i" > "$JOB50/REPORTS/26052100:00:00.$i-role-$i.md"; done
(cd "$P50" && "$ROOT/bin/agentdock" workspace snapshot --json > "$TMP/fifty.json")
json_get "$TMP/fifty.json" 'assert d["job"]["final_ready"] is True; assert len(d["roles"]) >= 51; assert d["layout"]["density"] in ("normal","dense","crowded")'
(cd "$P50" && "$ROOT/bin/agentdock" workspace export --out .agent-work/11_ARCHIVE/workspace.html)
grep -q 'Density' "$P50/.agent-work/11_ARCHIVE/workspace.html"

echo "workspace p0.5 ok"
