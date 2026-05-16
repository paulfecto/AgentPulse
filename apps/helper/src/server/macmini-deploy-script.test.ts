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

  it('installs only a Codex-safe Agent Pulse helper LaunchAgent on 55110', async () => {
    const deploy = await readRepoFile('scripts/macmini3/deploy-agentpulse-beta.sh');
    const helper = await readRepoFile('scripts/macmini3/run-agentpulse-beta-helper.sh');

    expect(deploy).toContain('com.agentpulse.helper.55110.beta-edge');
    expect(deploy).toContain('AGENT_PULSE_DISABLE_CODEX_DESKTOP=1');
    expect(deploy).toContain('AGENT_PULSE_SKIP_MANAGED_TUNNEL=1');
    expect(deploy).toContain('launchctl bootout "gui/$uid/$launch_label"');
    expect(deploy).toContain('launchctl bootout "gui/$uid" "$plist_path"');
    expect(deploy).toContain('LaunchAgent $launch_label is still registered after bootout.');
    expect(deploy).toContain('Port $helper_port is already in use by a non-Agent Pulse beta LaunchAgent process.');
    expect(deploy).toContain('npm exec --yes pnpm@10.28.2 --');
    expect(deploy).toContain('run_pnpm install --frozen-lockfile');
    expect(deploy).toContain("pgrep -fl 'codex app-server'");
    expect(deploy).toContain("grep -v '/tmp/fake-bin/codex'");
    expect(helper).toContain('AGENT_PULSE_WRITE_SETTINGS_ONLY');
    expect(helper).toContain('mode: \'edge\'');
    expect(helper).toContain('mobileSendEnabled: true');
    expect(helper).toContain('prepend_codex_cli_path');
    expect(helper).toContain("find \"$nvm_root/versions/node\" -path '*/bin/codex' \\( -type f -o -type l \\)");
  });

  it('reconciles only a marked /agent-pulse shared-edge block and supports host or container upstreams', async () => {
    const reconciler = await readRepoFile('scripts/macmini3/reconcile-agentpulse-shared-edge.sh');

    expect(reconciler).toContain('# Agent Pulse beta app proxy BEGIN');
    expect(reconciler).toContain('# Agent Pulse beta app proxy END');
    expect(reconciler).toContain('location = {base_path}');
    expect(reconciler).toContain('location ^~ {base_path}/');
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

    expect(docs).toContain('preserves existing `/project-manager`, `/health`, `/api`, MCP');
    expect(docs).toContain('restores the previous shared-edge config if');
    expect(docs).toContain('validation fails');
    expect(deploy).toContain('refusing to touch shared beta edge');
    expect(deploy).toContain('assert_project_manager_health');
    expect(deploy).toContain('http://127.0.0.1:4344/health');
    expect(deploy).toContain('Public beta health is not reachable from macmini3');
    expect(deploy).toContain('wait_for_public_or_local_agentpulse');
    expect(deploy).toContain('Public Agent Pulse health is not reachable from macmini3');
    expect(deploy).toContain('bash scripts/macmini3/reconcile-agentpulse-shared-edge.sh');
  });
});
