# Agent Pulse beta deployment on macmini3

Public route: `https://beta.dope-ai.kr/agent-pulse`

This deployment follows the `management-tool` shared beta pattern. The shared
macmini3 edge owns TLS for `beta.dope-ai.kr`, strips `/agent-pulse/`, and sends
traffic to the Agent Pulse Docker edge on `127.0.0.1:4355`. The Docker edge
reverse-proxies to the macOS host helper on `127.0.0.1:55110`.

## Runtime shape

- Host helper: macOS process, because Codex app-server is bundled inside
  `/Applications/Codex.app`.
- Docker edge: nginx container named `agentpulse-beta-edge`.
- Public URL: `https://beta.dope-ai.kr/agent-pulse`.
- Desktop safety: the helper launcher always sets
  `AGENT_PULSE_DISABLE_CODEX_DESKTOP=1`.
- Tunnel safety: the helper launcher always sets
  `AGENT_PULSE_SKIP_MANAGED_TUNNEL=1`; Cloudflare is handled by the existing
  shared beta edge, not by Agent Pulse.

## macmini3 commands

From the Agent Pulse checkout on macmini3:

```sh
AGENT_PULSE_PUBLIC_BASE_PATH=/agent-pulse/ pnpm build
docker compose -f docker-compose.macmini3.yml up -d
scripts/macmini3/run-agentpulse-beta-helper.sh
```

Install the shared-edge route by including
`deploy/macmini3/beta-shared-edge-agentpulse.conf` in the existing
`beta.dope-ai.kr` nginx server block, then reload that shared edge.

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
