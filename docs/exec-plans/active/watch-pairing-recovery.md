# Watch Pairing Recovery

## Objective

Make the public beta Watch flow recover from stale device sessions and prove the
current `https://beta.dope-ai.kr/agent-pulse` route is returning AgentPulse API
JSON.

## Scope

- Watch client auth/session error handling.
- Live public route probes for health and Watch auth failure shape.
- Xcode build proof for the Watch target.
- No Project Manager changes.
- No Codex Desktop IPC/focus/restart/kill.

## Evidence

- 2026-05-17: `GET https://beta.dope-ai.kr/agent-pulse/health/get` returned
  `HTTP 200`, `content-type: application/json`, and
  `codexAppServer: "connected"`.
- 2026-05-17: `GET https://beta.dope-ai.kr/agent-pulse/watch/summary` with a
  fake device session returned `HTTP 401` JSON:
  `{"error":"unknown-device"}`.
- 2026-05-17: Code inspection showed the Watch store only cleared pairing for
  "revoked", so `unknown-device` could leave the Watch stuck with stale
  Keychain credentials.
- 2026-05-17: Docker `pnpm test`, `pnpm typecheck`, and `pnpm build` passed in
  an ephemeral container copy with the host repo mounted read-only. Test result:
  41 files / 553 tests passed.
- 2026-05-17: Watch simulator build passed with signing disabled using
  `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild ...`
  for `generic/platform=watchOS Simulator`.
- 2026-05-17: Physical Watch build passed for `Paul's Apple Watch`
  (`00008301-2084A531140BC02E`) with `DEVELOPMENT_TEAM=H86Z687FT6`.
- 2026-05-17: Installed and launched the fixed build on the paired physical
  Watch through `xcrun devicectl`; install and launch both returned
  `outcome: "success"`.
- 2026-05-17: Pairing workflow run `25987803883` minted beta PIN `341777`,
  proving the public helper could create a device session, but authenticated
  `/watch/summary` showed zero Watch threads and `/threads/list` showed only
  stale Claude rows.
- 2026-05-17: Local Codex SQLite state on the Codex desktop Mac contained the
  expected active/pinned Codex threads, including the current AgentPulse thread.
  This proved the public route was pointed at the wrong helper state.
- 2026-05-17: Restored the documented macmini3 topology: public shared edge ->
  Docker nginx edge on `4355` -> Mac helper relay on `127.0.0.1:55112` -> Codex
  desktop Mac helper on `55110`.
- 2026-05-17: Local Watch-authenticated `GET http://127.0.0.1:55110/watch/summary`
  returned `HTTP 200` JSON in about 3.2s with 32 Codex Watch threads and edited
  pinned titles such as `agent pulse`, `management tool`, `foundry`, and `vox`.
- 2026-05-17: The helper initially hung while reading several 100MB+ Codex
  rollout files and reconciling every recently touched idle thread. Added a
  bounded rollout status tail and skipped transcript reconciliation for recent
  idle list rows unless app-server reports the thread as loaded or non-idle.
- 2026-05-17: Docker `pnpm test`, `pnpm typecheck`, and `pnpm build` passed in
  an ephemeral container copy with the host repo mounted read-only. Test result:
  41 files / 555 tests passed.
- 2026-05-17: Removed transcript reads from the list/poll path entirely. Watch
  summary now trusts app-server live statuses for list state and keeps full
  transcript reads on explicit thread detail requests.
- 2026-05-17: Added a bounded file-preview basename search guard. The helper no
  longer recursively scans `source-cache`/large data roots when decorating
  transcript file references for Watch/tablet previews.
- 2026-05-17: Local helper restart proof stayed responsive across repeated
  health checks for 26 seconds, returned authenticated Watch summary with 32
  real Codex-visible threads, and the macmini relay on `127.0.0.1:55112`
  returned `codexAppServer: "connected"`.
- 2026-05-17: Public route proof:
  `https://beta.dope-ai.kr/agent-pulse/health/get` returned AgentPulse JSON with
  `codexAppServer: "connected"`;
  authenticated `https://beta.dope-ai.kr/agent-pulse/watch/summary` returned 32
  threads with edited pinned titles (`CoWorkOS`, `commerceOS`,
  `management tool`, `foundry`, `vox`, ...); `/thread/open` returned `403` with
  `Codex desktop control is disabled for this Agent Pulse runtime.`
- 2026-05-17: Public stress proof passed 30 iterations across public health,
  authenticated Watch summary, and tablet shell. Every API response stayed JSON
  and Project Manager health remained `healthy`.
- 2026-05-17: Docker `pnpm test`, `pnpm typecheck`, and `pnpm build` passed in
  an ephemeral container copy with the host repo mounted read-only. Test result:
  41 files / 556 tests passed.
- 2026-05-17: Initial physical Watch bootstrap/install retry was blocked by
  Apple CoreDevice transport (`CoreDeviceError 4000` / tunnel timeout). A later
  `devicectl device info details` showed Paul’s Apple Watch paired, Developer
  Mode enabled, and tunnel state `connected`.
- 2026-05-17: Retried physical Watch launch with forced bootstrap values for
  `https://beta.dope-ai.kr/agent-pulse`; `devicectl` launched
  `com.paulfecto.AgentPulse.watchkitapp` successfully. Helper keychain record
  for the Watch device is present, not revoked, has fresh `lastSeenAt`, and has
  a sandbox Watch push token for `com.paulfecto.AgentPulse.watchkitapp`.
- 2026-05-17: Public transcript proof for a real Codex-visible thread returned
  `application/json`, 90 visible messages, `sendState: "Ready"`, and no raw
  provider payload marker. Public Watch attention endpoint returned valid JSON.

## Changes

- Map helper auth errors `unknown-device`, `revoked`, `invalid`, and `missing`
  to a Watch pairing-reset error.
- Clear the Watch Keychain session locally on pairing-reset errors and return
  the app to the pairing screen with a concrete "fresh PIN" message.
- Add a macmini3 GitHub workflow/script to mint a live beta pairing PIN through
  the helper using existing `MACMINI3_*` secrets, rotating only the isolated
  beta admin credentials if the saved beta admin passcode is unavailable.
- Point the macmini3 Docker edge and watchdog checks at the existing Mac helper
  relay on `55112` instead of starting a second helper on macmini3.
- Stop reading full/recent idle Codex transcripts during list/summary
  reconciliation, and bound rollout status reads to keep Watch summary
  responsive with very large Codex session logs.
- Skip expensive bare-filename file-preview searches in large/generated data
  roots such as `source-cache`, so opening full conversations cannot block the
  helper event loop.

## Validation Log

- Passed: Docker `pnpm test` with 556 tests.
- Passed: Docker `pnpm typecheck`.
- Passed: Docker `pnpm build`.
- Passed: Watch simulator Xcode build.
- Passed: signed physical Watch build.
- Passed: physical Watch install and launch.
- Passed: local relayed helper authenticated Watch summary returns Codex-visible
  pinned threads with edited titles.
- Passed: public beta route returns AgentPulse JSON and authenticated Watch
  summary for `https://beta.dope-ai.kr/agent-pulse`.
- Passed: public route stress loop, 30 iterations, no Project Manager HTML in
  AgentPulse APIs.
- Passed: physical Watch launch with forced public beta bootstrap.
- Passed: helper-side Watch device record recognized the refreshed session and
  stored a Watch push token.
- Not exercised: sending a real reply or stop command from the Watch, because
  that would mutate a real Codex thread. The public authenticated transcript and
  attention surfaces were verified read-only.

## Completion State

Server and physical Watch pairing recovery complete. Remaining APNs delivery
and destructive/action mutations should be verified with an explicit live-test
thread before claiming production notification coverage.
