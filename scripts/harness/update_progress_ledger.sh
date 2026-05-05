#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RESOLVER="$ROOT_DIR/scripts/_agent_os/resolve_trusted_harness_root.py"
[[ -f "$RESOLVER" ]] || { echo "Missing trusted harness resolver: $RESOLVER" >&2; exit 1; }

RESOLVED_HARNESS_ROOT="$(python3 "$RESOLVER" "$ROOT_DIR/repo_harness.toml")"
python3 "$RESOLVED_HARNESS_ROOT/scripts/harness/render_progress_ledger.py" --repo "$ROOT_DIR" "$@"
if python3 - "$ROOT_DIR/repo_harness.toml" <<'PY' >/dev/null 2>&1
import sys, tomllib
from pathlib import Path
with Path(sys.argv[1]).open("rb") as handle:
    data = tomllib.load(handle)
install = data.get("install") or {}
enabled = install.get("enabled_features") if isinstance(install, dict) else []
frontier = data.get("frontier") or {}
raise SystemExit(
    0
    if isinstance(enabled, list)
    and "frontier" in enabled
    and isinstance(frontier, dict)
    and frontier.get("enabled") is True
    else 1
)
PY
then
  python3 "$RESOLVED_HARNESS_ROOT/scripts/harness/render_team_ledger.py" --repo "$ROOT_DIR"
fi
python3 "$RESOLVED_HARNESS_ROOT/scripts/harness/render_state_ledger.py" --repo "$ROOT_DIR"
if python3 - "$ROOT_DIR/repo_harness.toml" <<'PY' >/dev/null 2>&1
import sys, tomllib
from pathlib import Path
with Path(sys.argv[1]).open("rb") as handle:
    data = tomllib.load(handle)
install = data.get("install") or {}
enabled = install.get("enabled_features") if isinstance(install, dict) else []
board = data.get("developer_progress_board") or {}
raise SystemExit(0 if isinstance(enabled, list) and "developer-progress-board" in enabled and isinstance(board, dict) and board.get("enabled") is True else 1)
PY
then
  exec python3 "$RESOLVED_HARNESS_ROOT/scripts/harness/render_developer_progress.py" --repo "$ROOT_DIR"
fi
