#!/usr/bin/env bash

set -euo pipefail

helper_url="${AGENT_PULSE_HELPER_URL:-http://127.0.0.1:55110}"
edge_url="${AGENT_PULSE_EDGE_URL:-http://127.0.0.1:4355}"
public_url="${AGENT_PULSE_PUBLIC_URL:-https://beta.dope-ai.kr/agent-pulse}"

require_agentpulse_health() {
  local url="$1"
  local body
  body="$(curl --connect-timeout 5 --max-time 20 -fsSL "$url")"
  if ! printf '%s' "$body" | grep -q '"codexAppServer"' ||
    ! printf '%s' "$body" | grep -q '"connected"'; then
    echo "Expected Agent Pulse health JSON with connected Codex app-server at $url" >&2
    printf '%s\n' "$body" | sed -n '1,20p' >&2
    exit 1
  fi
}

require_agentpulse_health "$helper_url/health/get"
require_agentpulse_health "$edge_url/health/get"
require_agentpulse_health "$public_url/health/get"

project_manager_health="$(curl --connect-timeout 5 --max-time 20 -fsSL "https://beta.dope-ai.kr/project-manager/health")"
if ! printf '%s' "$project_manager_health" | grep -qi 'healthy'; then
  echo "Project Manager health is not healthy." >&2
  printf '%s\n' "$project_manager_health" >&2
  exit 1
fi

if pgrep -fl '/tmp/fake-bin/codex' >/dev/null 2>&1; then
  echo "Unexpected fake Codex process is running." >&2
  exit 1
fi

if ! curl --connect-timeout 5 --max-time 20 -fsSL "$edge_url/" >/dev/null; then
  echo "Agent Pulse tablet shell is not loading through the Docker edge." >&2
  exit 1
fi

echo "Agent Pulse beta route is healthy at $public_url"
