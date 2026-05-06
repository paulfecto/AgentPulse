#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
helper_script="$repo_root/apps/helper/dist/dev-server.js"
state_dir="${AGENT_PULSE_BETA_STATE_DIR:-$HOME/Library/Application Support/Agent Pulse Beta}"
settings_path="${AGENT_PULSE_SETTINGS_PATH:-$state_dir/settings.json}"
admin_credentials_path="${AGENT_PULSE_ADMIN_CREDENTIALS_PATH:-$state_dir/admin.json}"
keychain_service="${AGENT_PULSE_KEYCHAIN_SERVICE:-AgentPulseBeta}"
helper_port="${AGENT_PULSE_HELPER_PORT:-55110}"
public_url="${AGENT_PULSE_PUBLIC_URL:-https://beta.dope-ai.kr/agent-pulse}"
public_base_path="${AGENT_PULSE_PUBLIC_BASE_PATH:-/agent-pulse/}"
public_hostname="${AGENT_PULSE_REMOTE_HOSTNAME:-beta.dope-ai.kr}"

log() {
  echo "[agent-pulse-beta-helper] $*"
}

if ! command -v pnpm >/dev/null 2>&1; then
  echo "pnpm is required to build Agent Pulse before starting the helper." >&2
  exit 1
fi

case "$public_url" in
  https://*) ;;
  *)
    echo "AGENT_PULSE_PUBLIC_URL must be an https URL." >&2
    exit 1
    ;;
esac

mkdir -p "$state_dir"

AGENT_PULSE_PUBLIC_URL="$public_url" \
AGENT_PULSE_REMOTE_HOSTNAME="$public_hostname" \
node --input-type=module - "$settings_path" <<'NODE'
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';

const settingsPath = process.argv[2];
const port = Number(process.env.AGENT_PULSE_HELPER_PORT || '55110');
const publicUrl = process.env.AGENT_PULSE_PUBLIC_URL || 'https://beta.dope-ai.kr/agent-pulse';
const hostname = process.env.AGENT_PULSE_REMOTE_HOSTNAME || new URL(publicUrl).hostname;

let existing = {};
try {
  existing = JSON.parse(await readFile(settingsPath, 'utf8'));
} catch {
  existing = {};
}

const previousRemote = existing.remoteAccess && typeof existing.remoteAccess === 'object'
  ? existing.remoteAccess
  : {};
const previousWatch = existing.watchNotifications && typeof existing.watchNotifications === 'object'
  ? existing.watchNotifications
  : {};
const apnsComplete = Boolean(
  process.env.AGENT_PULSE_APNS_TEAM_ID &&
  process.env.AGENT_PULSE_APNS_KEY_ID &&
  process.env.AGENT_PULSE_APNS_KEY_PATH
);

const settings = {
  ...existing,
  port,
  lanEnabled: false,
  mobileSendEnabled: true,
  remoteAccess: {
    ...previousRemote,
    enabled: true,
    provider: 'cloudflare',
    mode: 'edge',
    tunnelProtocol: previousRemote.tunnelProtocol || 'auto',
    hostname,
    publicUrl: publicUrl.replace(/\/+$/, ''),
    tunnelName: previousRemote.tunnelName || 'agent-pulse',
    tunnelId: '',
    configPath: path.join(path.dirname(settingsPath), 'edge', 'config.yml'),
    metricsUrl: previousRemote.metricsUrl || 'http://127.0.0.1:60123/metrics',
    status: 'healthy',
    lastError: '',
    lastStartedAt: previousRemote.lastStartedAt ?? null,
    lastStoppedAt: previousRemote.lastStoppedAt ?? null,
    lastCheckedAt: new Date().toISOString(),
    checklist: {
      dependencyInstalled: true,
      authenticated: true,
      configured: true,
      tunnelRunning: true,
      hostnameAssigned: true
    }
  },
  watchNotifications: {
    ...previousWatch,
    enabled: apnsComplete ? true : previousWatch.enabled === true,
    teamId: process.env.AGENT_PULSE_APNS_TEAM_ID || previousWatch.teamId || '',
    keyId: process.env.AGENT_PULSE_APNS_KEY_ID || previousWatch.keyId || '',
    bundleId: process.env.AGENT_PULSE_APNS_BUNDLE_ID || previousWatch.bundleId || 'com.paulfecto.AgentPulse.watchkitapp',
    environment: process.env.AGENT_PULSE_APNS_ENVIRONMENT === 'production' ? 'production' : (previousWatch.environment || 'sandbox'),
    keyPath: process.env.AGENT_PULSE_APNS_KEY_PATH || previousWatch.keyPath || '',
    lastError: previousWatch.lastError || '',
    lastCheckedAt: previousWatch.lastCheckedAt ?? null
  }
};

await mkdir(path.dirname(settingsPath), { recursive: true });
await writeFile(settingsPath, `${JSON.stringify(settings, null, 2)}\n`, 'utf8');
NODE

if [[ "${AGENT_PULSE_WRITE_SETTINGS_ONLY:-0}" == "1" ]]; then
  log "Wrote beta helper settings at $settings_path"
  exit 0
fi

if [[ "${AGENT_PULSE_SKIP_BUILD:-0}" != "1" ]]; then
  log "Building with public base path $public_base_path"
  (cd "$repo_root" && AGENT_PULSE_PUBLIC_BASE_PATH="$public_base_path" pnpm build)
fi

if [[ ! -f "$helper_script" ]]; then
  echo "Missing helper build at $helper_script. Run pnpm build or unset AGENT_PULSE_SKIP_BUILD." >&2
  exit 1
fi

if lsof -tiTCP:"$helper_port" -sTCP:LISTEN >/dev/null 2>&1; then
  echo "Port $helper_port is already in use. Stop only the Agent Pulse helper using that port, then rerun this script." >&2
  exit 1
fi

log "Starting Codex-safe helper on 127.0.0.1:$helper_port for $public_url"
exec env \
  AGENT_PULSE_SETTINGS_PATH="$settings_path" \
  AGENT_PULSE_ADMIN_CREDENTIALS_PATH="$admin_credentials_path" \
  AGENT_PULSE_KEYCHAIN_SERVICE="$keychain_service" \
  AGENT_PULSE_DISABLE_CODEX_DESKTOP=1 \
  AGENT_PULSE_SKIP_MANAGED_TUNNEL=1 \
  node "$helper_script"
