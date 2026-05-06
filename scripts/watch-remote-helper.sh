#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
helper_script="$repo_root/apps/helper/dist/dev-server.js"
state_dir="${AGENT_PULSE_REMOTE_STATE_DIR:-$HOME/Library/Application Support/Agent Pulse Watch Remote}"
settings_path="${AGENT_PULSE_SETTINGS_PATH:-$state_dir/settings.json}"
admin_credentials_path="${AGENT_PULSE_ADMIN_CREDENTIALS_PATH:-$state_dir/admin.json}"
keychain_service="${AGENT_PULSE_KEYCHAIN_SERVICE:-com.agentpulse.watch-remote}"
helper_port="${AGENT_PULSE_HELPER_PORT:-55110}"
hostname="${AGENT_PULSE_REMOTE_HOSTNAME:-}"
tunnel_name="${AGENT_PULSE_REMOTE_TUNNEL_NAME:-agent-pulse-watch}"
tunnel_protocol="${AGENT_PULSE_REMOTE_TUNNEL_PROTOCOL:-auto}"
metrics_url="${AGENT_PULSE_TUNNEL_METRICS_URL:-http://127.0.0.1:60123/metrics}"
cloudflared_cert_path="${AGENT_PULSE_CLOUDFLARED_CERT_PATH:-$HOME/.cloudflared/cert.pem}"

log() {
  echo "[agent-pulse-watch-remote] $*"
}

if [[ -z "$hostname" ]]; then
  echo "Set AGENT_PULSE_REMOTE_HOSTNAME to the stable Cloudflare hostname, for example pulse.example.com." >&2
  exit 1
fi

if ! command -v cloudflared >/dev/null 2>&1; then
  echo "cloudflared is required for world-accessible Watch runtime. Install it and run cloudflared tunnel login." >&2
  exit 1
fi

if [[ ! -f "$cloudflared_cert_path" ]]; then
  echo "Cloudflare login is required before starting the named tunnel. Run: cloudflared tunnel login" >&2
  exit 1
fi

if ! command -v pnpm >/dev/null 2>&1; then
  echo "pnpm is required to build Agent Pulse before starting the helper." >&2
  exit 1
fi

mkdir -p "$state_dir"

tunnel_id="$(
  cloudflared tunnel list --name "$tunnel_name" --output json 2>/dev/null \
    | node --input-type=module -e "const chunks=[]; for await (const chunk of process.stdin) chunks.push(chunk); try { const value=JSON.parse(Buffer.concat(chunks).toString('utf8')); const first=Array.isArray(value) ? value[0] : undefined; process.stdout.write(first?.id || first?.ID || ''); } catch { process.exit(0); }"
)"

if [[ -z "$tunnel_id" ]]; then
  log "Creating Cloudflare tunnel $tunnel_name..."
  tunnel_output="$(cloudflared tunnel create "$tunnel_name" 2>&1)"
  tunnel_id="$(node --input-type=module -e "const value=process.argv[1] || ''; process.stdout.write(value.match(/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/i)?.[0] || '');" "$tunnel_output")"
fi

if [[ -z "$tunnel_id" ]]; then
  echo "Could not resolve Cloudflare tunnel id for $tunnel_name." >&2
  exit 1
fi

log "Routing $hostname to Cloudflare tunnel $tunnel_name..."
if ! cloudflared tunnel route dns "$tunnel_name" "$hostname"; then
  log "Cloudflare DNS route may already exist; continuing with local helper settings."
fi

AGENT_PULSE_REMOTE_TUNNEL_ID="$tunnel_id" node --input-type=module - "$settings_path" <<'NODE'
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';

const settingsPath = process.argv[2];
const stateDir = path.dirname(settingsPath);
const port = Number(process.env.AGENT_PULSE_HELPER_PORT || '55110');
const hostname = process.env.AGENT_PULSE_REMOTE_HOSTNAME || '';
const tunnelName = process.env.AGENT_PULSE_REMOTE_TUNNEL_NAME || 'agent-pulse-watch';
const tunnelId = process.env.AGENT_PULSE_REMOTE_TUNNEL_ID || '';
const tunnelProtocol = process.env.AGENT_PULSE_REMOTE_TUNNEL_PROTOCOL || 'auto';
const metricsUrl = process.env.AGENT_PULSE_TUNNEL_METRICS_URL || 'http://127.0.0.1:60123/metrics';

let existing = {};
try {
  existing = JSON.parse(await readFile(settingsPath, 'utf8'));
} catch {
  existing = {};
}

const previousRemote = existing.remoteAccess && typeof existing.remoteAccess === 'object' ? existing.remoteAccess : {};
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
  lanEnabled: true,
  mobileSendEnabled: true,
  remoteAccess: {
    ...previousRemote,
    enabled: true,
    provider: 'cloudflare',
    mode: 'named',
    tunnelProtocol: tunnelProtocol === 'quic' || tunnelProtocol === 'http2' ? tunnelProtocol : 'auto',
    hostname,
    publicUrl: `https://${hostname}`,
    tunnelName,
    tunnelId,
    configPath: path.join(stateDir, 'cloudflared', 'config.yml'),
    metricsUrl,
    status: previousRemote.status || 'off',
    lastError: '',
    lastStartedAt: previousRemote.lastStartedAt ?? null,
    lastStoppedAt: previousRemote.lastStoppedAt ?? null,
    lastCheckedAt: previousRemote.lastCheckedAt ?? null,
    checklist: {
      dependencyInstalled: true,
      authenticated: true,
      configured: true,
      tunnelRunning: false,
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

if [[ "${AGENT_PULSE_SKIP_BUILD:-0}" != "1" ]]; then
  log "Building helper and tablet bundles..."
  (cd "$repo_root" && pnpm build)
fi

if [[ ! -f "$helper_script" ]]; then
  echo "Missing helper build at $helper_script. Run pnpm build or unset AGENT_PULSE_SKIP_BUILD." >&2
  exit 1
fi

if lsof -tiTCP:"$helper_port" -sTCP:LISTEN >/dev/null 2>&1; then
  echo "Port $helper_port is already in use. Stop the Agent Pulse helper using that port, then rerun this script." >&2
  exit 1
fi

log "Starting Codex-safe helper on port $helper_port for https://$hostname"
exec env \
  AGENT_PULSE_SETTINGS_PATH="$settings_path" \
  AGENT_PULSE_ADMIN_CREDENTIALS_PATH="$admin_credentials_path" \
  AGENT_PULSE_KEYCHAIN_SERVICE="$keychain_service" \
  AGENT_PULSE_DISABLE_CODEX_DESKTOP=1 \
  AGENT_PULSE_SKIP_MANAGED_TUNNEL=0 \
  node "$helper_script"
