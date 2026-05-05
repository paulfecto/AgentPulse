#!/usr/bin/env bash
set -euo pipefail
require_python311() {
  if ! python3 - <<'PY' >/dev/null 2>&1
import sys
raise SystemExit(0 if sys.version_info >= (3, 11) else 1)
PY
  then
    echo "Repo-local Codex launcher requires python3 >= 3.11." >&2
    exit 1
  fi
}
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TARGET_DIR="$ROOT_DIR/.codex-home"
START_DIR="${PWD:-$ROOT_DIR}"
RESOLVER="$ROOT_DIR/scripts/_agent_os/resolve_trusted_harness_root.py"
require_python311
mkdir -p "$TARGET_DIR"
mkdir -p "$TARGET_DIR/log"
[[ -f "$RESOLVER" ]] || { echo "Missing trusted harness resolver: $RESOLVER" >&2; exit 1; }
RESOLVED_HARNESS_ROOT="$(python3 "$RESOLVER" "$ROOT_DIR/repo_harness.toml")"
RUNTIME_DIR_OUTPUT="$(python3 - "$ROOT_DIR/.codex/config.toml" "$ROOT_DIR" <<'PY'
import sys, tomllib
from pathlib import Path
config_path = Path(sys.argv[1])
repo_root = Path(sys.argv[2])
with config_path.open("rb") as handle:
    data = tomllib.load(handle)
for key in ("log_dir", "sqlite_home"):
    value = str(data.get(key) or "").strip()
    if not value:
        continue
    path = Path(value)
    if not path.is_absolute():
        path = repo_root / path
    print(path)
PY
)" || {
  echo "[agentOS] failed to parse $ROOT_DIR/.codex/config.toml for runtime directories; falling back to default repo-local runtime paths" >&2
  RUNTIME_DIR_OUTPUT=""
}
RUNTIME_DIRS=()
if [[ -n "$RUNTIME_DIR_OUTPUT" ]]; then
  while IFS= read -r line; do
    RUNTIME_DIRS+=("$line")
  done <<<"$RUNTIME_DIR_OUTPUT"
fi
for runtime_dir in "${RUNTIME_DIRS[@]}"; do
  mkdir -p "$runtime_dir"
done

cleanup() {
  local phase="$1"
  local log_file="$CLEANUP_LOG_FILE"
  local status=0
  if ! "$ROOT_DIR/scripts/codex/clean_repo_artifacts.sh" >>"$log_file" 2>&1; then
    echo "[agentOS] artifact cleanup failed during $phase; inspect $log_file" >&2
    status=1
  fi
  return "$status"
}

CLEANUP_LOG_DIR="${RUNTIME_DIRS[0]:-$TARGET_DIR/log}"
mkdir -p "$CLEANUP_LOG_DIR"
CLEANUP_LOG_FILE="$CLEANUP_LOG_DIR/artifact-cleanup-$(date '+%Y%m%d-%H%M%S')-$$.log"
trap 'cleanup shutdown || true' EXIT
cleanup startup || true

export CODEX_HOME="$TARGET_DIR"

case "$START_DIR" in
  "$ROOT_DIR"|"$ROOT_DIR"/*) cd "$START_DIR" ;;
  *) cd "$ROOT_DIR" ;;
esac
CODEX_BIN="${CODEX_CLI_BIN:-codex}"
exec python3 "$RESOLVED_HARNESS_ROOT/scripts/harness/run_supervised_lane.py" \
  --repo "$ROOT_DIR" \
  --lane codex \
  --binary "$CODEX_BIN" \
  --start-dir "$START_DIR" \
  -- "$@"
