#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

version="$(tr -d '[:space:]' < VERSION)"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  printf 'VERSION must contain semver like 0.1.5, got: %s\n' "$version" >&2
  exit 1
}

expected_tag="v$version"
if [[ -n "${GITHUB_REF_NAME:-}" && "${GITHUB_REF_NAME:-}" == v* && "$GITHUB_REF_NAME" != "$expected_tag" ]]; then
  printf 'Release tag mismatch: GITHUB_REF_NAME=%s but VERSION=%s (%s expected)\n' "$GITHUB_REF_NAME" "$version" "$expected_tag" >&2
  exit 1
fi

grep -Fq "AGENTDOCK_VERSION=\"$version\"" bin/agentdock || {
  printf 'bin/agentdock AGENTDOCK_VERSION does not match VERSION=%s\n' "$version" >&2
  exit 1
}

grep -Fq "agentdock $version" tests/smoke.sh || {
  printf 'tests/smoke.sh expected version does not match VERSION=%s\n' "$version" >&2
  exit 1
}

grep -Fq "version-$version-" README.md || {
  printf 'README version badge does not match VERSION=%s\n' "$version" >&2
  exit 1
}

grep -Fq "git tag $expected_tag" README.md || {
  printf 'README release tag example does not match %s\n' "$expected_tag" >&2
  exit 1
}

grep -Fq "git push origin $expected_tag" README.md || {
  printf 'README release push example does not match %s\n' "$expected_tag" >&2
  exit 1
}

grep -Fq "Version \`$version\`" README.md || {
  printf 'README status version does not match VERSION=%s\n' "$version" >&2
  exit 1
}

printf 'Version check ok: %s\n' "$version"
