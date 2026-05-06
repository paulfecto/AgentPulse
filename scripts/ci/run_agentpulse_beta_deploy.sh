#!/usr/bin/env bash

set -euo pipefail

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required environment variable: $name" >&2
    exit 1
  fi
}

ensure_sshpass() {
  if command -v sshpass >/dev/null 2>&1; then
    return 0
  fi

  sudo apt-get update
  sudo apt-get install -y sshpass
}

request_body() {
  local url="$1"
  curl --connect-timeout 5 --max-time 20 -fsSL "$url"
}

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

require_env MACMINI3_HOST
require_env MACMINI3_USER
require_env MACMINI3_PORT
require_env MACMINI3_PASSWORD

if [[ "${GITHUB_REF:-refs/heads/main}" != "refs/heads/main" && "${AGENT_PULSE_ALLOW_NON_MAIN_DEPLOY:-0}" != "1" ]]; then
  echo "Agent Pulse beta deploy is main-only. Current ref: ${GITHUB_REF:-unknown}" >&2
  exit 1
fi

CURRENT_HEAD_SHA="$(git rev-parse HEAD)"
PUBLIC_URL="${AGENT_PULSE_PUBLIC_URL:-https://beta.dope-ai.kr/agent-pulse}"
PUBLIC_BASE_PATH="${AGENT_PULSE_PUBLIC_BASE_PATH:-/agent-pulse/}"
REMOTE_REPO_DIR="${AGENT_PULSE_MACMINI_REPO_DIR:-/Users/paulfecto/AgentPulse}"
WORKFLOW_RUN_ID="${GITHUB_RUN_ID:-0}"
WORKFLOW_URL="${GITHUB_SERVER_URL:-https://github.com}/${GITHUB_REPOSITORY:-paulfecto/AgentPulse}/actions/runs/${WORKFLOW_RUN_ID}"

ensure_sshpass
export SSHPASS="${MACMINI3_PASSWORD}"
SSH_OPTS=(
  -o StrictHostKeyChecking=no
  -o ServerAliveInterval=30
  -o ServerAliveCountMax=20
)

sshpass -e ssh "${SSH_OPTS[@]}" -p "${MACMINI3_PORT}" "${MACMINI3_USER}@${MACMINI3_HOST}" <<REMOTE
set -euo pipefail
export PATH="/Applications/Docker.app/Contents/Resources/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:\$PATH"

repo_dir="${REMOTE_REPO_DIR}"
if [ ! -d "\$repo_dir/.git" ] && [ ! -f "\$repo_dir/.git" ]; then
  mkdir -p "\$(dirname "\$repo_dir")"
  git clone https://github.com/paulfecto/AgentPulse.git "\$repo_dir"
fi

cd "\$repo_dir"
git fetch origin main
git checkout main
git reset --hard ${CURRENT_HEAD_SHA}

AGENT_PULSE_PUBLIC_URL="${PUBLIC_URL}" \
AGENT_PULSE_PUBLIC_BASE_PATH="${PUBLIC_BASE_PATH}" \
AGENT_PULSE_EXPECTED_SHA="${CURRENT_HEAD_SHA}" \
bash scripts/macmini3/deploy-agentpulse-beta.sh "${CURRENT_HEAD_SHA}"
REMOTE

for attempt in $(seq 1 60); do
  if agentpulse_body="$(request_body "${PUBLIC_URL%/}/health/get" 2>/dev/null)" &&
    printf '%s' "$agentpulse_body" | grep -q '"codexAppServer"' &&
    printf '%s' "$agentpulse_body" | grep -q '"connected"'; then
    break
  fi

  if [[ "$attempt" == "60" ]]; then
    echo "Agent Pulse public health did not converge at ${PUBLIC_URL%/}/health/get" >&2
    printf '%s\n' "${agentpulse_body:-}" | sed -n '1,20p' >&2 || true
    exit 1
  fi
  sleep 2
done

project_manager_health="$(request_body "https://beta.dope-ai.kr/project-manager/health")"
if ! printf '%s' "$project_manager_health" | grep -qi 'healthy'; then
  echo "Project Manager health failed after Agent Pulse route update." >&2
  printf '%s\n' "$project_manager_health" >&2
  exit 1
fi

root_health="$(request_body "https://beta.dope-ai.kr/health")"
if ! printf '%s' "$root_health" | grep -qi 'healthy'; then
  echo "Shared beta root health failed after Agent Pulse route update." >&2
  printf '%s\n' "$root_health" >&2
  exit 1
fi

echo "Agent Pulse beta deploy succeeded."
echo "  sha: ${CURRENT_HEAD_SHA}"
echo "  url: ${PUBLIC_URL}"
echo "  workflow: ${WORKFLOW_URL}"
