#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

expected_sha="${1:-${AGENT_PULSE_EXPECTED_SHA:-}}"
public_url="${AGENT_PULSE_PUBLIC_URL:-https://beta.dope-ai.kr/agent-pulse}"
public_base_path="${AGENT_PULSE_PUBLIC_BASE_PATH:-/agent-pulse/}"
edge_port="${AGENT_PULSE_EDGE_PORT:-4355}"
helper_port="${AGENT_PULSE_HELPER_PORT:-55110}"
launch_label="${AGENT_PULSE_LAUNCH_LABEL:-com.agentpulse.helper.55110.beta-edge}"
launch_agent_dir="$HOME/Library/LaunchAgents"
log_dir="$HOME/Library/Logs"
plist_path="$launch_agent_dir/$launch_label.plist"
stdout_path="$log_dir/$launch_label.log"
stderr_path="$log_dir/$launch_label.error.log"
PNPM_COMMAND=()

log() {
  echo "[agent-pulse-beta-deploy] $*"
}

request_body() {
  local url="$1"
  curl --connect-timeout 5 --max-time 20 -fsSL "$url"
}

require_command() {
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    echo "Missing required command on macmini3: $name" >&2
    exit 1
  fi
}

wait_for_url_contains() {
  local url="$1"
  local pattern="$2"
  local attempts="${3:-60}"
  local body=""
  for attempt in $(seq 1 "$attempts"); do
    if body="$(request_body "$url" 2>/dev/null)" && printf '%s' "$body" | grep -q "$pattern"; then
      return 0
    fi
    sleep 2
  done
  echo "Timed out waiting for $url to contain $pattern" >&2
  printf '%s\n' "$body" | sed -n '1,20p' >&2 || true
  return 1
}

wait_for_public_or_local_agentpulse() {
  if wait_for_url_contains "${public_url%/}/health/get" '"codexAppServer":"connected"' 10; then
    return 0
  fi
  log "Public Agent Pulse health is not reachable from macmini3; using local Docker edge health for host-side proof."
  wait_for_url_contains "http://127.0.0.1:${edge_port}/health/get" '"codexAppServer":"connected"' 60
}

assert_project_manager_health() {
  local pm_health root_health local_root_health local_project_manager_health
  if pm_health="$(request_body "https://beta.dope-ai.kr/project-manager/health" 2>/dev/null)" &&
    printf '%s' "$pm_health" | grep -qi 'healthy' &&
    root_health="$(request_body "https://beta.dope-ai.kr/health" 2>/dev/null)" &&
    printf '%s' "$root_health" | grep -qi 'healthy'; then
    return 0
  fi

  log "Public beta health is not reachable from macmini3; checking local shared-edge health instead."
  local_project_manager_health="$(request_body "http://127.0.0.1:4344/health")"
  if ! printf '%s' "$local_project_manager_health" | grep -qi 'healthy'; then
    echo "Local Project Manager beta health failed; refusing to touch shared beta edge." >&2
    printf '%s\n' "$local_project_manager_health" >&2
    exit 1
  fi

  local_root_health="$(request_body "http://127.0.0.1/health")"
  if ! printf '%s' "$local_root_health" | grep -qi 'healthy'; then
    echo "Local shared beta root health failed; refusing to touch shared beta edge." >&2
    printf '%s\n' "$local_root_health" >&2
    exit 1
  fi
}

ensure_node_runtime() {
  require_command node
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

run_pnpm() {
  "${PNPM_COMMAND[@]}" "$@"
}

ensure_launch_agent() {
  local uid
  uid="$(id -u)"
  if ! launchctl print "gui/$uid" >/dev/null 2>&1; then
    echo "No GUI launchctl domain is available for Agent Pulse helper." >&2
    exit 1
  fi

  if lsof -tiTCP:"$helper_port" -sTCP:LISTEN >/dev/null 2>&1 &&
    ! launchctl print "gui/$uid/$launch_label" >/dev/null 2>&1; then
    echo "Port $helper_port is already in use by a non-Agent Pulse beta LaunchAgent process." >&2
    lsof -nP -iTCP:"$helper_port" -sTCP:LISTEN >&2 || true
    exit 1
  fi

  mkdir -p "$launch_agent_dir" "$log_dir"
  AGENT_PULSE_REPO_ROOT="$repo_root" \
  AGENT_PULSE_PUBLIC_URL="$public_url" \
  AGENT_PULSE_PUBLIC_BASE_PATH="$public_base_path" \
  AGENT_PULSE_HELPER_PORT="$helper_port" \
  AGENT_PULSE_LAUNCH_LABEL="$launch_label" \
  AGENT_PULSE_STDOUT_PATH="$stdout_path" \
  AGENT_PULSE_STDERR_PATH="$stderr_path" \
  python3 - "$plist_path" <<'PY'
import os
import plistlib
import shlex
import sys
from pathlib import Path

plist_path = Path(sys.argv[1])
repo_root = os.environ["AGENT_PULSE_REPO_ROOT"]
public_url = os.environ["AGENT_PULSE_PUBLIC_URL"]
public_base_path = os.environ["AGENT_PULSE_PUBLIC_BASE_PATH"]
helper_port = os.environ["AGENT_PULSE_HELPER_PORT"]
label = os.environ["AGENT_PULSE_LAUNCH_LABEL"]
stdout_path = os.environ["AGENT_PULSE_STDOUT_PATH"]
stderr_path = os.environ["AGENT_PULSE_STDERR_PATH"]

command = " ".join([
    "export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH;",
    "cd", shlex.quote(repo_root), "&&",
    "exec env",
    f"AGENT_PULSE_SKIP_BUILD=1",
    f"AGENT_PULSE_HELPER_PORT={shlex.quote(helper_port)}",
    f"AGENT_PULSE_PUBLIC_URL={shlex.quote(public_url)}",
    f"AGENT_PULSE_PUBLIC_BASE_PATH={shlex.quote(public_base_path)}",
    "AGENT_PULSE_DISABLE_CODEX_DESKTOP=1",
    "AGENT_PULSE_SKIP_MANAGED_TUNNEL=1",
    "bash", shlex.quote(str(Path(repo_root) / "scripts/macmini3/run-agentpulse-beta-helper.sh")),
])

payload = {
    "Label": label,
    "ProgramArguments": ["/bin/zsh", "-lc", command],
    "RunAtLoad": True,
    "KeepAlive": True,
    "WorkingDirectory": repo_root,
    "StandardOutPath": stdout_path,
    "StandardErrorPath": stderr_path,
}
plist_path.write_bytes(plistlib.dumps(payload, sort_keys=False))
PY

  if launchctl print "gui/$uid/$launch_label" >/dev/null 2>&1; then
    launchctl bootout "gui/$uid/$launch_label" >/dev/null 2>&1 || true
  fi
  launchctl bootstrap "gui/$uid" "$plist_path"
  launchctl kickstart -k "gui/$uid/$launch_label" >/dev/null 2>&1 || true
}

if [[ -n "$expected_sha" ]]; then
  actual_sha="$(git rev-parse HEAD)"
  if [[ "$actual_sha" != "$expected_sha" ]]; then
    echo "Checkout is not at expected Agent Pulse SHA." >&2
    echo "  expected: $expected_sha" >&2
    echo "  actual:   $actual_sha" >&2
    exit 1
  fi
fi

require_command git
require_command docker
require_command curl
require_command lsof
require_command launchctl

assert_project_manager_health

if pgrep -fl '/tmp/fake-bin/codex' >/dev/null 2>&1; then
  echo "Unexpected fake Codex process is running on macmini3." >&2
  exit 1
fi

ensure_node_runtime

log "Installing dependencies and building with base path $public_base_path"
run_pnpm install --frozen-lockfile
AGENT_PULSE_PUBLIC_BASE_PATH="$public_base_path" run_pnpm build

log "Writing isolated helper settings"
AGENT_PULSE_SKIP_BUILD=1 \
AGENT_PULSE_WRITE_SETTINGS_ONLY=1 \
AGENT_PULSE_HELPER_PORT="$helper_port" \
AGENT_PULSE_PUBLIC_URL="$public_url" \
AGENT_PULSE_PUBLIC_BASE_PATH="$public_base_path" \
bash scripts/macmini3/run-agentpulse-beta-helper.sh

log "Installing Codex-safe LaunchAgent $launch_label"
ensure_launch_agent
wait_for_url_contains "http://127.0.0.1:${helper_port}/health/get" '"codexAppServer":"connected"' 60

if ! pgrep -fl 'codex app-server' | grep -v '/tmp/fake-bin/codex' >/dev/null 2>&1; then
  echo "Real Codex app-server process was not found after helper start." >&2
  exit 1
fi

log "Starting Agent Pulse Docker edge on port $edge_port"
AGENT_PULSE_EDGE_PORT="$edge_port" AGENT_PULSE_EDGE_BIND="${AGENT_PULSE_EDGE_BIND:-127.0.0.1}" \
  docker compose -f docker-compose.macmini3.yml up -d --force-recreate
wait_for_url_contains "http://127.0.0.1:${edge_port}/health/get" '"codexAppServer":"connected"' 60

log "Reconciling shared beta edge route"
bash scripts/macmini3/reconcile-agentpulse-shared-edge.sh

wait_for_public_or_local_agentpulse
assert_project_manager_health

log "Agent Pulse beta is healthy at $public_url"
