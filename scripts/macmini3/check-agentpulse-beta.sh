#!/usr/bin/env bash

set -euo pipefail

helper_url="${AGENT_PULSE_HELPER_URL:-http://127.0.0.1:55112}"
edge_url="${AGENT_PULSE_EDGE_URL:-http://127.0.0.1:4355}"
public_url="${AGENT_PULSE_PUBLIC_URL:-https://beta.dope-ai.kr/agent-pulse}"

curl -fsS "$helper_url/health/get" >/dev/null
curl -fsS "$edge_url/health/get" >/dev/null
curl -fsS "$public_url/health/get" >/dev/null

if pgrep -fl '/tmp/fake-bin/codex' >/dev/null 2>&1; then
  echo "Unexpected fake Codex process is running." >&2
  exit 1
fi

if ! pgrep -fl '/Applications/Codex.app/Contents/Resources/codex app-server' >/dev/null 2>&1; then
  echo "Real Codex app-server process was not found." >&2
  exit 1
fi

echo "Agent Pulse beta route is healthy at $public_url"
