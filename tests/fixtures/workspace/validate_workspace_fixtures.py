#!/usr/bin/env python3
"""Validate CLI workspace snapshot fixtures.

This intentionally validates the stable, read-only snapshot-to-UI contract only.
It must not shell out, mutate .agent-work, or depend on a live AgentDock job.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
FIXTURES = {
    "active-normal.json",
    "missing-reports.json",
    "blocker-present.json",
    "final-ready.json",
    "dense-20-roles.json",
    "dense-50-roles.json",
    "stale-last-good.json",
    "error-state.json",
    "orchestration-solo.json",
    "orchestration-standard-team.json",
    "orchestration-qa-blocked.json",
    "orchestration-active-tft.json",
    "orchestration-legacy.json",
}
REQUIRED_TOP = {
    "schema_version",
    "generated_at",
    "project",
    "job",
    "reports",
    "layout",
    "commands",
    "roles",
    "alerts",
    "warnings",
}
REQUIRED_PROJECT = {"name", "root", "session", "session_name"}
REQUIRED_JOB = {"id", "path", "readme_path", "lifecycle", "lifecycle_status", "final_ready", "final_ready_reason"}
REQUIRED_REPORTS = {"submitted", "required", "submitted_selected_roles", "required_selected_roles", "missing_roles"}
REQUIRED_LAYOUT = {"role_count", "density", "density_thresholds"}
REQUIRED_COMMANDS = {"mode", "write_bridge_enabled", "allowed_read_commands"}
REQUIRED_ROLE = {"id", "role_id", "department", "status", "selected", "configured", "running_pane", "task_path", "latest_report_path"}


def fail(path: Path, message: str) -> None:
    raise AssertionError(f"{path.name}: {message}")


def require_keys(path: Path, obj: dict, required: set[str], label: str) -> None:
    missing = sorted(required - set(obj))
    if missing:
        fail(path, f"missing {label} keys: {', '.join(missing)}")


def validate_fixture(path: Path) -> dict:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        fail(path, f"invalid JSON: {exc}")
    if not isinstance(data, dict):
        fail(path, "fixture root must be an object")

    require_keys(path, data, REQUIRED_TOP, "top-level")
    if data["schema_version"] != "workspace.snapshot.v1":
        fail(path, "schema_version must be workspace.snapshot.v1")

    require_keys(path, data["project"], REQUIRED_PROJECT, "project")
    require_keys(path, data["job"], REQUIRED_JOB, "job")
    require_keys(path, data["reports"], REQUIRED_REPORTS, "reports")
    require_keys(path, data["layout"], REQUIRED_LAYOUT, "layout")
    require_keys(path, data["commands"], REQUIRED_COMMANDS, "commands")

    if data["commands"]["mode"] != "read-only":
        fail(path, "commands.mode must remain read-only")
    if data["commands"]["write_bridge_enabled"] is not False:
        fail(path, "write_bridge_enabled must be false")
    # `agentdock report --fast` is a read-only status command in the current CLI.
    # Reject only mutation/action surfaces that would let CLI diagnostics change AgentDock state.
    for forbidden in (" job finish", " job report", " report --from", " inbox send", " send", " recruit", " edit", " exec"):
        if any(forbidden in f" {cmd} " for cmd in data["commands"].get("allowed_read_commands", [])):
            fail(path, f"forbidden write/action command advertised: {forbidden.strip()}")

    roles = data["roles"]
    if not isinstance(roles, list) or not roles:
        fail(path, "roles must be a non-empty list")
    if data["layout"]["role_count"] != len(roles):
        fail(path, "layout.role_count must equal len(roles)")
    role_ids = {r.get("id") for r in roles if isinstance(r, dict)}
    for idx, role in enumerate(roles):
        if not isinstance(role, dict):
            fail(path, f"roles[{idx}] must be an object")
        require_keys(path, role, REQUIRED_ROLE, f"roles[{idx}]")
        if role["id"] != role["role_id"]:
            fail(path, f"roles[{idx}] id and role_id must match for backward-compatible UI lookup")

    missing_roles = data["reports"]["missing_roles"]
    if not isinstance(missing_roles, list):
        fail(path, "reports.missing_roles must be a list")
    unknown_missing = sorted(set(missing_roles) - role_ids)
    if unknown_missing:
        fail(path, "missing_roles references unknown roles: " + ", ".join(unknown_missing))

    if path.name == "missing-reports.json":
        if data["job"]["final_ready"] is not False or not missing_roles:
            fail(path, "must model final_ready=false with at least one missing report")
    if path.name == "blocker-present.json":
        if data["job"]["final_ready"] is not False:
            fail(path, "must model final_ready=false")
        if not data.get("alerts"):
            fail(path, "must include at least one blocker alert")
        if not any(role.get("status") == "blocked" for role in roles):
            fail(path, "must include at least one blocked role")
    if path.name == "final-ready.json":
        if data["job"]["final_ready"] is not True or missing_roles:
            fail(path, "must model final_ready=true with no missing reports")
    if path.name == "dense-20-roles.json":
        if len(roles) != 20 or data["layout"]["role_count"] != 20:
            fail(path, "must contain exactly 20 roles")
        if data["layout"]["density"] not in {"dense", "crowded"}:
            fail(path, "20-role fixture must advertise dense/crowded layout")
        if not missing_roles:
            fail(path, "must include at least one missing report for dense readability evidence")
    if path.name == "dense-50-roles.json":
        if len(roles) != 50 or data["layout"]["role_count"] != 50:
            fail(path, "must contain exactly 50 roles")
        if data["layout"]["density"] not in {"dense", "crowded"}:
            fail(path, "50-role fixture must advertise dense/crowded layout")
    if path.name in {"stale-last-good.json", "error-state.json"}:
        expected = {
            "stale-last-good.json": "stale",
            "error-state.json": "error",
        }[path.name]
        if data.get("source_mode") != expected:
            fail(path, f"must advertise source_mode={expected}")
        if data["job"]["final_ready"] is not False:
            fail(path, "fallback/error fixtures must not appear final-ready")

    return data


def main() -> int:
    found = {p.name for p in ROOT.glob("*.json")}
    missing = sorted(FIXTURES - found)
    if missing:
        raise AssertionError("missing required fixture files: " + ", ".join(missing))
    for fixture in sorted(FIXTURES):
        validate_fixture(ROOT / fixture)
    print(f"workspace fixture validation ok ({len(FIXTURES)} fixtures)")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"workspace fixture validation failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
