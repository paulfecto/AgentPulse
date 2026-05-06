# Execution plan

Make Agent Pulse Watch usable outside the LAN through a branded, stable,
Codex-safe remote runtime.

- status: in-progress
- owner: codex
- started: 2026-05-05

## Target behavior

- The Watch app has a real app icon and in-app logo based on the existing Agent
  Pulse mark in `apps/tablet/public/icon.svg`.
- Remote access settings clearly distinguish temporary quick tunnels from the
  stable named Cloudflare tunnel required for anywhere-in-the-world Watch use.
- A dedicated host-side run path starts the real helper with isolated Agent
  Pulse state, real Codex app-server transport, and
  `AGENT_PULSE_DISABLE_CODEX_DESKTOP=1`.
- The helper fails fast on named remote access when `cloudflared` is missing,
  not authenticated, or not configured.
- APNs credentials remain outside git; Watch notifications stay configurable
  through helper settings.

## Inputs and constraints

- Work only on `main`.
- Do not focus, open, restart, kill, or IPC-control the Codex Desktop app.
- The real helper must run on macOS, not in Docker, because it uses the bundled
  Codex app-server.
- Run normal Node/helper validation inside Docker.
- Do not delete broad paths; avoid cleanup commands unless they target narrow,
  known disposable files.
- Stable Cloudflare hostname and APNs `.p8` key material are external inputs.

## Owning layer

- Owner: `codex`
- Product layers: Watch app assets/UI, helper Cloudflare supervisor, tablet
  settings UI, and host runtime launcher.
- Runtime boundary: helper talks to real Codex app-server; desktop UI control is
  disabled for the Watch remote runtime.

## Planned write set

- `docs/exec-plans/active/watch-global-runtime.md`
- `packages/shared/src/index.ts`
- `apps/helper/src/server/agent-pulse-server.ts`
- `apps/helper/src/server/agent-pulse-server.test.ts`
- `apps/helper/src/server/cloudflare-tunnel.ts`
- `apps/helper/src/server/cloudflare-tunnel.test.ts`
- `apps/tablet/src/App.tsx`
- `apps/tablet/src/App.test.tsx`
- `apps/tablet/src/styles.css`
- `apps/watchos/AgentPulseWatch/AgentPulseWatch.xcodeproj/project.pbxproj`
- `apps/watchos/AgentPulseWatch/AgentPulseWatch/**`
- `apps/watchos/AgentPulseWatch/README.md`
- `scripts/generate-watch-icons.sh`
- `scripts/watch-remote-helper.sh`

## File cohesion plan

These files exceed the harness size threshold in the current repo. This task
keeps changes local to existing tablet settings ownership rather than
decomposing unrelated tablet source as part of the Watch remote runtime work.

- file: `apps/tablet/src/App.tsx`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
- file: `apps/tablet/src/App.test.tsx`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
- file: `packages/shared/src/index.ts`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
- file: `apps/helper/src/server/agent-pulse-server.ts`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
- file: `apps/helper/src/server/agent-pulse-server.test.ts`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`

## Interface or contract changes

- `WatchSummaryResponse.remoteAccess` now includes `mode` so the Watch can
  distinguish stable named tunnels from temporary quick tunnels.
- The Watch store may persist an HTTPS named remote URL returned by
  `/watch/summary` after a local/LAN pairing succeeds.
- The tablet settings admin surface can configure stable Cloudflare hostname,
  tunnel name, login, and temporary tunnel mode through existing helper
  settings routes.
- Named Cloudflare tunnel startup now fails fast when login/authentication or a
  hostname is missing.

## Acceptance criteria

- Watch asset catalog contains app icon, accent color, and reusable logo image
  assets.
- Xcode project compiles the asset catalog and uses `AppIcon`.
- Watch pairing/offline/empty states render the Agent Pulse mark.
- Tablet settings can configure named Cloudflare hostname/tunnel name and show
  stable-domain checklist copy.
- Helper named tunnel config has one hostname ingress rule and refuses to start
  named mode before Cloudflare login.
- The dedicated Watch remote launcher keeps Codex Desktop control disabled and
  does not kill existing Codex Desktop processes.
- Docker `pnpm test`, `pnpm typecheck`, and `pnpm build` pass or record a real
  environment blocker.
- Xcode simulator build is attempted with signing disabled.

## TDD plan

- smallest failing check: targeted Docker Vitest coverage for named tunnel
  preflight failure, stable remote settings UI, Watch summary compact contract,
  and Watch remote URL persistence seam.
- red signal: named mode starts without Cloudflare login, stable hostname fields
  are missing from settings, Watch summary omits remote mode, or Watch keeps a
  local URL after receiving a stable HTTPS remote URL.
- fixture or seam: temporary Cloudflare config directories, mocked
  `cloudflared` process, jsdom settings UI tests, and decoded shared schemas.
- green condition: targeted Docker tests pass and the watchOS simulator build
  succeeds with the new asset catalog.
- refactor guard: Docker full `pnpm test`, Docker `pnpm typecheck`, Docker
  `pnpm build`, and AgentOS harness verifiers pass.

## Validation matrix

| Surface | Check | Proof |
| --- | --- | --- |
| Watch branding | `pnpm watch:icons` plus Xcode simulator build | assets compile and `AppIcon` is wired |
| Helper Cloudflare guard | Docker targeted Vitest | named tunnel refuses missing login/hostname |
| Tablet settings | Docker targeted Vitest | stable hostname mode can be configured |
| Shared/watch contract | Docker targeted Vitest and typecheck | `/watch/summary` exposes remote mode |
| Repo gates | Docker `pnpm test`, `pnpm typecheck`, `pnpm build` | product checks pass in disposable container |
| Runtime launcher | static review and fail-fast checks | launcher requires hostname/cloudflared login and disables Codex Desktop control |

## Deploy/runtime impact

- Real helper runtime remains a macOS host process because the Codex app-server
  binary is macOS-only.
- Docker is used only for validation and leaves no long-running container.
- The new Watch remote launcher refuses to start when port `55110` is already in
  use; it does not kill existing helper or Codex Desktop processes.
- Stable world access still requires an external Cloudflare hostname and local
  `cloudflared` login before launch.
- APNs delivery still requires external Apple APNs Key ID and `.p8` key path.

## Review risks and open questions

- A stable Cloudflare hostname was not available in this session, so global
  pairing could not be launched or proven end to end.
- APNs credentials were not available, so notification delivery remains an
  external setup blocker.
- The launcher seeds isolated Agent Pulse state and keeps normal macOS `HOME`;
  review focus is making sure that isolation does not change Codex app-server
  authentication state.

## Validation evidence

- commands run: `git -C ../agentOS fetch origin main --prune`; `git -C
  ../agentOS pull --ff-only origin main`; `bash
  ../agentOS/scripts/harness/install.sh --repo "$PWD" --accept-adoption-plan`;
  `pnpm watch:icons`; Docker targeted `vitest` for helper/tablet/shared watch
  surfaces; Docker full `pnpm test`; Docker `pnpm typecheck`; Docker `pnpm
  build`; `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild
  -project apps/watchos/AgentPulseWatch/AgentPulseWatch.xcodeproj -scheme
  AgentPulseWatch -destination 'generic/platform=watchOS Simulator'
  CODE_SIGNING_ALLOWED=NO build`; AgentOS `verify_harness.py`;
  AgentOS `verify_protocol.py`; AgentOS `doctor_engineering_discipline.py`.
- runtime proof: Codex Desktop was not focused, opened, restarted, killed, or
  IPC-controlled. The dedicated launcher sets
  `AGENT_PULSE_DISABLE_CODEX_DESKTOP=1`, preserves normal macOS `HOME`, uses
  isolated Agent Pulse settings/admin/keychain paths, and refuses to start over
  an existing helper on port `55110`.
- remaining gaps: global remote launch and Watch re-pairing are blocked until a
  stable Cloudflare hostname plus authenticated `cloudflared` tunnel are
  supplied; APNs delivery is blocked until APNs Key ID and `.p8` key path are
  supplied outside git.
- Watch timeout diagnosis, 2026-05-06: the physical Watch showed request
  timeout because the helper was no longer listening on `55110`, the default
  helper settings had drifted to port `50675` with LAN disabled, and the helper
  bundle on disk was stale. The fix set helper settings back to
  `port = 55110`, `lanEnabled = true`, and `mobileSendEnabled = true`, rebuilt
  shared/tablet/helper bundles, restarted the helper with
  `AGENT_PULSE_DISABLE_CODEX_DESKTOP=1`, rebuilt/reinstalled the Watch app, and
  launched it with a DEBUG bootstrap refresh. Proof: LAN health passed at
  `http://172.30.1.15:55110/health/get`, `/watch/summary` returned the current
  Watch contract including `remoteAccess.mode`, and the helper recorded the
  Watch device `lastSeenAt = 2026-05-06T01:33:18.711Z`.

## TDD evidence

- red signal: the first targeted Docker run exposed missing named-tunnel login
  fixture setup for the new Cloudflare preflight expectations; the first full
  Docker test copy also exposed host AppleDouble `._*.test.ts` files entering
  the container tar stream.
- red artifact: transient Docker console output only; no durable artifact
  retained.
- green result: targeted Docker tests passed after adding explicit fake
  Cloudflare cert fixtures; full Docker `pnpm test` passed after streaming the
  repo with `COPYFILE_DISABLE=1` and excluding AppleDouble files; Docker
  `pnpm typecheck`, Docker `pnpm build`, and Xcode watchOS simulator build all
  passed.
- green artifact: transient Docker and Xcode console output only; no durable
  artifact retained.
- refactor verification: `git diff --check` passed and AgentOS harness/protocol
  checks passed after the AgentOS 4.12.2 update.

## Review evidence

- reviewer: `codex` using AgentOS harness checks plus targeted diff inspection
  of Cloudflare supervisor, tablet settings, shared schema, Watch SwiftUI, asset
  catalog, and launcher changes.
- review artifact:
  `docs/exec-plans/active/review-cycles/watch-global-runtime/cycle-001/review-verdict.md`
- unresolved findings: no blocking code findings from local review. External
  blockers remain stable Cloudflare hostname/authentication and APNs key
  material.

## Completion status

- state: complete-with-external-blockers.
- ready for merge or deploy: code and validation are ready for review; global
  runtime launch and APNs proof require the external hostname and Apple APNs
  secrets.

## Frontier routing

- status: single-lane-not-escalated.
- task class: implementation
- arbiter: codex
