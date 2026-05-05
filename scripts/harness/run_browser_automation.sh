#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RESOLVER="$REPO_ROOT/scripts/_agent_os/resolve_trusted_harness_root.py"

if [[ ! -x "$RESOLVER" ]]; then
  echo "Missing trusted harness resolver: $RESOLVER" >&2
  exit 1
fi

HARNESS_ROOT="$("$RESOLVER" "$REPO_ROOT/repo_harness.toml")"
if [[ -z "$HARNESS_ROOT" ]]; then
  echo "Unable to resolve trusted harness root." >&2
  exit 1
fi

if [[ $# -eq 0 ]]; then
  echo "Usage: scripts/harness/run_browser_automation.sh <command> [args...]" >&2
  exit 64
fi

PYTHONPATH="$HARNESS_ROOT/scripts/harness${PYTHONPATH:+:$PYTHONPATH}" python3 - "$REPO_ROOT" "$@" <<'PY'
from pathlib import Path
from urllib.parse import urlparse
import sys

from capability_control_contract import candidate_urls, enforce_capability_request

repo = Path(sys.argv[1]).resolve()
argv = sys.argv[2:]
for url in candidate_urls(argv):
    parsed = urlparse(url)
    if not parsed.scheme or not parsed.hostname:
        continue
    origin = f"{parsed.scheme}://{parsed.hostname}"
    if parsed.port is not None:
        origin += f":{parsed.port}"
    allowed, reason = enforce_capability_request(
        repo,
        capability_id="browser-external",
        origin=origin,
        blocker_prefix="Browser automation blocked this navigation",
    )
    if not allowed:
        raise SystemExit(reason)
PY

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required for containerized browser automation." >&2
  exit 1
fi

DEFAULT_IMAGE="mcr.microsoft.com/playwright:v1.56.1-noble"
DEFAULT_ARTIFACT_DIR="$REPO_ROOT/.playwright-cli"
OVERRIDE_ARTIFACT="${AGENT_OS_BROWSER_OVERRIDE_ARTIFACT:-$REPO_ROOT/docs/exec-plans/active/browser-automation-override.json}"

require_override_artifact() {
  if [[ ! -f "$OVERRIDE_ARTIFACT" ]]; then
    echo "Browser automation override requested, but no override artifact exists: $OVERRIDE_ARTIFACT" >&2
    exit 1
  fi
  python3 - "$OVERRIDE_ARTIFACT" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
try:
    payload = json.loads(path.read_text(encoding="utf-8"))
except Exception as exc:
    raise SystemExit(f"Browser automation override artifact is not valid JSON: {path} ({exc})")
if not isinstance(payload, dict):
    raise SystemExit(f"Browser automation override artifact must decode to a JSON object: {path}")
for key in ("reason", "approved_by", "linked_plan", "created_at"):
    if not str(payload.get(key) or "").strip():
        raise SystemExit(f"Browser automation override artifact is missing required key '{key}': {path}")
PY
}

IMAGE="${AGENT_OS_BROWSER_IMAGE:-$DEFAULT_IMAGE}"
ARTIFACT_DIR="${AGENT_OS_BROWSER_ARTIFACT_DIR:-$DEFAULT_ARTIFACT_DIR}"
if [[ "$IMAGE" != "$DEFAULT_IMAGE" || "$ARTIFACT_DIR" != "$DEFAULT_ARTIFACT_DIR" ]]; then
  require_override_artifact
fi

mkdir -p "$ARTIFACT_DIR"

exec docker run --rm \
  --init \
  -e CI=1 \
  -e AGENT_OS_DOCKER_BROWSER=1 \
  -e PLAYWRIGHT_ARTIFACT_DIR=/workspace/.playwright-cli \
  -v "$REPO_ROOT:/workspace" \
  -w /workspace \
  "$IMAGE" \
  "$@"
