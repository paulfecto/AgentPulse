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
- PASS: Deployed commit `e240214` directly to macmini3 over SSH; deploy built
  helper/tablet, recreated only `agentpulse-beta-edge`, reconciled the shared
  edge after `nginx -t`, installed the patched
  `com.agentpulse.route-watchdog.beta-edge` LaunchAgent, and reported Agent
  Pulse healthy at `https://beta.dope-ai.kr/agent-pulse`.
- PASS: Patched route watchdog one-shot on macmini3:
  `AGENT_PULSE_ROUTE_WATCHDOG_ONCE=1 ... bash
  scripts/macmini3/watch-agentpulse-beta-route.sh` reported `Route healthy at
  https://beta.dope-ai.kr/agent-pulse`.
- PASS: Bounded TestFlight-facing stress probe: 20 loops through macmini3 TLS
  resolve checked `/health/get`, authenticated `/watch/summary`, and
  authenticated `transcript?limit=8&history=full&window=tail`; every response
  stayed JSON, never Project Manager HTML, and transcript size stayed within
  the 8-message Watch limit. Selected thread title was `office administrator`.
- PASS: `gh run list --repo paulfecto/AgentPulse --limit 5` showed only older
  `workflow_dispatch` runs from 2026-05-17; this repair did not use a GitHub
  Actions deployment.

## 2026-05-27 Regression Reopen

### Current Failure

- Public route regression reproduced at 2026-05-27T01:00Z:
  `curl https://beta.dope-ai.kr/agent-pulse/health/get` returned HTTP `502`
  with `content-type: text/html`.
- `https://beta.dope-ai.kr/agent-pulse/watch/summary` also returned HTTP `502`
  HTML.
- Project Manager stayed healthy:
  `https://beta.dope-ai.kr/project-manager/health` and
  `https://beta.dope-ai.kr/health` both returned `healthy`.
- macmini3 had `sshd-session` listening on `127.0.0.1:55112`, but
  `curl http://127.0.0.1:55112/health/get` failed with
  `Recv failure: Connection reset by peer`.
- This Mac had no process listening on `127.0.0.1:55110`, while the reverse
  tunnel LaunchAgent was still running with
  `-R 127.0.0.1:55112:127.0.0.1:55110 macmini-3`.
- Root cause: the shared edge route and tunnel were present, but the desktop
  Mac helper was not supervised, so the relay reset and the Docker/shared edge
  returned nginx HTML `502`.
- Secondary root cause for the Watch `unknown device` state: the live Apple
  Watch pairing was stored under keychain service `com.agentpulse.helper`, while
  the beta helper defaulted to an empty `AgentPulseBeta` service.

### Additional Write Set

- `scripts/macmini3/install-local-beta-helper.sh`
- `apps/helper/src/server/macmini-deploy-script.test.ts`
- `docs/deploy/macmini3-agent-pulse-beta.md`
- `docs/exec-plans/active/watch-testflight-public-route-drift.md`

### Additional Acceptance Criteria

- Codex desktop Mac has a tracked local helper LaunchAgent installer.
- The local helper LaunchAgent starts the helper with:
  `AGENT_PULSE_DISABLE_CODEX_DESKTOP=1`,
  `AGENT_PULSE_SKIP_MANAGED_TUNNEL=1`,
  `AGENT_PULSE_PUBLIC_URL=https://beta.dope-ai.kr/agent-pulse`, and
  port `55110`.
- The local helper LaunchAgent uses the existing paired-device keychain service
  when present, so the TestFlight Watch remains known after restart.
- The installer proves local helper health before reporting success.
- The installer stages a HOME-owned runtime before LaunchAgent start, because
  this Mac rejected LaunchAgent execution from the external `/Volumes/...`
  checkout with `Operation not permitted`.
- The existing reverse tunnel can then make macmini3 `127.0.0.1:55112` reach
  the local helper instead of resetting.
- Public `/agent-pulse/health/get` and Watch APIs return Agent Pulse JSON,
  never Project Manager HTML or nginx HTML.
- Docker edge and shared edge convert Agent Pulse upstream `5xx` failures to a
  small JSON error payload, so even transient helper/relay failures do not
  surface as a web page to TestFlight.
- SIGTERM on the helper exits within a bounded time, so LaunchAgent can restart
  it instead of leaving a stale listener that accepts TCP but never answers
  health checks.
- The helper LaunchAgent uses `KeepAlive = true`, so a clean signal-triggered
  helper exit is restarted just like a crash.

### 2026-05-27 Evidence Log

- Reproduced live public failure:
  `https://beta.dope-ai.kr/agent-pulse/health/get` returned HTTP `502` with
  `content-type: text/html`; `/watch/summary` also returned HTTP `502` HTML.
- Confirmed Project Manager was not broken:
  `https://beta.dope-ai.kr/project-manager/health` and
  `https://beta.dope-ai.kr/health` returned `healthy`.
- Isolated failed hop:
  macmini3 `127.0.0.1:55112` was listening but reset connections; this Mac had
  no listener on `127.0.0.1:55110`, so macmini3 Docker edge returned nginx
  `502`.
- First LaunchAgent install attempt failed from the external checkout with
  `Operation not permitted`; fixed by staging the built runtime under
  `~/Library/Application Support/Agent Pulse Beta/runtime`.
- Existing TestFlight Watch pairing was found under keychain service
  `com.agentpulse.helper`; installer now auto-selects that service when
  present and passes `AGENT_PULSE_KEYCHAIN_SERVICE` to the helper.
- Local helper install passed:
  `scripts/macmini3/install-local-beta-helper.sh` built and installed
  `com.agentpulse.helper.55110.beta-edge`, then proved local
  `/health/get` returned `codexAppServer: connected`.
- Relay and edge proof passed:
  macmini3 `http://127.0.0.1:55112/health/get`,
  `http://127.0.0.1:4355/health/get`, and local shared TLS resolve for
  `/agent-pulse/health/get` all returned Agent Pulse JSON with
  `codexAppServer: connected`.
- Public route proof passed:
  `https://beta.dope-ai.kr/agent-pulse/health/get` returned Agent Pulse JSON;
  unauthenticated `/watch/summary` returned JSON `401 {"error":"missing"}`;
  tablet shell loaded Agent Pulse HTML under `/agent-pulse/`, not Project
  Manager.
- Watch-auth proof passed using the existing Apple Watch device keychain
  record: `/watch/summary` returned HTTP `200`, 32 threads, remote URL
  `https://beta.dope-ai.kr/agent-pulse`; known Agent Pulse thread transcript
  returned HTTP `200` JSON capped at 8 messages.
- Supervisor proof passed after the bounded shutdown patch and `KeepAlive =
  true`: sending SIGTERM to the helper process produced a new helper pid on
  attempt 2, and public `/agent-pulse/health/get` returned JSON
  `codexAppServer: connected` without manual repair.
- macmini3 route watchdog one-shot passed:
  `AGENT_PULSE_ROUTE_WATCHDOG_ONCE=1 ... watch-agentpulse-beta-route.sh`
  reported route healthy; Project Manager health remained healthy.
- Authenticated public Watch stress passed 20 loops:
  `/health/get`, authenticated `/watch/summary`, and authenticated
  `transcript?limit=8&history=full&window=tail` stayed JSON, never returned
  Project Manager/nginx HTML, and transcript messages stayed at 8.

### 2026-05-27 Validation Log

- PASS: shell syntax:
  `bash -n scripts/macmini3/install-local-beta-helper.sh
  scripts/macmini3/install-local-reverse-tunnel.sh
  scripts/macmini3/watch-agentpulse-beta-route.sh
  scripts/macmini3/deploy-agentpulse-beta.sh
  scripts/macmini3/reconcile-agentpulse-shared-edge.sh
  scripts/macmini3/lib-agentpulse-beta-probe.sh`.
- PASS: targeted Docker contract test:
  `pnpm exec vitest run apps/helper/src/server/macmini-deploy-script.test.ts`
  in `node:22-bookworm`; 4 tests passed.
- PASS: final Docker product gate in `node:22-bookworm`:
  `pnpm test`, `pnpm typecheck`, and `pnpm build`; 41 test files and 560 tests
  passed.
- PASS: pushed commit `219d884420b1ae0291ee979432fecb7667fc0408` to
  `origin/main`.
- PASS: macmini3 checkout fast-forwarded to
  `219d884420b1ae0291ee979432fecb7667fc0408` without a hard reset.
- PASS: direct macmini3 deploy of `219d884420b1ae0291ee979432fecb7667fc0408`
  built the tablet/helper, recreated only `agentpulse-beta-edge`, reconciled
  the marked `/agent-pulse` shared-edge block after `nginx -t`, reinstalled
  `com.agentpulse.route-watchdog.beta-edge`, and reported Agent Pulse beta
  healthy.
- PASS: post-deploy public checks:
  `/agent-pulse/health/get` returned JSON with `codexAppServer: connected`,
  `/agent-pulse/` served the Agent Pulse tablet shell, and
  `/project-manager/health` stayed `healthy`.
- PASS: post-deploy Watch-auth stress:
  15 loops over public `/health/get`, unauthenticated `/watch/summary`
  expecting JSON `401`, authenticated `/watch/summary`, and authenticated
  Agent Pulse thread transcript. Every API response stayed JSON, transcript
  messages stayed capped at 8, and no nginx/Project Manager HTML appeared.

## Completion State

- status: complete
