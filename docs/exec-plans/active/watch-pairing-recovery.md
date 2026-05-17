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

## Changes

- Map helper auth errors `unknown-device`, `revoked`, `invalid`, and `missing`
  to a Watch pairing-reset error.
- Clear the Watch Keychain session locally on pairing-reset errors and return
  the app to the pairing screen with a concrete "fresh PIN" message.
- Add a macmini3 GitHub workflow/script to mint a live beta pairing PIN through
  the helper using existing `MACMINI3_*` secrets, rotating only the isolated
  beta admin credentials if the saved beta admin passcode is unavailable.

## Validation Log

- Passed: Docker `pnpm test`.
- Passed: Docker `pnpm typecheck`.
- Passed: Docker `pnpm build`.
- Passed: Watch simulator Xcode build.
- Passed: signed physical Watch build.
- Passed: physical Watch install and launch.
- Pending: live pairing PIN workflow dispatch and authenticated Watch summary
  proof after the user enters the fresh PIN on the physical Watch.

## Completion State

In progress.
