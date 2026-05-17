#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=scripts/macmini3/lib-agentpulse-beta-probe.sh
source "$repo_root/scripts/macmini3/lib-agentpulse-beta-probe.sh"

helper_url="${AGENT_PULSE_HELPER_URL:-http://127.0.0.1:55110}"
edge_url="${AGENT_PULSE_EDGE_URL:-http://127.0.0.1:4355}"
public_url="${AGENT_PULSE_PUBLIC_URL:-https://beta.dope-ai.kr/agent-pulse}"

agentpulse_require_health_url "$helper_url/health/get"
agentpulse_require_health_url "$edge_url/health/get"
agentpulse_require_health_url "$public_url/health/get"
agentpulse_require_json_url "$public_url/watch/summary" "200|401"
agentpulse_require_tablet_shell "$public_url/"

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

agentpulse_require_tablet_shell "$edge_url/"

echo "Agent Pulse beta route is healthy at $public_url"
