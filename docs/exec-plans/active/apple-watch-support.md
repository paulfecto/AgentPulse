# Execution plan

Build Agent Pulse Apple Watch v1 as a glance-and-act native watch surface backed by the existing trusted helper.

## Target behavior

- The helper can persist watch APNs settings, validate the configured APNs key material, and send minimal APNs pushes through Node built-ins only.
- Paired watch devices can register and delete their APNs token metadata without exposing transcripts or raw provider state.
- Existing status transitions notify watches once for finished, errored, and attention states.
- Watch clients can read a compact summary, read watch-safe thread details, send short replies, stop runs, and open Codex on the Mac.
- The tablet settings surface can enable/disable watch notifications and manage APNs configuration.
- A native SwiftUI watchOS v1 scaffold lives under `apps/watchos/AgentPulseWatch`, not the ignored `Watch app/` directory.

## Inputs and constraints

- User requested implementation of the Apple Watch support plan in one pass.
- Work only on `main`.
- Run Node/helper validation only inside Docker.
- Clean up disposable containers and temporary validation state after testing.
- Do not add a third-party APNs dependency; use Node `http2` and `crypto`.
- Notification content must stay minimal and exclude transcript text/raw provider data.
- Approval decisions are out of v1 scope; attention notifications open the thread.
- WatchOS build/signing validation is separate from Docker because Xcode and Apple signing are host/toolchain dependent.

## Owning layer

- Owner: `codex`
- Product layers: shared contracts, helper server/auth/settings, tablet settings UI, and native watchOS client.
- Runtime owner remains the helper as trusted backend; watch clients never talk directly to providers.

## Planned write set

- `docs/exec-plans/active/apple-watch-support.md`
- `docs/exec-plans/active/task-claim.json`
- `docs/exec-plans/active/resume-state.json`
- `docs/exec-plans/active/heartbeat.jsonl`
- `docs/exec-plans/active/HARNESS_PROGRESS_LEDGER.html`
- `docs/exec-plans/active/TEAM_PROGRESS_LEDGER.html`
- `docs/exec-plans/completed/agentos-downstream-adoption.md`
- `packages/shared/src/index.ts`
- `apps/helper/src/server/settings.ts`
- `apps/helper/src/auth/pairing.ts`
- `apps/helper/src/server/watch-push.ts`
- `apps/helper/src/server/watch-push.test.ts`
- `apps/helper/src/server/agent-pulse-server.ts`
- `apps/helper/src/server/agent-pulse-server.test.ts`
- `apps/tablet/src/api.ts`
- `apps/tablet/src/App.tsx`
- `apps/tablet/src/styles.css`
- `apps/watchos/AgentPulseWatch/**`

## File cohesion plan

These files already exceed the harness size threshold in the current repo. This task keeps changes local to their existing ownership rather than decomposing unrelated source as part of watch support.

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
- file: `apps/tablet/src/api.ts`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`

## Interface or contract changes

- Add shared watch notification settings and watch summary schemas.
- Extend device records with watch push token bundle/environment metadata.
- Add helper admin routes for watch notification settings and validation.
- Add `GET /watch/summary`.
- Add a watch-specific 500-character message guard using the watch client header.
- Preserve existing pairing, thread, stop, and open endpoints for v1.

## Acceptance criteria

- APNs JWT generation and HTTP/2 request shaping are covered by tests.
- Disabled or incomplete APNs config does not throw and records a useful error.
- Watch push registration stores token, bundle id, environment, and timestamp.
- Revoked devices are excluded from push attempts.
- Finished, errored, and attention transitions enqueue exactly one push per status transition.
- Notification payloads contain only minimal fields and no transcript/raw provider data.
- `GET /watch/summary` returns compact thread/server/remote state.
- Watch messages over 500 characters are rejected server-side.
- Tablet settings can save and check watch notification config.
- Native watchOS source and setup README are present under `apps/watchos/AgentPulseWatch`.

## TDD plan

- smallest failing check: Docker Vitest coverage for APNs helpers, watch token persistence, status transition push delivery, compact summary, and watch message length before relying on implementation.
- red signal: missing APNs sender behavior, missing watch token metadata, duplicate transition pushes, non-compact summary payloads, and over-500-character watch messages should fail these tests.
- fixture or seam: use in-memory pairing stores, injected APNs sender, mocked HTTP/2 client, and existing helper route harnesses.
- green condition: Docker `pnpm test` passes with the new watch behavior.
- refactor guard: Docker `pnpm typecheck` and Docker `pnpm build` pass.

## Validation matrix

| Surface | Check | Proof |
| --- | --- | --- |
| APNs helper | Docker `pnpm test -- --run apps/helper/src/server/watch-push.test.ts` or full `pnpm test` | JWT, request, payload, disabled config behavior |
| Helper routes | Docker `pnpm test` | token registration, summary, transition delivery, watch message limit |
| Type contracts | Docker `pnpm typecheck` | shared/helper/tablet TypeScript contracts compile |
| Build output | Docker `pnpm build` | helper/tablet/shared bundles compile |
| AgentOS state | Docker AgentOS gates | active plan and adapter remain valid |
| Watch app | Xcode watchOS simulator build/manual checks | separate host validation due signing/toolchain |

## Deploy/runtime impact

- Helper settings gain optional APNs credentials and health fields.
- Devices gain optional watch push metadata.
- APNs calls occur only when watch notifications are enabled and configured.
- Push payloads reveal only status kind, thread id, server name, and short alert copy.
- Existing tablet and helper behavior should remain unchanged for non-watch clients.

## Review risks and open questions

- Real APNs delivery requires user-supplied Apple Team ID, Key ID, `.p8` key path, bundle id, and sandbox/production selection.
- watchOS signing cannot be proven in Docker; document exact host-side build expectations.
- Manual `.xcodeproj` generation is intentionally avoided unless Xcode tooling is available; the checked-in SwiftUI source is the durable product surface.

## Validation evidence

- Docker targeted watch/helper/tablet check passed: `pnpm exec vitest run apps/helper/src/server/watch-push.test.ts apps/helper/src/server/agent-pulse-server.test.ts apps/tablet/src/App.test.tsx` passed 3 files / 173 tests.
- Docker full test gate passed after final code changes: `pnpm test` passed 34 files / 449 tests.
- Docker type/build gate passed after final code changes: `pnpm typecheck` passed and `pnpm build` passed.
- Docker AgentOS gate initially caught stale upstream and ledger state; `../agentOS-upstream-main` was restored to `11274a64f909ea1ee0a3c92455b4d291ba8ea344`.
- Docker AgentOS final gate passed: `verify_harness.py`, `verify_protocol.py`, and `verify_exec_plan.py --stage start`.
- WatchOS host build was not run because the user required normal repo validation to stay Docker-only and watchOS signing/building requires Xcode plus Apple provisioning outside Docker. The checked-in README documents the host-side Xcode checks.

## TDD evidence

- red signal: first Docker targeted run exposed two regressions: the admin settings response shape test needed the new `watchNotifications` field, and the tablet had duplicate `Check setup` button names.
- green result: targeted Docker watch/helper/tablet tests passed after adding the settings expectation and renaming the watch APNs check action.
- refactor verification: Docker `pnpm typecheck` caught optional legacy settings merge typing; after fixing default normalization, Docker `pnpm typecheck` and Docker `pnpm build` passed.

## Review evidence

- reviewer: `codex` using `.agents/skills/harness-reviewer`.
- one source of truth: shared schemas in `packages/shared/src/index.ts` own watch settings and summary contracts; helper settings own APNs credentials; watch source consumes helper routes only.
- canonical mutation result: watch APNs token metadata mutates only paired device records; helper settings mutate only through admin watch-notification routes.
- projection stability: tablet settings is the only web projection changed; watchOS source is isolated under `apps/watchos/AgentPulseWatch`; no AgentOS product source was merged.
- module locality: APNs JWT/HTTP2 complexity is behind `apps/helper/src/server/watch-push.ts`, leaving server route/status hooks narrow.
- unresolved findings: no blocking repo validation findings; Xcode signing/build verification remains a manual external check.

## Completion status

- state: validation-complete.
- ready for merge or deploy: yes for the checked-in helper/tablet/watch source changes; host-side watchOS signing/build remains external manual validation.

## Frontier routing

- status: single-lane-not-escalated.
- task class: implementation
- arbiter: codex
