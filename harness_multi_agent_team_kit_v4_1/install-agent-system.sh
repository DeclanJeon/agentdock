#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Install the multi-agent system into a real project.

Usage:
  ./install-agent-system.sh --project /path/to/project
  ./install-agent-system.sh /path/to/project

What it does:
  - Copies this kit into <project>/.agent-system
  - Creates <project>/.agent-work shared folders
  - Keeps your product code separate from agent operating documents
USAGE
}

PROJECT_ROOT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      PROJECT_ROOT="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "$PROJECT_ROOT" ]]; then
        PROJECT_ROOT="$1"
        shift
      else
        echo "Unknown argument: $1" >&2
        usage
        exit 1
      fi
      ;;
  esac
done

if [[ -z "$PROJECT_ROOT" ]]; then
  echo "Error: project path is required." >&2
  usage
  exit 1
fi

PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"
KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$PROJECT_ROOT/.agent-system"

mkdir -p "$TARGET"
rsync -a --delete \
  --exclude '.git' \
  --exclude '.agent-work' \
  --exclude '07_JOBS' \
  --exclude '08_DECISIONS' \
  --exclude '09_HANDOFFS' \
  --exclude '10_REPORTS' \
  --exclude '11_ARCHIVE' \
  "$KIT_ROOT/" "$TARGET/"

mkdir -p \
  "$PROJECT_ROOT/.agent-work/07_JOBS" \
  "$PROJECT_ROOT/.agent-work/08_DECISIONS" \
  "$PROJECT_ROOT/.agent-work/09_HANDOFFS" \
  "$PROJECT_ROOT/.agent-work/10_REPORTS" \
  "$PROJECT_ROOT/.agent-work/11_ARCHIVE" \
  "$PROJECT_ROOT/.agent-work/12_INBOX" \
  "$PROJECT_ROOT/.agent-work/13_OUTBOX" \
  "$PROJECT_ROOT/.agent-work/14_SHARED_CONTEXT"

cat > "$PROJECT_ROOT/.agent-work/README.md" <<README
# .agent-work

This directory is the shared workspace for tmux/Codex agents.

- 07_JOBS: job specs, task cards, job outputs
- 08_DECISIONS: decision records
- 09_HANDOFFS: team-to-team handoff files
- 10_REPORTS: completion reports and daily reports
- 11_ARCHIVE: closed jobs and historical records
- 12_INBOX: incoming assignments per agent/team
- 13_OUTBOX: completed outputs waiting for review
- 14_SHARED_CONTEXT: project context shared across agents
README

chmod +x "$TARGET/04_TMUX/"*.sh 2>/dev/null || true

echo "Installed agent system into: $TARGET"
echo "Created shared work area: $PROJECT_ROOT/.agent-work"
echo "Next: cd '$PROJECT_ROOT' && .agent-system/04_TMUX/start-codex-agents.sh"
