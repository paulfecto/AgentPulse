# Watch Thread Detail Release

## Objective

Fix the Watch thread-detail flow where tapping a thread loads and then shows no
messages. Prove the fix through public-route/API checks, Docker validation,
Xcode Watch validation, commit/push on `main`, and a local TestFlight upload.

## Scope

- Watch transcript fetch/decode/state handling.
- Helper transcript contract only if required by the failing Watch path.
- Local TestFlight archive/upload script, no GitHub Actions.
- Preserve Codex Desktop safety: no IPC/open/focus/restart/kill, and keep the
  beta runtime using `AGENT_PULSE_DISABLE_CODEX_DESKTOP=1`.
- Preserve unrelated existing AgentOS active-plan state.

## Acceptance Criteria

- Tapping a Watch thread leaves a non-empty, decoded transcript in Watch state
  whenever the helper returns visible messages.
- Watch detail reports a concrete server/decode error instead of silently
  rendering an empty state when payload shape is wrong.
- Public `https://beta.dope-ai.kr/agent-pulse` transcript endpoints return
  AgentPulse JSON, not Project Manager HTML.
- Docker `pnpm test`, `pnpm typecheck`, and `pnpm build` pass.
- Watch simulator/Xcode build passes.
- Scoped changes are committed and pushed to `origin/main`.
- TestFlight upload is attempted locally through Xcode tooling with API-key
  environment variables, never through a GitHub Action.

## Evidence Log

- 2026-05-17: Started from `main...origin/main` with unrelated dirty
  harness/active-plan state already present.
- 2026-05-17: Code inspection confirmed the Watch currently fetches
  `GET /threads/:threadId/transcript?limit=40`, not the legacy `view=watch`
  summary endpoint.
- 2026-05-17: Diagnosis found the helper's default Codex transcript path uses a
  recent-turn snapshot. Watch detail can therefore receive an empty/blank
  limited window when the latest turns contain only internal activity even
  though the full Codex history has visible conversation messages.
- 2026-05-17: Patched Watch detail fetches to request
  `history=full`, and patched the helper transcript route to honor that query
  through `appServer.readFullTranscript` while leaving normal list/poll reads on
  the recent snapshot path.
- 2026-05-17: Repaired the live shared beta route so
  `https://beta.dope-ai.kr/agent-pulse/health/get` returns AgentPulse JSON
  instead of Project Manager HTML. The authenticated Watch path then returned
  32 summary threads and 40 visible transcript messages for the selected
  public-route thread detail request.

## Validation Log

- 2026-05-17: Docker targeted Vitest passed:
  `pnpm exec vitest run apps/helper/src/server/agent-pulse-server.test.ts -t "full Codex history for Watch detail"`.
- 2026-05-17: Docker full product gate passed in `node:22-bookworm`:
  `pnpm test` reported 41 files / 557 tests passed, then `pnpm typecheck`
  passed, then `pnpm build` passed for shared, tablet, and helper.
- 2026-05-17: Watch simulator build passed with signing disabled:
  `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project apps/watchos/AgentPulseWatch/AgentPulseWatch.xcodeproj -scheme AgentPulseWatch -configuration Debug -destination 'generic/platform=watchOS Simulator' CODE_SIGNING_ALLOWED=NO build`.
- 2026-05-17: Public route health passed:
  `curl https://beta.dope-ai.kr/agent-pulse/health/get` returned
  `content-type: application/json` with `codexAppServer: "connected"`.
- 2026-05-17: Authenticated public Watch detail proof passed:
  `/watch/summary` returned 32 threads, then
  `/threads/019e3533-24d8-7111-ac36-809ce2488734/transcript?limit=40&history=full`
  returned 40 transcript messages and 40 visible text messages.
- 2026-05-17: Public stress probe passed 20 iterations against
  `https://beta.dope-ai.kr/agent-pulse`: `/health/get`, `/watch/summary`,
  and full transcript detail all returned JSON, and every transcript probe had
  visible messages.
- 2026-05-17: Pushed scoped code fix to `origin/main` at
  `e2920cb86415952b7a0ce9b480f0b56e24dd7c3b`.
- 2026-05-17: Deployed macmini3 AgentPulse edge checkout to
  `e2920cb86415952b7a0ce9b480f0b56e24dd7c3b`; `agentpulse-beta-edge`
  was healthy on `127.0.0.1:4355`, and the public route again returned
  AgentPulse JSON with `codexAppServer: "connected"`.
- 2026-05-17: Post-deploy authenticated Watch detail proof passed:
  `/watch/summary` returned 32 threads and the selected transcript returned
  40 messages / 40 visible text messages through
  `https://beta.dope-ai.kr/agent-pulse`.
- 2026-05-17: Local TestFlight archive succeeded for build `202605172102`.
  The first API-key export path failed with a cloud signing permission/profile
  error, then local Xcode-account export/upload succeeded without using GitHub
  Actions.
- 2026-05-17: App Store Connect build API confirmed app id `6770043269`
  (`Agent Pulse Watch`, bundle `com.paulfecto.AgentPulse`) has build
  `202605172102` uploaded at `2026-05-17T05:07:11-07:00` with
  `processingState: "VALID"` and `expired: false`.

## Completion State

- status: complete
