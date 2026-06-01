#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { echo "obsidian job sync failed: $*" >&2; exit 1; }
TMP="$(mktemp -d)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

fakebin="$TMP/bin"
vault="$TMP/Obsidian Vault"
project="$TMP/My Readable Project"
mkdir -p "$fakebin" "$vault" "$project" "$TMP/config/obsidian"

cat > "$fakebin/tmux" <<'SH'
#!/usr/bin/env bash
case "${1:-}" in
  has-session) exit 0 ;;
  display-message) echo "%100"; exit 0 ;;
  list-panes) echo "%100"; exit 0 ;;
  new-window|split-window|select-layout|select-pane|send-keys|kill-pane|load-buffer|paste-buffer) exit 0 ;;
  *) exit 0 ;;
esac
SH
chmod +x "$fakebin/tmux"
cat > "$fakebin/hermes" <<'SH'
#!/usr/bin/env bash
exit 0
SH
chmod +x "$fakebin/hermes"
cat > "$fakebin/obsidian" <<'SH'
#!/usr/bin/env bash
exit 0
SH
chmod +x "$fakebin/obsidian"

cat > "$TMP/config/obsidian/obsidian.json" <<EOF_JSON
{
  "vaults": {
    "fixture": {
      "path": "$vault",
      "open": true,
      "ts": 1770000000000
    }
  },
  "last_opened": "fixture"
}
EOF_JSON

env PATH="$fakebin:$PATH" XDG_CONFIG_HOME="$TMP/config" "$ROOT/bin/agentdock" init --project "$project" > "$TMP/init.out"
grep -q "Obsidian JOB sync enabled" "$TMP/init.out" || fail "init did not enable sync"
grep -q '^OBSIDIAN_SYNC_ENABLED=1$' "$project/.agentdock/config.runtime" || fail "runtime sync flag missing"
grep -q "sync_enabled: true" "$project/.agentdock/config.yml" || fail "yaml sync flag missing"
test -f "$vault/AgentDock/My Readable Project/AgentDock JOB Index.md" || fail "project index not created"

env PATH="$fakebin:$PATH" XDG_CONFIG_HOME="$TMP/config" "$ROOT/bin/agentdock" job --project "$project" --no-attach "문서 로그를 검토해줘" >/dev/null
job="$(find "$project/.agent-work/07_JOBS" -maxdepth 1 -type d -name 'JOB-*' | sort | tail -1)"
job_id="$(basename "$job")"
mirror="$vault/AgentDock/My Readable Project/JOBS/$job_id"

test -f "$mirror/00 Job Overview.md" || fail "job overview was not mirrored"
test -f "$mirror/02 Team Plan.md" || fail "team plan was not mirrored"
test -f "$mirror/Tasks/Task - Ceo Orchestrator.md" || fail "task card did not get readable name"
grep -q "AgentDock source: \`README.md\`" "$mirror/00 Job Overview.md" || fail "source metadata missing"
grep -q "문서 로그를 검토해줘" "$mirror/00 Job Overview.md" || fail "job content missing from mirror"

env PATH="$fakebin:$PATH" XDG_CONFIG_HOME="$TMP/config" "$ROOT/bin/agentdock" job report --project "$project" --from ceo-orchestrator --summary "검토 완료" >/dev/null
compgen -G "$mirror/Reports/Report - * - Ceo Orchestrator.md" >/dev/null || fail "role report readable copy missing"

env PATH="$fakebin:$PATH" XDG_CONFIG_HOME="$TMP/config" "$ROOT/bin/agentdock" job finish --project "$project" --summary "최종 완료" >/dev/null
compgen -G "$mirror/Reports/Final Report - * - Final.md" >/dev/null || fail "final report readable copy missing"
final_report="$(find "$mirror/Reports" -maxdepth 1 -type f -name 'Final Report - * - Final.md' | sort | tail -1)"
grep -q "최종 완료" "$final_report" || fail "final report content missing"
test -f "$mirror/_AgentDock Export Manifest.md" || fail "export manifest missing"

echo "obsidian job sync ok"
