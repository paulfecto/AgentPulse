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

require_env MACMINI3_HOST
require_env MACMINI3_USER
require_env MACMINI3_PORT
require_env MACMINI3_PASSWORD

ensure_sshpass
export SSHPASS="${MACMINI3_PASSWORD}"

SSH_OPTS=(
  -o StrictHostKeyChecking=no
  -o ServerAliveInterval=30
  -o ServerAliveCountMax=20
)

sshpass -e ssh "${SSH_OPTS[@]}" -p "${MACMINI3_PORT}" "${MACMINI3_USER}@${MACMINI3_HOST}" <<'REMOTE'
set -euo pipefail
export PATH="/Applications/Docker.app/Contents/Resources/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

state_dir="${AGENT_PULSE_BETA_STATE_DIR:-$HOME/Library/Application Support/Agent Pulse Beta}"
admin_json="$state_dir/admin.json"
admin_passcode_file="$state_dir/admin-passcode.txt"
helper_url="${AGENT_PULSE_HELPER_URL:-http://127.0.0.1:55110}"
public_url="${AGENT_PULSE_PUBLIC_URL:-https://beta.dope-ai.kr/agent-pulse}"
launch_label="${AGENT_PULSE_LAUNCH_LABEL:-com.agentpulse.helper.55110.beta-edge}"

log() {
  echo "[agent-pulse-beta-pairing] $*"
}

write_managed_admin_passcode() {
  mkdir -p "$state_dir"
  node --input-type=module - "$admin_json" "$admin_passcode_file" <<'NODE'
import { randomBytes, scryptSync } from 'node:crypto';
import { mkdir, writeFile, chmod } from 'node:fs/promises';
import path from 'node:path';

const adminJson = process.argv[2];
const passcodeFile = process.argv[3];
const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const bytes = randomBytes(18);
let passcode = '';
for (const byte of bytes) {
  passcode += alphabet[byte % alphabet.length];
}
const salt = randomBytes(16).toString('hex');
const passcodeHash = scryptSync(passcode, salt, 32).toString('hex');

await mkdir(path.dirname(adminJson), { recursive: true });
await writeFile(adminJson, `${JSON.stringify({ salt, passcodeHash }, null, 2)}\n`, 'utf8');
await writeFile(passcodeFile, `${passcode}\n`, 'utf8');
await chmod(adminJson, 0o600);
await chmod(passcodeFile, 0o600);
NODE
}

restart_helper() {
  local uid
  uid="$(id -u)"
  if ! launchctl print "gui/$uid/$launch_label" >/dev/null 2>&1; then
    echo "Agent Pulse beta LaunchAgent is not loaded: $launch_label" >&2
    exit 1
  fi
  launchctl kickstart -k "gui/$uid/$launch_label" >/dev/null
}

wait_for_helper() {
  local body
  for _ in $(seq 1 60); do
    if body="$(curl --connect-timeout 3 --max-time 10 -fsSL "$helper_url/health/get" 2>/dev/null)" &&
      printf '%s' "$body" | grep -q '"codexAppServer":"connected"'; then
      return 0
    fi
    sleep 2
  done
  echo "Timed out waiting for Agent Pulse helper health at $helper_url/health/get" >&2
  exit 1
}

create_pin_with_current_passcode() {
  if [[ ! -f "$admin_passcode_file" ]]; then
    return 1
  fi

  local passcode login_payload login_json token pin_json
  passcode="$(tr -d '\r\n' < "$admin_passcode_file")"
  if [[ ${#passcode} -lt 12 ]]; then
    return 1
  fi

  login_payload="$(PASSCODE="$passcode" python3 - <<'PY'
import json
import os
print(json.dumps({"passcode": os.environ["PASSCODE"]}))
PY
)"
  if ! login_json="$(curl --connect-timeout 3 --max-time 10 -fsSL \
    -H 'Content-Type: application/json' \
    -X POST "$helper_url/admin/login" \
    --data "$login_payload" 2>/dev/null)"; then
    return 1
  fi

  token="$(LOGIN_JSON="$login_json" python3 - <<'PY'
import json
import os
print(json.loads(os.environ["LOGIN_JSON"])["token"])
PY
)"
  pin_json="$(curl --connect-timeout 3 --max-time 10 -fsSL \
    -H "Authorization: Bearer $token" \
    -H 'Content-Type: application/json' \
    -X POST "$helper_url/settings/pairing-pin" \
    --data '{"deviceName":"Apple Watch"}')"

  PIN_JSON="$pin_json" PUBLIC_URL="$public_url" python3 - <<'PY'
import json
import os

payload = json.loads(os.environ["PIN_JSON"])
print(f"PAIRING_URL={os.environ['PUBLIC_URL'].rstrip('/')}")
print(f"PAIRING_PIN={payload['pin']}")
print(f"PAIRING_EXPIRES_AT={payload['expiresAt']}")
PY
}

wait_for_helper
if create_pin_with_current_passcode; then
  exit 0
fi

log "Current isolated beta admin passcode is unavailable or invalid; rotating beta admin credentials only."
write_managed_admin_passcode
restart_helper
wait_for_helper
create_pin_with_current_passcode
REMOTE
