# Watch TestFlight Public Route Drift Repair

## Objective

Stop `https://beta.dope-ai.kr/agent-pulse` from returning Project Manager HTML to the TestFlight Watch app. The public API must return Agent Pulse JSON or a truthful Agent Pulse error, never a web page from another app.

## Current Failure

- Local public DNS currently resolves `beta.dope-ai.kr` to `220.124.236.147`; port 443 is refusing connections from this Mac.
- macmini3 local shared-edge probe with `--resolve beta.dope-ai.kr:443:127.0.0.1` returns Project Manager HTML for `/agent-pulse/health/get`.
- Agent Pulse Docker edge on macmini3 returns `502` because its upstream helper relay at `127.0.0.1:55112` is not listening.
- Local Mac helper is healthy on `55110`, but the reverse tunnel LaunchAgent currently forwards `55112` to `rpi5-jumphost`, not `macmini-3`, so macmini3 cannot reach it.
- macmini3 route watchdog detects route drift but cannot repair because `assert_project_manager_health` uses public beta URLs without the configured local `--resolve` fallback.

## Write Set

- `scripts/macmini3/watch-agentpulse-beta-route.sh`
- `scripts/macmini3/install-local-reverse-tunnel.sh`
- `docs/exec-plans/active/watch-testflight-public-route-drift.md`
- related narrow tests if existing route script tests cover this seam

## Acceptance Criteria

- macmini3 watchdog can verify Project Manager health through local shared-edge TLS resolve when public hairpin/DNS is unavailable.
- macmini3 watchdog repairs the marked `/agent-pulse` block after detecting Project Manager HTML.
- local Mac reverse tunnel points to `macmini-3` and makes macmini3 `127.0.0.1:55112` reach local helper `127.0.0.1:55110`.
- macmini3 `http://127.0.0.1:4355/health/get` returns Agent Pulse JSON with `codexAppServer: connected`.
- macmini3 local shared-edge probe for `/agent-pulse/health/get` returns Agent Pulse JSON, not Project Manager HTML.
- TestFlight-facing public API route is tested from this Mac when network allows; if DNS/port 443 still points/refuses externally, record that as an external DNS/network blocker separately from local shared-edge correctness.
- Docker validation passes for changed scripts/tests.

## Evidence Log

- Reproduced public route failure from this Mac:
  `curl https://beta.dope-ai.kr/agent-pulse/health/get` failed to connect to
  current DNS target `220.124.236.147:443`.
- Reproduced macmini3 local shared-edge failure:
  `curl --resolve beta.dope-ai.kr:443:127.0.0.1
  https://beta.dope-ai.kr/agent-pulse/health/get` returned Project Manager
  HTML.
- Reproduced macmini3 Agent Pulse edge failure:
  `curl http://127.0.0.1:4355/health/get` returned `502 Bad Gateway`.
- Isolated helper relay failure: local Mac helper was healthy on `55110`, but
  the reverse tunnel LaunchAgent forwarded `55112` to `rpi5-jumphost`, while
  macmini3 expected `127.0.0.1:55112`.
- Installed the local reverse tunnel with
  `scripts/macmini3/install-local-reverse-tunnel.sh`; macmini3 then showed
  `sshd-session` listening on `127.0.0.1:55112`, and
  `curl http://127.0.0.1:55112/health/get` returned Agent Pulse JSON with
  `codexAppServer: connected`.
- Reconciled the shared beta edge. macmini3 local edge
  `http://127.0.0.1:4355/health/get` returned Agent Pulse JSON with
  `codexAppServer: connected`.
- Verified authenticated TestFlight-facing route through macmini3 TLS resolve:
  Watch device `Apple Watch`, 32 summary threads, selected thread
  `office administrator`, `transcriptMessages = 8`, public URL
  `https://beta.dope-ai.kr/agent-pulse`, `openOnMac = false`.
- External internet proof through web fetch:
  `https://beta.dope-ai.kr/agent-pulse/health/get` returned
  `content-type: application/json`, `status: ok`, and
  `codexAppServer: connected`.
- Patched `scripts/macmini3/watch-agentpulse-beta-route.sh` so Project Manager
  safety checks use the configured local `--resolve` fallback and so route
  reconciliation still runs even when the helper relay or Agent Pulse edge is
  unhealthy.
- Added `scripts/macmini3/install-local-reverse-tunnel.sh` as the repeatable
  local LaunchAgent installer for `127.0.0.1:55112 -> this Mac 127.0.0.1:55110`.

## Validation Log

- PASS: `bash -n scripts/macmini3/watch-agentpulse-beta-route.sh
  scripts/macmini3/install-local-reverse-tunnel.sh
  scripts/macmini3/deploy-agentpulse-beta.sh
  scripts/macmini3/reconcile-agentpulse-shared-edge.sh
  scripts/macmini3/lib-agentpulse-beta-probe.sh`.
- PASS: Docker targeted contract test:
  `docker run --rm -v "$PWD":/work -v /work/node_modules -w /work
  node:22-bookworm bash -lc 'corepack enable && corepack prepare
  pnpm@10.28.2 --activate >/dev/null && pnpm install --frozen-lockfile
  >/dev/null && pnpm exec vitest run
  apps/helper/src/server/macmini-deploy-script.test.ts'`.
- PASS: Docker full product gate:
  `pnpm test`, `pnpm typecheck`, and `pnpm build` passed inside
  `node:22-bookworm`; tests reported 41 files and 559 tests passed.

## Completion State

- status: in_progress
