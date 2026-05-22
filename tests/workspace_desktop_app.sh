#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() { echo "workspace desktop app test failed: $*" >&2; exit 1; }

[[ -f package.json ]] || fail "package.json missing"
[[ -f vite.config.ts ]] || fail "vite.config.ts missing"
[[ -f tsconfig.json ]] || fail "tsconfig.json missing"
[[ -f index.html ]] || fail "index.html missing"
[[ -f src-ui/App.tsx ]] || fail "src-ui/App.tsx missing"
[[ -f src-ui/model/normalize.ts ]] || fail "src-ui/model/normalize.ts missing"
[[ -f src-ui/model/scene.ts ]] || fail "src-ui/model/scene.ts missing"
[[ -f src-ui/model/fixtures.ts ]] || fail "src-ui/model/fixtures.ts missing"
grep -q "emptySnapshot" src-ui/model/fixtures.ts || fail "empty live snapshot fallback missing"
if grep -q "demoSnapshot\|workspace.snapshot.demo" src-ui/model/fixtures.ts src-ui/App.tsx; then
  fail "desktop app must not render bundled mock/demo roles when live snapshot is unavailable"
fi
[[ -f src-ui/components/FinalReadinessPanel.tsx ]] || fail "FinalReadinessPanel missing"
[[ -f src-ui/components/ReportDesk.tsx ]] || fail "ReportDesk missing"
[[ -f src-ui/components/BlockerDesk.tsx ]] || fail "BlockerDesk missing"
[[ -f src-ui/scene/OfficeScene.tsx ]] || fail "OfficeScene missing"
[[ -f src-ui/scene/MissionBoard.tsx ]] || fail "MissionBoard missing"
[[ -f src-ui/scene/ReportDeskScene.tsx ]] || fail "ReportDeskScene missing"
[[ -f src-ui/scene/BlockerDeskScene.tsx ]] || fail "BlockerDeskScene missing"
[[ -f src-ui/scene/FinalGateScene.tsx ]] || fail "FinalGateScene missing"
[[ -f src-ui/scene/DenseRoleNavigator.tsx ]] || fail "DenseRoleNavigator missing"
[[ -f src-ui/components/CeoTaskComposer.tsx ]] || fail "CeoTaskComposer missing"
[[ -f src-tauri/Cargo.toml ]] || fail "src-tauri/Cargo.toml missing"
[[ -f src-tauri/src/lib.rs ]] || fail "src-tauri/src/lib.rs missing"
[[ -f src-tauri/tauri.conf.json ]] || fail "src-tauri/tauri.conf.json missing"

node -e 'const p=require("./package.json"); if(!p.scripts || !p.scripts["tauri:dev"] || !p.scripts["tauri:build"] || !p.scripts.build) process.exit(1)'
grep -q "base: './'" vite.config.ts || fail "vite config must use relative asset base for Tauri app protocol"

grep -q 'agentdock workspace app' README.md || fail "README missing desktop app launch docs"
agentdock_help="$(./bin/agentdock help)"
grep -q 'workspace app' <<<"$agentdock_help" || fail "agentdock help missing workspace app"
workspace_app_help="$(./bin/agentdock workspace app --help)"
grep -q 'agentdock-workspace' <<<"$workspace_app_help" || fail "workspace app help missing binary guidance"
grep -q 'skip-hermes-install' <<<"$workspace_app_help" || fail "workspace app help missing Hermes auto-install opt-out"
grep -q 'install_hermes_if_missing' install.sh || fail "install.sh missing first-install Hermes bootstrap"
grep -q 'raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh' install.sh || fail "install.sh missing official Hermes GitHub installer URL"
python3 tests/fixtures/workspace/validate_workspace_fixtures.py

grep -q 'workspace_snapshot' src-tauri/src/lib.rs || fail "Tauri adapter missing workspace_snapshot command"
grep -q 'workspace_watch_start' src-tauri/src/lib.rs || fail "Tauri adapter missing live workspace watch command"
grep -q 'workspace_changed' src-tauri/src/lib.rs || fail "Tauri adapter missing workspace changed event"
grep -q 'agentdock_job_create' src-tauri/src/lib.rs || fail "Tauri adapter missing controlled job-create command"
grep -q 'Command::new' src-tauri/src/lib.rs || fail "Tauri adapter must use structured command execution"
grep -q 'FinalReadinessPanel' src-ui/components/PixelOffice.tsx || fail "PixelOffice missing final readiness decision surface"
grep -q 'ReportDesk' src-ui/components/PixelOffice.tsx || fail "PixelOffice missing report desk decision surface"
grep -q 'BlockerDesk' src-ui/components/PixelOffice.tsx || fail "PixelOffice missing blocker desk decision surface"
grep -q 'aria-label="Missing report role' src-ui/components/ReportDesk.tsx || fail "ReportDesk missing accessible missing-role chips"
grep -q 'Final ready' src-ui/components/FinalReadinessPanel.tsx || fail "FinalReadinessPanel missing ready/not-ready text state"
grep -q 'No active blocker' src-ui/components/BlockerDesk.tsx || fail "BlockerDesk missing empty blocker state"
if grep -Eq 'sh -c|bash -c|/bin/sh|/bin/bash' src-tauri/src/lib.rs; then
  fail "Tauri adapter must not invoke shell"
fi
grep -q 'duration_ms' src-tauri/src/lib.rs || fail "Tauri adapter result missing duration_ms"
grep -q 'canonicalize_project_root' src-tauri/src/lib.rs || fail "Tauri adapter missing project root canonicalization helper"
grep -q 'validate_agentdock_project' src-tauri/src/lib.rs || fail "Tauri adapter missing .agentdock/.agent-work validation"
grep -q 'redact_text' src-tauri/src/lib.rs || fail "Tauri adapter missing stderr/stdout redaction helper"
grep -q 'redactText' src-ui/model/snapshot.ts || fail "React model missing redactText helper"
grep -q 'SUPPORTED_SCHEMA_VERSION' src-ui/model/snapshot.ts || fail "React model missing supported schema constant"
grep -q 'isSupportedSnapshot' src-ui/model/snapshot.ts || fail "React model missing supported schema guard"
grep -q 'Unsupported snapshot schema' src-ui/App.tsx || fail "React app missing unsupported schema error handling"
grep -q "'live'" src-ui/App.tsx || fail "React app missing live mode"
grep -q "'idle'" src-ui/App.tsx || fail "React app missing idle/not-connected mode"
grep -q "'stale'" src-ui/App.tsx || fail "React app missing stale mode"
grep -q "'error'" src-ui/App.tsx || fail "React app missing error mode"
grep -q 'Refresh snapshot' src-ui/App.tsx || fail "React app missing manual refresh button"
grep -q 'workspace_watch_start' src-ui/App.tsx || fail "React app missing live watch startup"
grep -q 'workspace_changed' src-ui/App.tsx || fail "React app missing workspace changed event listener"
grep -q 'refreshInFlight' src-ui/App.tsx || fail "React app missing in-flight refresh guard"
grep -q 'lastGoodSnapshot' src-ui/App.tsx || fail "React app missing last-good snapshot preservation"
grep -q 'ErrorStrip' src-ui/App.tsx || fail "React app missing ErrorStrip component"
grep -q 'OfficeScene' src-ui/App.tsx || fail "React app missing pixel office scene mount"
grep -q 'CeoTaskComposer' src-ui/App.tsx || fail "React app missing CEO task composer mount"
grep -q 'agentdock_job_create' src-ui/App.tsx || fail "React app missing controlled job-create invoke"
grep -q 'Send to CEO' src-ui/components/CeoTaskComposer.tsx || fail "CEO task composer missing submit copy"
grep -qi 'no arbitrary shell' src-ui/components/CeoTaskComposer.tsx || fail "CEO task composer missing trust copy"
if grep -E "invoke<.*\('(recruit|broadcast|finish|report|task|send)'" src-ui/App.tsx src-ui/components/CeoTaskComposer.tsx; then
  fail "CEO task UI must not invoke recruit/broadcast/finish/report/task-edit controls"
fi
grep -q "visualMode === 'pixelOffice'" src-ui/App.tsx || fail "React app missing pixelOffice render switch"
grep -q 'classic-workspace-layout' src-ui/App.tsx || fail "React app missing classic fallback"
bash tests/workspace_visual_scene.sh
cargo test --manifest-path src-tauri/Cargo.toml
npm run build
cargo check --manifest-path src-tauri/Cargo.toml
