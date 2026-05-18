#!/usr/bin/env bash
set -euo pipefail

PREFIX="$HOME/.local"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix) PREFIX="${2:-}"; shift 2 ;;
    --prefix=*) PREFIX="${1#*=}"; shift ;;
    *) shift ;;
  esac
done

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$PREFIX/bin"
SHARE_DIR="$PREFIX/share/agentdock"

write_role_template() {
  local file="$1" title="$2" use="$3" source="${4:-BMAD Method default BMM agent catalog.}"
  {
    printf '# %s\n\n' "$title"
    printf 'Use: %s\n\n' "$use"
    printf 'Source: %s\n' "$source"
  } > "$file"
}

mkdir -p "$BIN_DIR" "$SHARE_DIR/bin" "$SHARE_DIR/adapters" "$SHARE_DIR/roles/bmad" "$SHARE_DIR/roles/agentdock"
cp "$ROOT/bin/agentdock" "$SHARE_DIR/bin/agentdock"
cp "$ROOT/adapters/"*.conf "$SHARE_DIR/adapters/"
if compgen -G "$ROOT/roles/bmad/*.md" >/dev/null; then
  cp "$ROOT/roles/bmad/"*.md "$SHARE_DIR/roles/bmad/"
fi
if compgen -G "$ROOT/roles/agentdock/*.md" >/dev/null; then
  cp "$ROOT/roles/agentdock/"*.md "$SHARE_DIR/roles/agentdock/"
fi
write_role_template "$SHARE_DIR/roles/bmad/bmad-agent-dev.md" "Developer (Amelia)" "dev story execution, quick dev, QA test generation, code review, sprint planning, story creation, retrospective."
write_role_template "$SHARE_DIR/roles/bmad/bmad-analyst.md" "Analyst (Mary)" "discovery, brainstorming, market/domain/technical research, project brief, PRFAQ challenge, document project."
write_role_template "$SHARE_DIR/roles/bmad/bmad-architect.md" "Architect (Winston)" "architecture design, technical direction, implementation readiness."
write_role_template "$SHARE_DIR/roles/bmad/bmad-pm.md" "Product Manager (John)" "PRD creation/validation/editing, epics and stories, implementation readiness, course correction."
write_role_template "$SHARE_DIR/roles/bmad/bmad-tech-writer.md" "Technical Writer (Paige)" "document project, write/update docs, standards, Mermaid diagrams, doc validation, concept explanation."
write_role_template "$SHARE_DIR/roles/bmad/bmad-ux-designer.md" "UX Designer (Sally)" "UX design creation and interaction planning."
write_role_template "$SHARE_DIR/roles/agentdock/agentdock-ceo.md" "CEO Orchestrator" "job intake, team design, role naming, delegation, lifecycle ownership, final delivery accountability." "AgentDock supplemental role template. BMAD default BMM does not currently ship a CEO agent."
write_role_template "$SHARE_DIR/roles/agentdock/agentdock-cto.md" "CTO / Technical Director" "technical strategy, architecture review, risk tradeoffs, implementation sequencing, engineering standards, cross-team technical decisions." "AgentDock supplemental role template. BMAD default BMM maps part of this work to Architect (Winston), but does not currently ship a CTO agent."
write_role_template "$SHARE_DIR/roles/agentdock/agentdock-marketing.md" "Marketing Strategist" "positioning, target audience, messaging, launch plan, growth channels, competitive framing, campaign requirements." "AgentDock supplemental role template. BMAD default BMM does not currently ship a marketing agent."
write_role_template "$SHARE_DIR/roles/agentdock/agentdock-planner.md" "Planning / Delivery Manager" "roadmap slicing, milestone planning, dependency tracking, task sequencing, scope control, delivery coordination." "AgentDock supplemental role template. BMAD default BMM maps product planning to Product Manager (John), but does not currently ship a separate planning agent."
write_role_template "$SHARE_DIR/roles/agentdock/agentdock-qa.md" "QA / Quality Engineer" "test strategy, acceptance validation, regression planning, bug reproduction, release-readiness checks, risk-based verification." "AgentDock supplemental role template. BMAD default BMM provides QA test generation through Developer (Amelia); enterprise test architecture lives in BMAD's separate TEA module."
cp "$ROOT/VERSION" "$SHARE_DIR/VERSION"
chmod +x "$SHARE_DIR/bin/agentdock"
ln -sf "$SHARE_DIR/bin/agentdock" "$BIN_DIR/agentdock"
ln -sf "$SHARE_DIR/bin/agentdock" "$BIN_DIR/adock"
ln -sf "$SHARE_DIR/bin/agentdock" "$BIN_DIR/adock-delegate"
ln -sf "$SHARE_DIR/bin/agentdock" "$BIN_DIR/agentdock-delegate"

printf 'Installed AgentDock to %s\n' "$SHARE_DIR"
printf 'Executable: %s/agentdock\n' "$BIN_DIR"
printf 'Alias: %s/adock\n' "$BIN_DIR"
printf 'Hermes delegate helper: %s/adock-delegate\n' "$BIN_DIR"
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) printf 'Add %s to PATH if agentdock/adock is not found.\n' "$BIN_DIR" ;;
esac
