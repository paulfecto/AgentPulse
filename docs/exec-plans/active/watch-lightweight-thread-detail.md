# Watch Lightweight Thread Detail

## Objective

Make Watch thread detail reliable on low-CPU Apple Watch hardware by returning
only a small visible message window on initial thread open, while preserving the
full-history helper read that prevents empty transcript windows.

## Scope

- Watch transcript page size and request shape.
- Helper transcript windowing for Watch initial loads.
- Validation through Docker, Xcode, public route, commit/push, macmini3 deploy,
  and local TestFlight upload.
- Preserve Codex Desktop safety and avoid GitHub Actions.
- Leave unrelated pre-existing harness/generated dirty files untouched.

## Acceptance Criteria

- Watch initial thread detail requests use full-history lookup but receive only
  the last few visible messages.
- Older-message pagination remains available and uses the same smaller Watch
  page size.
- Watch send/reply responses are also capped to the lightweight Watch window.
- Public `https://beta.dope-ai.kr/agent-pulse` Watch transcript checks return
  JSON with a small message count, not a large transcript payload.
- Docker `pnpm test`, `pnpm typecheck`, and `pnpm build` pass.
- Watch Xcode build passes.
- Scoped changes are committed, pushed, deployed to macmini3, and uploaded to
  TestFlight locally without running GitHub Actions.

## Evidence Log

- 2026-05-17: Started from `main...origin/main` with unrelated AgentOS/generated
  dirty files already present.
- 2026-05-17: Watch detail now requests
  `/threads/:threadId/transcript?limit=8&history=full&window=tail`, so the
  helper still reads full visible history but returns only the latest 8 visible
  messages for initial Watch detail.
- 2026-05-17: Older-message pagination remains available and uses the same
  smaller Watch page size.
- 2026-05-17: Watch reply/send responses from helper routes are capped to the
  same 8-message lightweight transcript window for Watch clients.
- 2026-05-17: Added helper contract tests for strict Watch tail-window
  transcript reads and Watch send-response transcript capping.
- 2026-05-17: Older-message pagination responses are also strictly capped after
  helper transcript transformation, so each Watch scroll-back page remains
  bounded to the requested page size.
- 2026-05-17: Deployed commit `bbc38a9e993c3086718c31fba41da69fd1226c64`
  to macmini3 through the direct SSH deploy path. The route initially reached
  the updated edge, but the helper behind the reverse tunnel was still the old
  local process; after restarting only the Agent Pulse helper LaunchAgent
  `com.agentpulse.helper.55110.beta-edge`, public `/watch/summary` briefly
  drifted to Project Manager HTML and was repaired by re-running the Agent
  Pulse shared-edge reconciler.
- 2026-05-17: Public authenticated proof against
  `https://beta.dope-ai.kr/agent-pulse` returned Watch session `Apple Watch`,
  32 summary threads, selected thread `CoWorkOS`, `transcriptMessages = 8`,
  `visibleMessages = 8`, public URL
  `https://beta.dope-ai.kr/agent-pulse`, and `openOnMac = false`.
- 2026-05-17: Follow-up commit `dee2412` added strict capping to older
  transcript pages after helper transformation. It was pushed to `origin/main`,
  deployed to macmini3 directly over SSH, and the local Agent Pulse helper
  LaunchAgent behind the reverse tunnel was restarted onto the rebuilt helper
  bundle.
- 2026-05-17: TestFlight build `202605172144` was archived from scheme
  `AgentPulseMobile` and uploaded with local Xcode account export/upload. Xcode
  reported `Uploaded AgentPulseMobile`, `Upload succeeded`, and
  `** EXPORT SUCCEEDED **`.

## Validation Log

- PASS: Docker targeted helper tests:
  `docker run --rm -v "$PWD":/work -v /work/node_modules -w /work node:22-bookworm bash -lc 'corepack enable && corepack prepare pnpm@10.28.2 --activate && pnpm install --frozen-lockfile >/dev/null && pnpm exec vitest run apps/helper/src/server/agent-pulse-server.test.ts -t "Watch detail|Watch send responses|full Codex history"'`
  passed with 4 tests run.
- PASS: Docker full product gates:
  `docker run --rm -v "$PWD":/work -v /work/node_modules -w /work node:22-bookworm bash -lc 'corepack enable && corepack prepare pnpm@10.28.2 --activate && pnpm install --frozen-lockfile >/dev/null && pnpm test && pnpm typecheck && pnpm build'`
  passed. `pnpm test` reported 41 files and 559 tests passed; `pnpm
  typecheck` completed; `pnpm build` completed helper/tablet builds.
- PASS: Docker full product gates rerun after older-message capping:
  `pnpm test`, `pnpm typecheck`, and `pnpm build` passed inside
  `node:22-bookworm`; `pnpm test` again reported 41 files and 559 tests
  passed.
- PASS: Watch simulator build:
  `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project apps/watchos/AgentPulseWatch/AgentPulseWatch.xcodeproj -scheme AgentPulseWatch -configuration Debug -destination 'generic/platform=watchOS Simulator' CODE_SIGNING_ALLOWED=NO build`
  completed with `** BUILD SUCCEEDED **`.
- PASS: Public route health after repair:
  `https://beta.dope-ai.kr/agent-pulse/health/get` returned
  `content-type: application/json`, `status = ok`, and
  `codexAppServer = connected`.
- PASS: Public route stress loop: 30 consecutive loops checked
  `/health/get`, authenticated `/watch/summary`,
  `/threads/:threadId/transcript?limit=8&history=full&window=tail`, and
  `/threads/:threadId/transcript/older?before=<oldest>&limit=8`; every API
  response stayed JSON, the selected thread was `CoWorkOS`, tail transcript
  message count stayed `<= 8`, and older-page message count stayed `<= 8`.
- PASS: TestFlight archive/upload:
  `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild
  -project apps/watchos/AgentPulseWatch/AgentPulseWatch.xcodeproj -scheme
  AgentPulseMobile -configuration Release -destination generic/platform=iOS
  -archivePath Build/TestFlight/archives/AgentPulseWatch-20260517-214433.xcarchive
  DEVELOPMENT_TEAM=H86Z687FT6 CURRENT_PROJECT_VERSION=202605172144
  CODE_SIGN_STYLE=Automatic CODE_SIGNING_ALLOWED=YES CODE_SIGNING_REQUIRED=YES
  -allowProvisioningUpdates archive` succeeded, followed by
  `xcodebuild -exportArchive ... -exportOptionsPlist
  Build/TestFlight/exportOptions-20260517-214433-upload.plist
  -allowProvisioningUpdates`; upload succeeded and App Store Connect began
  processing the package.
- PASS: `gh run list --repo paulfecto/AgentPulse --limit 5` showed only older
  `workflow_dispatch` runs; no GitHub Actions run was manually triggered for
  this deployment/upload path.
- BLOCKED (pre-existing harness adapter state): `python3
  ../agentOS/scripts/harness/verify_harness.py --repo "$PWD"` and
  `verify_protocol.py` both failed before product checks because the resolved
  `../agentOS` manifest hash is
  `57b8c0603a99b59ba2fc6cbc37dee5c432662dfa75c1d0b412ba4915eb14ab5a`, while
  `repo_harness.toml` expects
  `d1ea748c25f22a9243672f2791500d71971eb2c5eee8fb43f6f2a11502849a94`.
- BLOCKED (pre-existing active-plan state): `python3
  ../agentOS/scripts/harness/verify_exec_plan.py --repo "$PWD" --stage start`
  failed on stale heartbeat liveness for
  `docs/exec-plans/active/codex-mobile-watch-remote-control.md`, not on this
  Watch lightweight-thread-detail plan.

## Completion State

- status: complete
