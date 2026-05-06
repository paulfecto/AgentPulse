# Execution plan

Run Agent Pulse against real Codex app-server and real Watch/APNs surfaces
without focusing, opening, restarting, or IPC-controlling the Codex desktop app.

- status: complete-with-external-blockers
- owner: codex
- started: 2026-05-05

## Target behavior

- `AGENT_PULSE_DISABLE_CODEX_DESKTOP=1` prevents Codex Desktop IPC connection
  and blocks `/thread/open`.
- The helper runs on `55110` with the real bundled Codex app-server binary, not a
  fake preview transport.
- Watch summary tells clients whether Open on Mac is available.
- The native Watch app builds from a tracked Xcode project under
  `apps/watchos/AgentPulseWatch`.
- Pairing, summary, detail, reply, stop, token registration, and APNs delivery
  are validated as far as the available Apple signing/APNs credentials allow.

## Inputs and constraints

- Keep Codex Desktop undisturbed: do not focus, open, restart, kill, or IPC-drive
  the desktop app.
- Use the current helper on `55110` and real Codex app-server transport.
- Use a Mac LAN URL for Watch pairing, never `127.0.0.1`.
- Run normal Node/helper gates only in Docker and clean disposable containers.
- Use Xcode tooling for Watch builds because watchOS signing cannot be proven in
  Docker.
- Signing secrets, APNs `.p8` keys, provisioning profiles, and team identifiers
  must stay out of git.

## Owning layer

- Owner: `codex`
- Product layers: helper runtime guardrails, shared watch capability contract,
  watchOS project/scaffold, and runtime validation evidence.
- Runtime boundary: helper controls Codex app-server; desktop UI control is
  disabled for the E2E runtime.

## Planned write set

- `docs/exec-plans/active/real-watch-e2e.md`
- `docs/exec-plans/active/HARNESS_PROGRESS_LEDGER.html`
- `docs/exec-plans/active/TEAM_PROGRESS_LEDGER.html`
- `docs/exec-plans/active/WORKING_CONTEXT.md`
- `docs/exec-plans/active/state-ledger.json`
- `packages/shared/src/index.ts`
- `apps/helper/src/auth/admin.ts`
- `apps/helper/src/auth/keychain-store.ts`
- `apps/helper/src/dev-server.ts`
- `apps/helper/src/main.ts`
- `apps/helper/src/server/agent-pulse-server.ts`
- `apps/helper/src/server/agent-pulse-server.test.ts`
- `apps/helper/src/server/settings.ts`
- `apps/tablet/src/App.tsx`
- `apps/tablet/src/App.test.tsx`
- `apps/watchos/AgentPulseWatch/AgentPulseWatch.xcodeproj/**`
- `apps/watchos/AgentPulseWatch/AgentPulseWatch/**`
- `apps/watchos/AgentPulseWatch/README.md`

## File cohesion plan

These files exceed the harness size threshold in the current repo. This task
keeps changes local to their existing ownership rather than decomposing
unrelated source as part of the Watch E2E runtime setup.

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
- file: `apps/tablet/src/App.tsx`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
- file: `apps/tablet/src/App.test.tsx`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`

## Interface or contract changes

- Add desktop-control-disabled runtime behavior through
  `AGENT_PULSE_DISABLE_CODEX_DESKTOP=1`.
- Add isolated Agent Pulse runtime state path overrides without changing Codex
  app-server authentication state.
- Make `/thread/open` return `403` when desktop control is disabled.
- Surface `open_on_mac` availability through Watch/tablet capability payloads so
  clients can hide or disable Open on Mac.
- Add a tracked standalone Watch Xcode project for the existing SwiftUI sources.

## Acceptance criteria

- `/health/get` reports `codexAppServer: "connected"` against the real helper.
- Process proof shows `/Applications/Codex.app/Contents/Resources/codex
  app-server` and no `/tmp/fake-bin/codex`.
- `/thread/open` is blocked while desktop control is disabled.
- `/watch/summary` returns real Codex-backed compact data with Open on Mac
  unavailable.
- Watch reply under 500 characters sends through the real app-server path.
- Docker `pnpm test`, `pnpm typecheck`, and `pnpm build` pass after tracked code
  changes.
- Watch simulator build succeeds with signing disabled.
- Physical Watch install/APNs delivery either succeeds or records the missing
  Apple signing/APNs material as an external blocker.
- Limited local physical install without APNs either succeeds or records the
  Watch/Xcode trust or developer-service blocker.

## TDD plan

- smallest failing check: Docker targeted Vitest coverage for desktop-disabled
  mode, Watch summary capability, watch reply path, and watch push token
  registration.
- red signal: IPC connection attempt, `/thread/open` success in disabled mode,
  fake transport use, missing capability flag, or missing push token persistence.
- fixture or seam: isolated helper state paths, mocked/real helper HTTP API, and
  process inspection for the spawned Codex app-server child.
- green condition: targeted Docker tests pass and runtime proof hits the real
  helper on `55110`.
- refactor guard: Docker full gates plus Xcode simulator build with signing
  disabled.

## Validation matrix

| Surface | Check | Proof |
| --- | --- | --- |
| Node contracts | Docker `pnpm test` | helper/shared/tablet behavior passes |
| Type/build | Docker `pnpm typecheck` and `pnpm build` | repo compiles after runtime/watch changes |
| Real runtime | `/health/get`, process list, `/watch/summary`, `/thread/open` | real Codex app-server path and desktop-disabled behavior |
| Watch build | `xcodebuild ... CODE_SIGNING_ALLOWED=NO build` | standalone Watch simulator build succeeds |
| Physical APNs | Xcode physical Watch install and APNs token registration | blocked without paid team/APNs key material |

## Deploy/runtime impact

- The E2E helper intentionally uses isolated Agent Pulse state while leaving
  normal macOS `HOME` intact for real Codex authentication.
- Desktop UI control is disabled in this runtime, so Open on Mac is unavailable.
- Watch APNs sandbox configuration remains disabled until real Apple Developer
  Program credentials are supplied.

## Review risks and open questions

- A paid Apple Developer Program team is required for the Push Notifications
  capability; the discovered Personal Team cannot complete APNs provisioning.
- No local APNs `.p8` key was available under searched locations.
- Physical Watch install and notification tap behavior remain manual external
  verification once signing and APNs credentials exist.

## Validation evidence

- commands run: Docker targeted helper/shared/settings/auth tests; Docker
  `pnpm test`; Docker `pnpm typecheck`; Docker `pnpm build`; helper runtime
  health/process/API probes; Xcode simulator build with signing disabled.
- runtime proof: real helper remained live on `http://127.0.0.1:55110`;
  `/health/get` returned `codexAppServer: "connected"`; process proof showed
  child `/Applications/Codex.app/Contents/Resources/codex app-server`; no
  `/tmp/fake-bin/codex` helper child was present; current LAN pairing URL
  candidate was `http://172.30.1.93:55110`.
- remaining gaps: physical Watch install and APNs notification delivery remain
  blocked until a paid Apple Developer Program team with Push Notifications
  capability and APNs `.p8` credentials are available.
- Assisted physical Watch setup pass, 2026-05-05:
  - helper settings had LAN enabled, mobile send enabled, Watch notifications
    sandbox bundle `com.paulfecto.AgentPulse.watchkitapp`, and Watch
    notifications disabled pending APNs credentials
  - local APNs `.p8` search under `~/Downloads`, `~/Desktop`, and `~/.config`
    found no key material
  - `security find-identity -p codesigning -v` found 0 valid code-signing
    identities
  - Xcode GUI was opened with computer-use, Apple Account sign-in was completed
    by the user in the secure Xcode prompt, and `xcodebuild -project ... -list`
    then succeeded
  - Xcode saw the physical Watch over local network, but the account exposed
    only a Personal Team
- physical/APNs provisioning failed because Personal Teams do not support the
  Push Notifications capability
- fixed the Watch project to build as a standalone watchOS app, removed the
  Xcode-written team ID from tracked project settings, removed
  watchOS-unavailable `keyboardType`, lowered deployment target to watchOS
  9.0, and replaced watchOS 10-only navigation/change handlers with watchOS
  9-compatible forms
- simulator build now passes with signing disabled
- Docker full gates were rerun in a throwaway `node:22-bookworm` container
  using a streamed repo copy that excluded host dependency/build folders;
  result: 34 test files passed, 454 tests passed; typecheck passed; build
  passed
- Limited physical install attempt, 2026-05-05:
  - removed the default Watch APNs entitlement and made remote notification
    registration opt-in with `AgentPulseRemoteNotificationsEnabled = false`
    so Personal Team signing is not blocked by Push Notifications
  - updated the Watch README to document the default limited local build and
    the separate APNs-enabled build path
  - lowered the Watch deployment target to watchOS 8.0 and replaced
    watchOS-10-only `foregroundStyle`/destructive button usage with older
    compatible SwiftUI APIs
  - `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild
    -project apps/watchos/AgentPulseWatch/AgentPulseWatch.xcodeproj -scheme
    AgentPulseWatch -destination 'generic/platform=watchOS Simulator'
    CODE_SIGNING_ALLOWED=NO build` passed
  - `xcrun devicectl list devices` saw `Paul’s Apple Watch` as paired and
    available over local network
  - `xcrun devicectl device info ddiServices --device
    E8FAD98B-82EA-5852-A29A-32F306E17758` failed with
    `com.apple.dt.RemotePairingError 1007`: the device rejected the developer
    connection request
  - `xcodebuild -showdestinations` continued to mark the Watch ineligible
    because Xcode could not read a watchOS version/build from the device and
    displayed it as lower than the watchOS 8.0 deployment target
  - automatic provisioning with the Personal Team failed because no eligible
    developer-connected Watch was available for profile generation
  - physical install remains blocked until the Watch accepts developer pairing
    services, typically by unlocking the Watch, keeping it on the same network,
    enabling Developer Mode/trust if prompted, and allowing Xcode to reconnect
- Physical Watch install pass, 2026-05-05:
  - after Developer Mode was enabled and Xcode/CoreDevice DDI services were
    usable, `xcodebuild -showdestinations` resolved `Paul’s Apple Watch` as an
    available physical `watchOS` destination with `arm64_32`
  - signed physical Watch build succeeded with local automatic signing using
    `DEVELOPMENT_TEAM=H86Z687FT6`; Xcode generated the local development
    provisioning profile for `com.paulfecto.AgentPulse.watchkitapp`
  - first install attempt reached the Watch and exposed a real Info.plist
    validation error: `WKWatchOnly` and `WKRunsIndependentlyOfCompanionApp`
    cannot both be present; removed the redundant
    `WKRunsIndependentlyOfCompanionApp` key for the watch-only app
  - `xcrun devicectl device install app --device
    E8FAD98B-82EA-5852-A29A-32F306E17758
    /tmp/agentpulse-watch-signed-generic/Build/Products/Debug-watchos/AgentPulseWatch.app`
    installed `Agent Pulse` on the physical Watch with bundle id
    `com.paulfecto.AgentPulse.watchkitapp`
  - `xcrun devicectl device process launch --device
    E8FAD98B-82EA-5852-A29A-32F306E17758
    com.paulfecto.AgentPulse.watchkitapp` launched the installed app
  - added a Debug-only `devicectl` launch-environment bootstrap path for
    assisted local pairing; relaunched the Watch app with the existing valid
    isolated helper device session and LAN URL `http://172.30.1.93:55110`
  - helper keychain device record for the Apple Watch updated
    `lastSeenAt` from `2026-05-05T09:58:15.720Z` to
    `2026-05-05T09:59:40.375Z`, proving the physical Watch app reached the
    real helper with the bootstrapped session
  - `xcrun devicectl device info apps` confirmed the app remains installed on
    the Watch, and `xcrun devicectl device info processes` showed
    `AgentPulseWatch.app/AgentPulseWatch` running
  - `/health/get` continued to report `codexAppServer: "connected"` and
    `/watch/summary` returned real Codex-backed threads with
    `canOpenOnMac: false` for the desktop-disabled runtime
  - a manual `/threads/:threadId/transcript?view=watch` smoke request was
    stopped because transcript hydration hung; this did not affect Watch
    install, launch, summary, or helper-session validation

## TDD evidence

### Watch Codex conversation parity fix, 2026-05-06

- failing signal to prove: Watch detail fetches `view=watch`, renders only
  `suffix(8)`, clamps messages to 5 lines, and the Codex thread reader lets
  generated project-anchor rows through as normal sidebar threads.
- intended fix: Watch detail uses the default Codex-visible transcript window,
  lazy-loads older history, and the helper filters Codex thread rows to hide
  subagent/internal/project-anchor rows from user-facing lists.
- validation to record: targeted Vitest red/green, Docker `pnpm test`,
  Docker `pnpm typecheck`, Docker `pnpm build`, Watch simulator build, and
  physical Watch install if Xcode/device connectivity permits.

- red signal: targeted tests and runtime probes initially exposed missing
  desktop-disabled guardrails and Watch build/toolchain compatibility issues.
- red artifact: failing Docker targeted tests and failing Xcode simulator build
  output were used as transient console evidence and not retained.
- green result: 5 targeted Docker files passed with 108 tests; full Docker gate
  passed with 34 files and 454 tests; typecheck passed; build passed; Xcode
  simulator build passed with signing disabled.
- green artifact: transient Docker and Xcode console output; no durable artifact
  retained.
- refactor verification: final Docker `pnpm typecheck` and `pnpm build` passed
  after Watch/helper runtime changes.

## Review evidence

- reviewer: `codex` using AgentOS execution-plan validation and targeted diff
  inspection.
- one source of truth: helper owns runtime state and Codex transport; shared
  schemas own watch capability contracts; Watch app consumes helper APIs only.
- unresolved findings: no blocking repo validation finding; physical APNs and
  Watch install remain external Apple account/credential blockers.

## Completion status

- state: complete-with-apple-membership-blocker.
- ready for merge or deploy: yes for checked-in helper/watch runtime changes;
  physical Watch local install/launch/pairing path is proven. The Watch target
  is now APNs-ready in git with `aps-environment = development` and remote
  registration enabled, but physical APNs signing is blocked because the
  available local team is a Personal Team and Apple refuses Push Notifications
  for `com.paulfecto.AgentPulse.watchkitapp` until a paid Apple Developer
  Program team and APNs `.p8` key are available.

## APNs finish attempt, 2026-05-05

- changed the Watch target to the APNs sandbox build shape:
  `AgentPulseRemoteNotificationsEnabled = true`, `aps-environment =
  development`, and Push Notifications enabled in the Xcode target capability
  metadata.
- `plutil -lint apps/watchos/AgentPulseWatch/AgentPulseWatch/Info.plist
  apps/watchos/AgentPulseWatch/AgentPulseWatch/AgentPulseWatch.entitlements`
  passed.
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild
  -project apps/watchos/AgentPulseWatch/AgentPulseWatch.xcodeproj -scheme
  AgentPulseWatch -destination 'generic/platform=watchOS Simulator'
  -derivedDataPath /tmp/agentpulse-watch-apns-sim CODE_SIGNING_ALLOWED=NO
  build` passed.
- physical APNs build with `DEVELOPMENT_TEAM=H86Z687FT6` failed because
  Personal Teams do not support the Push Notifications capability and the
  existing provisioning profile lacks `aps-environment`.
- no APNs `.p8` key was found under `~/Downloads`, `~/Documents`, or
  `~/Desktop` with a bounded search, so helper APNs configuration could not be
  completed.
- restarted only the isolated Agent Pulse helper on port 55110 after the old
  helper spun at high CPU and stopped answering `/health/get`; Codex Desktop was
  not killed or restarted.
- fresh helper validation passed: `/health/get` returned
  `codexAppServer: "connected"`, process proof showed
  `node apps/helper/dist/dev-server.js` with child
  `/Applications/Codex.app/Contents/Resources/codex app-server`, and
  `/watch/summary` returned real Codex-backed threads with `canOpenOnMac:
  false`.
- Docker validation in a disposable `node:22-bookworm` container passed:
  `pnpm test` reported 34 files and 454 tests passed, then `pnpm typecheck`
  passed, then `pnpm build` passed.
- the installed physical Watch app was relaunched through `devicectl` using the
  debug bootstrap session and LAN URL `http://172.30.1.93:55110`; the helper
  updated the Apple Watch device `lastSeenAt` to
  `2026-05-05T10:16:54.145Z`, and `devicectl device info processes` showed
  `AgentPulseWatch.app/AgentPulseWatch` running.
- the Apple Watch device record still has no `watchPushToken`, which is
  expected because the APNs-enabled build cannot be signed or installed until a
  paid Apple Developer Program team and APNs key material exist.

## Physical Watch APNs token proof, 2026-05-05

- Xcode was refreshed after paid Apple Developer Program activation; the
  account now appears as `Developer Team`, role `Admin`, with Certificates,
  Identifiers, & Profiles enabled for Team ID `H86Z687FT6`.
- Watch CoreDevice recovery required a physical Watch reboot, then
  `devicectl manage pair --device
  E8FAD98B-82EA-5852-A29A-32F306E17758` returned `connected` and
  `devicectl device info ddiServices --device
  E8FAD98B-82EA-5852-A29A-32F306E17758` reported `isUsable: true`.
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild
  -project apps/watchos/AgentPulseWatch/AgentPulseWatch.xcodeproj -scheme
  AgentPulseWatch -destination
  'platform=watchOS,id=00008301-2084A531140BC02E' -derivedDataPath
  /tmp/agentpulse-watch-paid-final -allowProvisioningUpdates
  -allowProvisioningDeviceRegistration DEVELOPMENT_TEAM=H86Z687FT6 build`
  passed with `aps-environment = development`.
- `devicectl device install app --device
  E8FAD98B-82EA-5852-A29A-32F306E17758
  /tmp/agentpulse-watch-paid-final/Build/Products/Debug-watchos/AgentPulseWatch.app`
  installed `com.paulfecto.AgentPulse.watchkitapp`.
- `devicectl device process launch --device
  E8FAD98B-82EA-5852-A29A-32F306E17758 --terminate-existing
  --environment-variables ... com.paulfecto.AgentPulse.watchkitapp` launched
  the Watch app against LAN helper URL `http://172.30.1.93:55110`.
- helper device record proof for device
  `0951b796-5da6-43d3-a5e2-3556c8ef65e7`: `hasWatchPushToken: true`,
  `watchPushTokenLength: 64`, `watchPushBundleId:
  com.paulfecto.AgentPulse.watchkitapp`, `watchPushEnvironment: sandbox`, and
  `watchPushTokenUpdatedAt: 2026-05-05T13:08:58.363Z`.
- `/watch/summary` proof returned 12 real Codex-backed threads and
  `canOpenOnMac: false`, preserving the desktop-control-disabled runtime
  boundary.
- remaining blocker: helper APNs sender settings are not enabled because no
  APNs auth key `.p8` path and Key ID have been provided. Current isolated
  helper settings show `watchNotifications.enabled: false`, `bundleId:
  com.paulfecto.AgentPulse.watchkitapp`, and `environment: sandbox`.

## Watch Codex conversation parity proof, 2026-05-06

- targeted red signal: before the fix, `view=watch` remained the Watch detail
  fetch path, Watch detail rendered only `suffix(8)`, messages were line
  clamped, and targeted helper tests proved subagent/internal/project-anchor
  rows could reach Watch-facing thread lists.
- implementation result: Watch detail now requests the default
  Codex-visible transcript window, renders all loaded messages without a line
  clamp, lazy-loads older pages through
  `/threads/:threadId/transcript/older`, and notification navigation refreshes
  the selected thread detail.
- helper result: the Codex thread reader applies one Codex-visible row
  predicate before workspace limiting, `/watch/summary` only exposes Codex
  provider rows, and generated project anchors, subagent sources, internal
  rows, Claude, and Copilot side-lane rows are excluded from the Watch summary.
- deployment config fix: `deploy/macmini3/agentpulse-nginx.conf` and
  `scripts/macmini3/check-agentpulse-beta.sh` now point at helper port `55110`,
  matching `scripts/macmini3/run-agentpulse-beta-helper.sh` and the documented
  macmini3 runtime.
- Docker validation passed:
  - targeted `vitest run apps/helper/src/server/dev-run-script.test.ts`: 5
    tests passed.
  - full `pnpm test`: 34 files and 463 tests passed.
  - `pnpm typecheck`: passed.
  - `pnpm build`: passed.
- deployment config validation passed:
  - `docker compose -f docker-compose.macmini3.yml config` passed.
  - `docker run --rm --add-host=host.docker.internal:host-gateway -v
    "$PWD/deploy/macmini3/agentpulse-nginx.conf:/etc/nginx/conf.d/default.conf:ro"
    nginx:1.27-alpine nginx -t` passed.
  - `bash -n scripts/macmini3/run-agentpulse-beta-helper.sh
    scripts/macmini3/check-agentpulse-beta.sh` passed.
- Watch build/install proof from this fix cycle:
  - watchOS simulator build passed with signing disabled.
  - physical build passed for device `00008301-2084A531140BC02E` with
    `DEVELOPMENT_TEAM=H86Z687FT6`.
  - `devicectl device install app` installed
    `com.paulfecto.AgentPulse.watchkitapp`, and `devicectl device process
    launch` launched the Watch app.
- runtime proof:
  - local `http://127.0.0.1:55110/health/get` returned
    `codexAppServer: "connected"` with `remoteAccess.mode: "edge"` and
    `publicUrl: "https://beta.dope-ai.kr/agent-pulse"`.
  - process proof showed helper process
    `/opt/homebrew/bin/node apps/helper/dist/dev-server.js` with child
    `/Applications/Codex.app/Contents/Resources/codex app-server`; no
    `/tmp/fake-bin/codex` process was present.
  - authenticated `/watch/summary` returned 12 threads, all provider `codex`,
    with `canOpenOnMac: false`.
  - authenticated transcript checks returned full default transcripts for
    Codex-visible rows; examples included `ChemToS` with 52 loaded messages and
    an older page of 10 messages, and `agent pulse` with 180 loaded messages
    and an older page of 10 messages.
- current live-route blocker:
  - `https://beta.dope-ai.kr/agent-pulse/health/get` returns HTTP 200 with the
    `project-manager` HTML shell instead of Agent Pulse JSON, so the shared
    beta edge has not applied the `/agent-pulse` route yet.
  - configured SSH host `macmini-3.local` does not resolve from this machine;
    visible LAN SSH hosts rejected available noninteractive credentials, so
    the live macmini3 shared edge could not be reloaded from this run.
  - result: local Watch/helper parity is fixed and installed, but cellular or
    off-LAN Watch access through `https://beta.dope-ai.kr/agent-pulse` remains
    blocked until the macmini3 shared edge route is applied and reloaded.

## Frontier routing

- status: single-lane-not-escalated.
- task class: implementation
- arbiter: codex
