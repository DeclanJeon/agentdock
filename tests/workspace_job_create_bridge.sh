#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

cargo test --manifest-path src-tauri/Cargo.toml fake_agentdock_job_create_uses_single_request_argv -- --nocapture

echo "workspace job create bridge ok"
