#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RESOLVER="$ROOT_DIR/scripts/_agent_os/resolve_trusted_harness_root.py"
[[ -f "$RESOLVER" ]] || { echo "Missing trusted harness resolver: $RESOLVER" >&2; exit 1; }

RESOLVED_HARNESS_ROOT="$(python3 "$RESOLVER" "$ROOT_DIR/repo_harness.toml")"
exec python3 "$RESOLVED_HARNESS_ROOT/scripts/harness/record_tdd_run.py" --repo "$ROOT_DIR" "$@"
