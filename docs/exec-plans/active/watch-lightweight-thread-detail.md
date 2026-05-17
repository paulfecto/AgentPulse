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

## Validation Log

- PASS: Docker targeted helper tests:
  `docker run --rm -v "$PWD":/work -v /work/node_modules -w /work node:22-bookworm bash -lc 'corepack enable && corepack prepare pnpm@10.28.2 --activate && pnpm install --frozen-lockfile >/dev/null && pnpm exec vitest run apps/helper/src/server/agent-pulse-server.test.ts -t "Watch detail|Watch send responses|full Codex history"'`
  passed with 4 tests run.
- PASS: Docker full product gates:
  `docker run --rm -v "$PWD":/work -v /work/node_modules -w /work node:22-bookworm bash -lc 'corepack enable && corepack prepare pnpm@10.28.2 --activate && pnpm install --frozen-lockfile >/dev/null && pnpm test && pnpm typecheck && pnpm build'`
  passed. `pnpm test` reported 41 files and 559 tests passed; `pnpm
  typecheck` completed; `pnpm build` completed helper/tablet builds.
- PASS: Watch simulator build:
  `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project apps/watchos/AgentPulseWatch/AgentPulseWatch.xcodeproj -scheme AgentPulseWatch -configuration Debug -destination 'generic/platform=watchOS Simulator' CODE_SIGNING_ALLOWED=NO build`
  completed with `** BUILD SUCCEEDED **`.
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

- status: in_progress
