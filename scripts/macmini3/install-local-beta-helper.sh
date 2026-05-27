#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
label="${AGENT_PULSE_HELPER_LABEL:-com.agentpulse.helper.55110.beta-edge}"
helper_port="${AGENT_PULSE_HELPER_PORT:-55110}"
public_url="${AGENT_PULSE_PUBLIC_URL:-https://beta.dope-ai.kr/agent-pulse}"
public_base_path="${AGENT_PULSE_PUBLIC_BASE_PATH:-/agent-pulse/}"
state_dir="${AGENT_PULSE_BETA_STATE_DIR:-$HOME/Library/Application Support/Agent Pulse Beta}"
runtime_dir="${AGENT_PULSE_BETA_RUNTIME_DIR:-$state_dir/runtime}"
keychain_service="${AGENT_PULSE_KEYCHAIN_SERVICE:-}"
launch_agent_dir="$HOME/Library/LaunchAgents"
log_dir="$HOME/Library/Logs"
plist_path="$launch_agent_dir/$label.plist"
stdout_path="$log_dir/$label.log"
stderr_path="$log_dir/$label.error.log"
PNPM_COMMAND=()
STAGED_RUNTIME_DIR=""

log() {
  echo "[agent-pulse-local-helper] $*"
}

require_command() {
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    echo "Missing required command: $name" >&2
    exit 127
  fi
}

has_device_index_for_service() {
  local service="$1"
  security find-generic-password -w -s "$service" -a devices-index >/dev/null 2>&1
}

choose_keychain_service() {
  if [[ -n "$keychain_service" ]]; then
    return 0
  fi
  if has_device_index_for_service "AgentPulseBeta"; then
    keychain_service="AgentPulseBeta"
    return 0
  fi
  if has_device_index_for_service "com.agentpulse.helper"; then
    keychain_service="com.agentpulse.helper"
    return 0
  fi
  keychain_service="AgentPulseBeta"
}

stage_runtime() {
  STAGED_RUNTIME_DIR="$(mktemp -d "$state_dir/runtime.new.XXXXXX")"
  log "Staging LaunchAgent-readable runtime at $STAGED_RUNTIME_DIR"
  mkdir -p \
    "$STAGED_RUNTIME_DIR/apps/helper" \
    "$STAGED_RUNTIME_DIR/apps/tablet" \
    "$STAGED_RUNTIME_DIR/scripts/macmini3"

  cp -R "$repo_root/apps/helper/dist" "$STAGED_RUNTIME_DIR/apps/helper/dist"
  cp -R "$repo_root/apps/tablet/dist" "$STAGED_RUNTIME_DIR/apps/tablet/dist"
  cp "$repo_root/scripts/macmini3/run-agentpulse-beta-helper.sh" "$STAGED_RUNTIME_DIR/scripts/macmini3/run-agentpulse-beta-helper.sh"
  chmod +x "$STAGED_RUNTIME_DIR/scripts/macmini3/run-agentpulse-beta-helper.sh"

  node --input-type=module - "$repo_root/package.json" "$STAGED_RUNTIME_DIR/package.json" <<'NODE'
import { readFile, writeFile } from 'node:fs/promises';

const sourcePath = process.argv[2];
const targetPath = process.argv[3];
const source = JSON.parse(await readFile(sourcePath, 'utf8'));
const runtimePackage = {
  name: 'agent-pulse-beta-runtime',
  private: true,
  type: 'module',
  dependencies: source.dependencies ?? {}
};
await writeFile(targetPath, `${JSON.stringify(runtimePackage, null, 2)}\n`, 'utf8');
NODE

  if [[ ! -d "$STAGED_RUNTIME_DIR/node_modules/@hono/node-server" ]]; then
    (cd "$STAGED_RUNTIME_DIR" && npm install --omit=dev --no-audit --no-fund --package-lock=false)
  fi

  if [[ -e "$runtime_dir" ]]; then
    mv "$runtime_dir" "$runtime_dir.previous.$(date -u '+%Y%m%dT%H%M%SZ')"
  fi
  mv "$STAGED_RUNTIME_DIR" "$runtime_dir"
  STAGED_RUNTIME_DIR=""
}

ensure_pnpm() {
  if command -v pnpm >/dev/null 2>&1; then
    PNPM_COMMAND=(pnpm)
    return 0
  fi
  if command -v corepack >/dev/null 2>&1; then
    corepack enable >/dev/null 2>&1 || true
    if command -v pnpm >/dev/null 2>&1; then
      PNPM_COMMAND=(pnpm)
      return 0
    fi
  fi
  require_command npm
  PNPM_COMMAND=(npm exec --yes pnpm@10.28.2 --)
}

wait_for_agentpulse_health() {
  local url="http://127.0.0.1:${helper_port}/health/get"
  local body=""

  for _ in $(seq 1 90); do
    if body="$(curl --connect-timeout 2 --max-time 8 -fsSL "$url" 2>/dev/null)" &&
      printf '%s' "$body" | python3 -c '
import json
import sys

try:
    payload = json.load(sys.stdin)
except Exception:
    raise SystemExit(1)
if payload.get("codexAppServer") != "connected":
    raise SystemExit(2)
' >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done

  echo "Timed out waiting for local Agent Pulse helper health at $url." >&2
  if [[ -n "$body" ]]; then
    printf '%s\n' "$body" | sed -n '1,20p' >&2 || true
  fi
  return 1
}

case "$public_url" in
  https://*) ;;
  *)
    echo "AGENT_PULSE_PUBLIC_URL must be an https URL." >&2
    exit 1
    ;;
esac

require_command curl
require_command launchctl
require_command lsof
require_command node
require_command python3
choose_keychain_service
log "Using paired-device keychain service $keychain_service"

uid="$(id -u)"
if ! launchctl print "gui/$uid" >/dev/null 2>&1; then
  echo "No GUI launchctl domain is available for Agent Pulse helper." >&2
  exit 1
fi

if [[ "${AGENT_PULSE_SKIP_BUILD:-0}" != "1" ]]; then
  ensure_pnpm
  log "Building Agent Pulse with public base path $public_base_path"
  (cd "$repo_root" && AGENT_PULSE_PUBLIC_BASE_PATH="$public_base_path" "${PNPM_COMMAND[@]}" build)
fi

mkdir -p "$launch_agent_dir" "$log_dir" "$state_dir"
stage_runtime

launchctl bootout "gui/$uid/$label" >/dev/null 2>&1 || true
launchctl bootout "gui/$uid" "$plist_path" >/dev/null 2>&1 || true

for _ in $(seq 1 20); do
  if ! launchctl print "gui/$uid/$label" >/dev/null 2>&1; then
    break
  fi
  sleep 0.5
done

if lsof -tiTCP:"$helper_port" -sTCP:LISTEN >/dev/null 2>&1; then
  echo "Port $helper_port is already in use by a non-Agent Pulse beta helper." >&2
  lsof -nP -iTCP:"$helper_port" -sTCP:LISTEN >&2 || true
  exit 1
fi

AGENT_PULSE_REPO_ROOT="$repo_root" \
AGENT_PULSE_RUNTIME_DIR="$runtime_dir" \
AGENT_PULSE_HELPER_LABEL="$label" \
AGENT_PULSE_HELPER_PORT="$helper_port" \
AGENT_PULSE_PUBLIC_URL="$public_url" \
AGENT_PULSE_PUBLIC_BASE_PATH="$public_base_path" \
AGENT_PULSE_BETA_STATE_DIR="$state_dir" \
AGENT_PULSE_KEYCHAIN_SERVICE="$keychain_service" \
AGENT_PULSE_HELPER_STDOUT_PATH="$stdout_path" \
AGENT_PULSE_HELPER_STDERR_PATH="$stderr_path" \
python3 - "$plist_path" <<'PY'
import os
import plistlib
import shlex
import sys
from pathlib import Path

plist_path = Path(sys.argv[1])
repo_root = os.environ["AGENT_PULSE_REPO_ROOT"]
runtime_dir = os.environ["AGENT_PULSE_RUNTIME_DIR"]
label = os.environ["AGENT_PULSE_HELPER_LABEL"]
helper_port = os.environ["AGENT_PULSE_HELPER_PORT"]
public_url = os.environ["AGENT_PULSE_PUBLIC_URL"]
public_base_path = os.environ["AGENT_PULSE_PUBLIC_BASE_PATH"]
state_dir = os.environ["AGENT_PULSE_BETA_STATE_DIR"]
keychain_service = os.environ["AGENT_PULSE_KEYCHAIN_SERVICE"]
stdout_path = os.environ["AGENT_PULSE_HELPER_STDOUT_PATH"]
stderr_path = os.environ["AGENT_PULSE_HELPER_STDERR_PATH"]

command = " ".join([
    "export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH;",
    "cd", shlex.quote(runtime_dir), "&&",
    "exec env",
    "AGENT_PULSE_SKIP_BUILD=1",
    f"AGENT_PULSE_HELPER_PORT={shlex.quote(helper_port)}",
    f"AGENT_PULSE_PUBLIC_URL={shlex.quote(public_url)}",
    f"AGENT_PULSE_PUBLIC_BASE_PATH={shlex.quote(public_base_path)}",
    f"AGENT_PULSE_BETA_STATE_DIR={shlex.quote(state_dir)}",
    f"AGENT_PULSE_KEYCHAIN_SERVICE={shlex.quote(keychain_service)}",
    "AGENT_PULSE_DISABLE_CODEX_DESKTOP=1",
    "AGENT_PULSE_SKIP_MANAGED_TUNNEL=1",
    "bash", shlex.quote(str(Path(runtime_dir) / "scripts/macmini3/run-agentpulse-beta-helper.sh")),
])

payload = {
    "Label": label,
    "ProgramArguments": ["/bin/zsh", "-lc", command],
    "RunAtLoad": True,
    "KeepAlive": True,
    "WorkingDirectory": runtime_dir,
    "StandardOutPath": stdout_path,
    "StandardErrorPath": stderr_path,
}
plist_path.write_bytes(plistlib.dumps(payload, sort_keys=False))
PY

launchctl bootstrap "gui/$uid" "$plist_path"
launchctl kickstart -k "gui/$uid/$label" >/dev/null 2>&1 || true

for _ in $(seq 1 20); do
  if launchctl print "gui/$uid/$label" >/dev/null 2>&1; then
    break
  fi
  sleep 0.5
done

wait_for_agentpulse_health
log "Installed local Agent Pulse helper $label on 127.0.0.1:$helper_port."
