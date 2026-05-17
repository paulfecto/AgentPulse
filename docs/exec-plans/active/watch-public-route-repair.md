# Execution plan

Repair and prove the Agent Pulse public Watch route at
`https://beta.dope-ai.kr/agent-pulse`.

- status: in-progress
- owner: codex
- started: 2026-05-17

## Target behavior

- Public `/agent-pulse` traffic reaches Agent Pulse, not Project Manager.
- API endpoints never return HTML with HTTP 200 to the Watch.
- macmini3 keeps a route watchdog that repairs only the marked Agent Pulse
  nginx block after safe health checks and `nginx -t`.
- Codex Desktop remains untouched; the beta helper keeps desktop control
  disabled and uses the real Codex app-server path.

## Planned write set

- `scripts/macmini3/lib-agentpulse-beta-probe.sh`
- `scripts/macmini3/check-agentpulse-beta.sh`
- `scripts/macmini3/deploy-agentpulse-beta.sh`
- `scripts/macmini3/watch-agentpulse-beta-route.sh`
- `scripts/ci/run_agentpulse_beta_deploy.sh`
- `apps/watchos/AgentPulseWatch/AgentPulseWatch/AgentPulseClient.swift`
- `docs/exec-plans/active/watch-public-route-repair.md`

## Acceptance criteria

- Public health returns Agent Pulse JSON with `codexAppServer: "connected"`.
- Public watch summary returns JSON, including expected auth JSON when
  unauthenticated, never Project Manager HTML.
- Public tablet shell title/assets are Agent Pulse under `/agent-pulse/`.
- Project Manager `/health` and `/project-manager/health` remain healthy.
- Watch client reports an explicit wrong-route/server-format error if a
  reverse proxy returns HTML.

## Validation evidence

- pending

## Completion status

- state: in-progress
