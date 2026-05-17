#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=scripts/macmini3/lib-agentpulse-beta-probe.sh
source "$repo_root/scripts/macmini3/lib-agentpulse-beta-probe.sh"

public_url="${AGENT_PULSE_PUBLIC_URL:-https://beta.dope-ai.kr/agent-pulse}"
probe_url="${AGENT_PULSE_ROUTE_WATCHDOG_PROBE_URL:-$public_url}"
probe_resolve="${AGENT_PULSE_ROUTE_WATCHDOG_PROBE_RESOLVE:-}"
helper_url="${AGENT_PULSE_HELPER_URL:-http://127.0.0.1:55110}"
edge_url="${AGENT_PULSE_EDGE_URL:-http://127.0.0.1:4355}"
interval_seconds="${AGENT_PULSE_ROUTE_WATCHDOG_INTERVAL_SECONDS:-60}"
dry_run="${AGENT_PULSE_ROUTE_WATCHDOG_DRY_RUN:-0}"
once="${AGENT_PULSE_ROUTE_WATCHDOG_ONCE:-0}"

log() {
  echo "[agent-pulse-route-watchdog] $(date -u '+%Y-%m-%dT%H:%M:%SZ') $*"
}

request_body() {
  local url="$1"
  curl --connect-timeout 5 --max-time 20 -fsSL "$url"
}

assert_project_manager_health() {
  local pm_health root_health
  pm_health="$(request_body "https://beta.dope-ai.kr/project-manager/health")"
  if ! printf '%s' "$pm_health" | grep -qi 'healthy'; then
    echo "Project Manager health is not healthy." >&2
    printf '%s\n' "$pm_health" >&2
    return 1
  fi

  root_health="$(request_body "https://beta.dope-ai.kr/health")"
  if ! printf '%s' "$root_health" | grep -qi 'healthy'; then
    echo "Shared beta root health is not healthy." >&2
    printf '%s\n' "$root_health" >&2
    return 1
  fi
}

check_public_route() {
  AGENT_PULSE_PROBE_RESOLVE="$probe_resolve" agentpulse_check_health_url "$probe_url/health/get" 1 &&
    AGENT_PULSE_PROBE_RESOLVE="$probe_resolve" agentpulse_check_json_url "$probe_url/watch/summary" "200|401" 1 &&
    AGENT_PULSE_PROBE_RESOLVE="$probe_resolve" agentpulse_check_tablet_shell "$probe_url/" 1
}

repair_public_route() {
  log "Route drift detected: ${AGENT_PULSE_PROBE_ERROR:-unknown probe failure}"
  assert_project_manager_health
  agentpulse_require_health_url "$helper_url/health/get"
  agentpulse_require_health_url "$edge_url/health/get"

  if [[ "$dry_run" == "1" ]]; then
    log "Dry run enabled; not reconciling shared beta edge."
    return 1
  fi

  log "Reconciling marked Agent Pulse shared-edge block."
  bash "$repo_root/scripts/macmini3/reconcile-agentpulse-shared-edge.sh"

  AGENT_PULSE_PROBE_RESOLVE="$probe_resolve" agentpulse_require_health_url "$probe_url/health/get"
  AGENT_PULSE_PROBE_RESOLVE="$probe_resolve" agentpulse_require_json_url "$probe_url/watch/summary" "200|401"
  AGENT_PULSE_PROBE_RESOLVE="$probe_resolve" agentpulse_require_tablet_shell "$probe_url/"
  assert_project_manager_health
  log "Route repair verified."
}

run_once() {
  if check_public_route; then
    log "Route healthy at $probe_url"
    return 0
  fi
  repair_public_route
}

while true; do
  run_once
  if [[ "$once" == "1" ]]; then
    break
  fi
  sleep "$interval_seconds"
done
