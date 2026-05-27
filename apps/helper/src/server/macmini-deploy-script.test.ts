import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { describe, expect, it } from 'vitest';

const repoRoot = path.resolve(import.meta.dirname, '../../../..');

async function readRepoFile(relativePath: string): Promise<string> {
  return readFile(path.join(repoRoot, relativePath), 'utf8');
}

describe('macmini3 Agent Pulse beta deploy automation', () => {
  it('uses the macmini3 secret model and deploys main through the AgentPulse workflow', async () => {
    const workflow = await readRepoFile('.github/workflows/agentpulse-beta.yml');
    const runner = await readRepoFile('scripts/ci/run_agentpulse_beta_deploy.sh');

    for (const secretName of ['MACMINI3_HOST', 'MACMINI3_USER', 'MACMINI3_PORT', 'MACMINI3_PASSWORD']) {
      expect(workflow).toContain(`secrets.${secretName}`);
      expect(runner).toContain(`require_env ${secretName}`);
    }

    expect(workflow).toContain("github.ref == 'refs/heads/main'");
    expect(workflow).toContain('bash scripts/ci/run_agentpulse_beta_deploy.sh');
    expect(runner).toContain('git reset --hard ${CURRENT_HEAD_SHA}');
    expect(runner).toContain('bash scripts/macmini3/deploy-agentpulse-beta.sh "${CURRENT_HEAD_SHA}"');
    expect(runner).toContain('https://beta.dope-ai.kr/project-manager/health');
    expect(runner).toContain('https://beta.dope-ai.kr/health');
  });

  it('uses the Mac helper relay instead of starting a second macmini3 helper', async () => {
    const deploy = await readRepoFile('scripts/macmini3/deploy-agentpulse-beta.sh');
    const edge = await readRepoFile('deploy/macmini3/agentpulse-nginx.conf');

    expect(deploy).toContain('AGENT_PULSE_RELAY_HELPER_PORT');
    expect(deploy).toContain('Disabling stale macmini3 local helper LaunchAgent');
    expect(deploy).toContain('com.agentpulse.helper.55110.beta-edge');
    expect(deploy).toContain('launchctl bootout "gui/$uid/$launch_label"');
    expect(deploy).toContain('Validating Mac helper relay on 127.0.0.1:$helper_port');
    expect(deploy).toContain('npm exec --yes pnpm@10.28.2 --');
    expect(deploy).toContain('run_pnpm install --frozen-lockfile');
    expect(edge).toContain('host.docker.internal:55112');
    expect(deploy).not.toContain('Installing Codex-safe LaunchAgent $launch_label');
    expect(deploy).not.toContain("pgrep -fl 'codex app-server'");
  });

  it('reconciles only a marked /agent-pulse shared-edge block and supports host or container upstreams', async () => {
    const reconciler = await readRepoFile('scripts/macmini3/reconcile-agentpulse-shared-edge.sh');

    expect(reconciler).toContain('# Agent Pulse beta app proxy BEGIN');
    expect(reconciler).toContain('# Agent Pulse beta app proxy END');
    expect(reconciler).toContain('location = {base_path}');
    expect(reconciler).toContain('location ^~ {base_path}/');
    expect(reconciler).toContain('proxy_intercept_errors on');
    expect(reconciler).toContain('@agentpulse_beta_json_error');
    expect(reconciler).toContain('agent_pulse_upstream_unavailable');
    expect(reconciler).toContain('http://127.0.0.1:${AGENT_PULSE_EDGE_PORT}');
    expect(reconciler).toContain('http://host.docker.internal:${AGENT_PULSE_EDGE_PORT}');
    expect(reconciler).toContain('Refusing to overwrite an unmarked /agent-pulse nginx location in the target server block.');
    expect(reconciler).toContain('docker exec "$container_name" nginx -t');
    expect(reconciler).toContain('nginx -t');
    expect(reconciler).not.toContain('docker restart internal-management');
    expect(reconciler).not.toContain('cd /Users/paulfecto/management-tool');
  });

  it('documents the non-destructive Project Manager preservation contract', async () => {
    const docs = await readRepoFile('docs/deploy/macmini3-agent-pulse-beta.md');
    const deploy = await readRepoFile('scripts/macmini3/deploy-agentpulse-beta.sh');
    const watchdog = await readRepoFile('scripts/macmini3/watch-agentpulse-beta-route.sh');
    const helper = await readRepoFile('scripts/macmini3/install-local-beta-helper.sh');
    const tunnel = await readRepoFile('scripts/macmini3/install-local-reverse-tunnel.sh');

    expect(docs).toContain('scripts/macmini3/install-local-beta-helper.sh');
    expect(docs).toContain('preserves existing `/project-manager`, `/health`, `/api`, MCP');
    expect(docs).toContain('restores the previous shared-edge config if');
    expect(docs).toContain('validation fails');
    expect(deploy).toContain('refusing to touch shared beta edge');
    expect(deploy).toContain('assert_project_manager_health');
    expect(deploy).toContain('http://127.0.0.1:4344/health');
    expect(deploy).toContain('Public beta health is not reachable from macmini3');
    expect(deploy).toContain('wait_for_public_or_local_shared_agentpulse');
    expect(deploy).toContain('AGENT_PULSE_LOCAL_SHARED_RESOLVE');
    expect(deploy).toContain('AGENT_PULSE_ROUTE_WATCHDOG_PROBE_RESOLVE');
    expect(deploy).toContain('Public Agent Pulse health is not reachable from macmini3');
    expect(deploy).toContain('bash scripts/macmini3/reconcile-agentpulse-shared-edge.sh');
    expect(watchdog).toContain('health_resolve="${AGENT_PULSE_ROUTE_WATCHDOG_HEALTH_RESOLVE:-$probe_resolve}"');
    expect(watchdog).toContain('curl_args+=(--resolve "$health_resolve")');
    expect(watchdog).toContain('Helper relay is not healthy before repair');
    expect(watchdog).toContain('Agent Pulse edge is not healthy before repair');
    expect(helper).toContain('com.agentpulse.helper.55110.beta-edge');
    expect(helper).toContain('Staging LaunchAgent-readable runtime');
    expect(helper).toContain('apps/helper/dist');
    expect(helper).toContain('apps/tablet/dist');
    expect(helper).toContain('npm install --omit=dev --no-audit --no-fund --package-lock=false');
    expect(helper).toContain('has_device_index_for_service "AgentPulseBeta"');
    expect(helper).toContain('has_device_index_for_service "com.agentpulse.helper"');
    expect(helper).toContain('AGENT_PULSE_KEYCHAIN_SERVICE=');
    expect(helper).toContain('AGENT_PULSE_DISABLE_CODEX_DESKTOP=1');
    expect(helper).toContain('AGENT_PULSE_SKIP_MANAGED_TUNNEL=1');
    expect(helper).toContain('AGENT_PULSE_SKIP_BUILD=1');
    expect(helper).toContain('scripts/macmini3/run-agentpulse-beta-helper.sh');
    expect(helper).toContain('payload.get("codexAppServer") != "connected"');
    expect(helper).toContain('"KeepAlive": True');
    expect(tunnel).toContain('remote_host="${AGENT_PULSE_TUNNEL_HOST:-macmini-3}"');
    expect(tunnel).toContain('remote_port="${AGENT_PULSE_TUNNEL_REMOTE_PORT:-55112}"');
    expect(tunnel).toContain('local_port="${AGENT_PULSE_TUNNEL_LOCAL_PORT:-55110}"');
  });
});
