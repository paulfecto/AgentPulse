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

## Validation Log

- Passed: Docker `pnpm test` with 555 tests.
- Passed: Docker `pnpm typecheck`.
- Passed: Docker `pnpm build`.
- Passed: Watch simulator Xcode build.
- Passed: signed physical Watch build.
- Passed: physical Watch install and launch.
- Passed: local relayed helper authenticated Watch summary returns Codex-visible
  pinned threads with edited titles.
- Pending: push/deploy relay topology to macmini3 public route, then bootstrap or
  refresh the physical Watch session against the relayed helper device.

## Completion State

In progress.
