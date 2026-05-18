#!/usr/bin/env bash

set -euo pipefail

label="${AGENT_PULSE_TUNNEL_LABEL:-kr.dopeai.agentpulse.macstudio-beta-tunnel}"
remote_host="${AGENT_PULSE_TUNNEL_HOST:-macmini-3}"
remote_bind="${AGENT_PULSE_TUNNEL_REMOTE_BIND:-127.0.0.1}"
remote_port="${AGENT_PULSE_TUNNEL_REMOTE_PORT:-55112}"
local_bind="${AGENT_PULSE_TUNNEL_LOCAL_BIND:-127.0.0.1}"
local_port="${AGENT_PULSE_TUNNEL_LOCAL_PORT:-55110}"
launch_agent_dir="$HOME/Library/LaunchAgents"
log_dir="$HOME/Library/Logs"
plist_path="$launch_agent_dir/$label.plist"
stdout_path="$log_dir/$label.log"
stderr_path="$log_dir/$label.error.log"

if ! command -v ssh >/dev/null 2>&1; then
  echo "ssh is required to install the Agent Pulse reverse tunnel." >&2
  exit 127
fi

if ! launchctl print "gui/$(id -u)" >/dev/null 2>&1; then
  echo "No GUI launchctl domain is available for Agent Pulse tunnel." >&2
  exit 1
fi

mkdir -p "$launch_agent_dir" "$log_dir"

AGENT_PULSE_TUNNEL_LABEL="$label" \
AGENT_PULSE_TUNNEL_HOST="$remote_host" \
AGENT_PULSE_TUNNEL_REMOTE_BIND="$remote_bind" \
AGENT_PULSE_TUNNEL_REMOTE_PORT="$remote_port" \
AGENT_PULSE_TUNNEL_LOCAL_BIND="$local_bind" \
AGENT_PULSE_TUNNEL_LOCAL_PORT="$local_port" \
AGENT_PULSE_TUNNEL_STDOUT_PATH="$stdout_path" \
AGENT_PULSE_TUNNEL_STDERR_PATH="$stderr_path" \
python3 - "$plist_path" <<'PY'
import os
import plistlib
import sys

plist_path = sys.argv[1]
label = os.environ["AGENT_PULSE_TUNNEL_LABEL"]
remote_host = os.environ["AGENT_PULSE_TUNNEL_HOST"]
remote_bind = os.environ["AGENT_PULSE_TUNNEL_REMOTE_BIND"]
remote_port = os.environ["AGENT_PULSE_TUNNEL_REMOTE_PORT"]
local_bind = os.environ["AGENT_PULSE_TUNNEL_LOCAL_BIND"]
local_port = os.environ["AGENT_PULSE_TUNNEL_LOCAL_PORT"]
stdout_path = os.environ["AGENT_PULSE_TUNNEL_STDOUT_PATH"]
stderr_path = os.environ["AGENT_PULSE_TUNNEL_STDERR_PATH"]

payload = {
    "Label": label,
    "ProgramArguments": [
        "/usr/bin/ssh",
        "-N",
        "-o",
        "ExitOnForwardFailure=yes",
        "-o",
        "ServerAliveInterval=30",
        "-o",
        "ServerAliveCountMax=3",
        "-R",
        f"{remote_bind}:{remote_port}:{local_bind}:{local_port}",
        remote_host,
    ],
    "RunAtLoad": True,
    "KeepAlive": {
        "NetworkState": True,
        "SuccessfulExit": False,
    },
    "StandardOutPath": stdout_path,
    "StandardErrorPath": stderr_path,
}

with open(plist_path, "wb") as plist:
    plistlib.dump(payload, plist, sort_keys=False)
PY

uid="$(id -u)"
launchctl bootout "gui/$uid/$label" >/dev/null 2>&1 || true
launchctl bootout "gui/$uid" "$plist_path" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$uid" "$plist_path"
launchctl kickstart -k "gui/$uid/$label" >/dev/null 2>&1 || true

for _ in $(seq 1 20); do
  if launchctl print "gui/$uid/$label" >/dev/null 2>&1; then
    echo "Installed Agent Pulse reverse tunnel $label -> $remote_host:$remote_port."
    exit 0
  fi
  sleep 0.5
done

echo "Agent Pulse reverse tunnel LaunchAgent did not register." >&2
exit 1
