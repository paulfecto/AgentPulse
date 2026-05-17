# Agent Pulse beta deployment on macmini3

Public route: `https://beta.dope-ai.kr/agent-pulse`

This deployment follows the `management-tool` shared beta pattern. The shared
macmini3 edge owns TLS for `beta.dope-ai.kr`, strips `/agent-pulse/`, and sends
traffic to the Agent Pulse Docker edge on `127.0.0.1:4355`. The Docker edge
serves the built tablet assets locally and reverse-proxies helper API traffic to
the active Mac relay helper on `127.0.0.1:55112`.

## Runtime shape

- Helper relay: macOS SSH relay on `55112`, because the real Codex app-server
  state lives on the Codex desktop Mac, not inside the shared public nginx
  container.
- Docker edge: nginx container named `agentpulse-beta-edge`.
- Docker edge static root: `apps/tablet/dist` mounted read-only at
  `/usr/share/nginx/html`.
- Public URL: `https://beta.dope-ai.kr/agent-pulse`.
- Desktop safety: the helper launcher always sets
  `AGENT_PULSE_DISABLE_CODEX_DESKTOP=1`.
- Tunnel safety: the helper launcher always sets
  `AGENT_PULSE_SKIP_MANAGED_TUNNEL=1`; Cloudflare is handled by the existing
  shared beta edge, not by Agent Pulse.

## macmini3 commands

The normal deploy path is the Agent Pulse-owned GitHub Actions workflow:

```text
Agent Pulse Beta -> Run workflow -> deploy = true
```

The workflow uses the same macmini3 secret model as the shared beta stack:

- `MACMINI3_HOST`
- `MACMINI3_USER`
- `MACMINI3_PORT`
- `MACMINI3_PASSWORD`

It checks out `paulfecto/AgentPulse` on macmini3 at the exact pushed `main`
SHA, builds with `/agent-pulse/`, starts only `agentpulse-beta-edge`, validates
the existing Mac helper relay on `127.0.0.1:55112`, disables any stale local
macmini3 Agent Pulse helper LaunchAgent, and reconciles only the marked Agent
Pulse block inside the active `beta.dope-ai.kr` shared nginx edge.

For direct host operation from the Agent Pulse checkout on macmini3:

```sh
scripts/macmini3/deploy-agentpulse-beta.sh "$(git rev-parse HEAD)"
```

The deploy script refuses to touch the shared edge unless
`https://beta.dope-ai.kr/project-manager/health` and
`https://beta.dope-ai.kr/health` are healthy first. It validates nginx with
`nginx -t` before reload and restores the previous shared-edge config if
validation fails.

`deploy/macmini3/beta-shared-edge-agentpulse.conf` is a reference snippet only.
Live deployment uses `scripts/macmini3/reconcile-agentpulse-shared-edge.sh`,
which inserts or updates the marked block:

```nginx
# Agent Pulse beta app proxy BEGIN
...
# Agent Pulse beta app proxy END
```

The reconciler preserves existing `/project-manager`, `/health`, `/api`, MCP,
and OAuth routes. It uses `http://127.0.0.1:4355/` for host nginx and
`http://host.docker.internal:4355/` when the shared edge runs inside Docker.

Validate:

```sh
scripts/macmini3/check-agentpulse-beta.sh
```

## Watch pairing

Pair the Watch with:

```text
https://beta.dope-ai.kr/agent-pulse
```

Do not use `127.0.0.1` or a LAN IP for the global Watch setup.

## APNs

APNs secrets stay outside git. If available, pass these environment variables
before starting the helper:

```sh
export AGENT_PULSE_APNS_TEAM_ID=H86Z687FT6
export AGENT_PULSE_APNS_KEY_ID=<key-id>
export AGENT_PULSE_APNS_KEY_PATH=<absolute-private-p8-path>
export AGENT_PULSE_APNS_BUNDLE_ID=com.paulfecto.AgentPulse.watchkitapp
export AGENT_PULSE_APNS_ENVIRONMENT=sandbox
```
