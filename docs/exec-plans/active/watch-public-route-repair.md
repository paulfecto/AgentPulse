# Execution plan

Repair and prove the Agent Pulse public Watch route at
`https://beta.dope-ai.kr/agent-pulse`.

- status: complete
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

- `bash -n scripts/macmini3/lib-agentpulse-beta-probe.sh scripts/macmini3/check-agentpulse-beta.sh scripts/macmini3/deploy-agentpulse-beta.sh scripts/macmini3/watch-agentpulse-beta-route.sh scripts/ci/run_agentpulse_beta_deploy.sh` passed.
- `git diff --check` passed for the route repair scripts and Watch client hunk.
- Local route-watchdog dry run against the broken public route detected the exact drift: Agent Pulse health returned HTML/Project Manager shell.
- Docker product gate was initially blocked because Docker Desktop was not
  running, then Docker Desktop was started and Docker validation completed.
- First Docker test run found one real contract-test regression in
  `apps/helper/src/server/macmini-deploy-script.test.ts`: it still expected
  the old fallback function name. The test was updated to assert the new local
  TLS vhost fallback and watchdog probe resolve behavior.
- Docker tests passed after the contract update:
  `docker run --rm -v "$PWD":/work -v /work/node_modules -w /work node:22-bookworm bash -lc 'corepack enable && corepack prepare pnpm@10.28.2 --activate && pnpm install --frozen-lockfile && pnpm test -- apps/helper/src/server/macmini-deploy-script.test.ts'`;
  result: 41 test files passed, 553 tests passed.
- Docker typecheck/build passed:
  `docker run --rm -v "$PWD":/work -v /work/node_modules -w /work node:22-bookworm bash -lc 'corepack enable && corepack prepare pnpm@10.28.2 --activate && pnpm install --frozen-lockfile && pnpm typecheck && pnpm build'`.
- Watch simulator build passed:
  `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project apps/watchos/AgentPulseWatch/AgentPulseWatch.xcodeproj -scheme AgentPulseWatch -configuration Debug -destination 'generic/platform=watchOS Simulator' build CODE_SIGNING_ALLOWED=NO`.
- First macmini3 deploy at `34f15dc` restored the public route but failed because macmini3 cannot connect to public `beta.dope-ai.kr:443` from itself.
- Second macmini3 deploy at `77e1f26` proved the need for a local TLS vhost probe after local HTTP returned a 301 redirect.
- Final macmini3 deploy at `964e1f7` passed:
  GitHub Actions run `25987144840`, helper and tablet built, shared edge reconciled, `nginx -t` passed, watchdog `com.agentpulse.route-watchdog.beta-edge` installed, and deploy reported Agent Pulse healthy at `https://beta.dope-ai.kr/agent-pulse`.
- Public post-deploy health returned JSON with `codexAppServer: "connected"` and `remoteAccess.publicUrl = "https://beta.dope-ai.kr/agent-pulse"`.
- Public unauthenticated `/watch/summary` returned HTTP 401 JSON `{"error":"missing"}`, not HTML.
- Public tablet shell returned `<title>Agent Pulse</title>` and `/agent-pulse/assets/`, with no `/project-manager/` asset references.
- Stress probe passed 100/100 iterations across `/agent-pulse/health/get`, `/agent-pulse/watch/summary`, `/agent-pulse/threads/list`, `/agent-pulse/`, `/project-manager/health`, and `/health`.
- AgentOS `verify_harness.py` was attempted with the configured harness root
  `../agentOS` and is blocked by pre-existing harness manifest drift:
  `57b8c0603a99b59ba2fc6cbc37dee5c432662dfa75c1d0b412ba4915eb14ab5a != d1ea748c25f22a9243672f2791500d71971eb2c5eee8fb43f6f2a11502849a94`.
- AgentOS `verify_exec_plan.py --stage start` was attempted and is blocked by
  unrelated stale active plan liveness for
  `codex-mobile-watch-remote-control.md`.

## Completion status

- state: complete
- result: public Watch-facing Agent Pulse route no longer returns Project
  Manager HTML; route watchdog is installed on macmini3 and public stress
  probes passed.
