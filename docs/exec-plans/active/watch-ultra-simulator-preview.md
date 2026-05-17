# Execution plan

Add an Agent Pulse Apple Watch Ultra simulator preview path equivalent to the
accepted LM Bar Watch proof surface.

- status: complete
- owner: codex
- started: 2026-05-16

## Target behavior

- A repo-owned command builds the native Agent Pulse watchOS app for the
  watchOS simulator.
- The command boots a dedicated Apple Watch Ultra-family simulator, installs
  the app, launches deterministic DEBUG preview states, and captures:
  - raw `simctl` Watch screenshots for pairing, summary, attention inbox,
    attention detail, attention actions, start thread, thread detail, routed
    messages/artifacts, routed reply/actions, empty, offline, error, and
    revoked states
  - actual `Simulator` app window/body screenshots for the same states, proving
    the rounded Ultra frame rather than a cropped square framebuffer
- The preview does not require a live helper session, real browser, physical
  Watch, Codex Desktop IPC, Project Manager, APNs credentials, or production
  runtime access.

## Inputs and constraints

- Use the LM Bar accepted proof pattern as the reference: raw Watch simulator
  screenshots plus actual `Simulator` app window/body screenshots.
- Keep preview data DEBUG-only and deterministic.
- Do not touch Codex Desktop, the live helper, Project Manager, APNs
  credentials, or the physical Watch.
- Use a dedicated reset simulator named `Agent Pulse Watch Ultra Preview` so
  existing shared Ultra simulator state does not leak into the proof.

## Owning layer

- Owner lane: `codex`
- Product layer: native watchOS app preview state and repo verification scripts.
- Runtime layer: local Xcode watchOS simulator only.

## Planned write set

- `docs/exec-plans/active/watch-ultra-simulator-preview.md`
- `apps/watchos/AgentPulseWatch/AgentPulseWatch/AgentPulseStore.swift`
- `scripts/verify/run_watch_ultra_simulator_preview.sh`
- `scripts/verify/test_watch_ultra_simulator_preview_contract.sh`
- large-file cohesion watchlist, preserve-only unless touched by unrelated
  active work:
  - `apps/helper/src/claude/claude-code.ts`
  - `apps/helper/src/codex/app-server-chat.test.ts`
  - `apps/helper/src/codex/app-server-chat.ts`
  - `apps/helper/src/codex/codex-mirror.test.ts`
  - `apps/helper/src/codex/codex-mirror.ts`
  - `apps/helper/src/copilot/copilot.ts`
  - `apps/helper/src/server/agent-pulse-server.test.ts`
  - `apps/helper/src/server/agent-pulse-server.ts`
  - `apps/helper/src/server/cloudflare-tunnel.ts`
  - `apps/tablet/src/App.test.tsx`
  - `apps/tablet/src/App.tsx`
  - `apps/tablet/src/Dashboard.tsx`
  - `apps/tablet/src/Sidebar.tsx`
  - `apps/tablet/src/ThreadView.tsx`
  - `apps/tablet/src/api.ts`
  - `apps/tablet/src/threadRendering.test.ts`
  - `packages/shared/src/index.ts`

## File cohesion plan

- file: `apps/watchos/AgentPulseWatch/AgentPulseWatch/AgentPulseStore.swift`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/watchos/AgentPulseWatch/AgentPulseWatch/AttentionStore.swift`
- file: `apps/helper/src/claude/claude-code.ts`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/helper/src/claude/claude-code-transport.ts`
- file: `apps/helper/src/codex/app-server-chat.test.ts`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/helper/src/codex/app-server-turns.test.ts`
- file: `apps/helper/src/codex/app-server-chat.ts`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/helper/src/codex/app-server-turns.ts`
- file: `apps/helper/src/codex/codex-mirror.test.ts`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/helper/src/codex/codex-mirror-events.test.ts`
- file: `apps/helper/src/codex/codex-mirror.ts`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/helper/src/codex/codex-mirror-events.ts`
- file: `apps/helper/src/copilot/copilot.ts`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/helper/src/copilot/copilot-transport.ts`
- file: `apps/helper/src/server/agent-pulse-server.test.ts`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/helper/src/server/agent-pulse-routes.test.ts`
- file: `apps/helper/src/server/agent-pulse-server.ts`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/helper/src/server/agent-pulse-routes.ts`
- file: `apps/helper/src/server/cloudflare-tunnel.ts`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/helper/src/server/cloudflare-tunnel-supervisor.ts`
- file: `apps/tablet/src/App.test.tsx`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/tablet/src/AppShell.test.tsx`
- file: `apps/tablet/src/App.tsx`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/tablet/src/AppShell.tsx`
- file: `apps/tablet/src/Dashboard.tsx`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/tablet/src/DashboardPanels.tsx`
- file: `apps/tablet/src/Sidebar.tsx`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/tablet/src/SidebarSections.tsx`
- file: `apps/tablet/src/ThreadView.tsx`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/tablet/src/ThreadConversationView.tsx`
- file: `apps/tablet/src/api.ts`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/tablet/src/api-client.ts`
- file: `apps/tablet/src/threadRendering.test.ts`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/tablet/src/threadRendering-focused.test.ts`
- file: `packages/shared/src/index.ts`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `packages/shared/src/contracts.ts`

## Interface or contract changes

- No production helper API or Watch network contract changes.
- Add DEBUG-only environment variables:
  - `AGENT_PULSE_WATCH_PREVIEW_FIXTURE=1`
  - `AGENT_PULSE_WATCH_PREVIEW_STATE=pairing|summary|attention|attentionDetail|start|detail|empty|offline|error|revoked`
- The preview fixture uses the public beta URL in display/session data but does
  not make network calls.

## Acceptance criteria

- DEBUG fixture mode renders the Watch scenario matrix without network access:
  pairing, summary, attention inbox, attention detail, attention actions, start
  thread, thread detail with context, message/artifact rows, reply/actions,
  empty, offline, error, and revoked.
- Preview script explicitly targets Apple Watch Ultra-family simulators.
- Preview script captures both raw watch screenshots and actual Simulator
  window/body screenshots.
- Contract check passes.
- Xcode simulator preview build/run passes or records an environment blocker
  with exact output.

## TDD plan

- smallest failing check: `bash scripts/verify/test_watch_ultra_simulator_preview_contract.sh`
- fixture or seam: DEBUG-only `AgentPulseStore` simulator preview state, with
  deterministic summary and transcript data.
- green condition: contract check passes and
  `scripts/verify/run_watch_ultra_simulator_preview.sh` produces all four
  screenshots from an Apple Watch Ultra-family simulator.
- refactor guard: `git diff --check`, contract check, and the Xcode simulator
  preview script.

## Validation matrix

| Surface | Check | Proof |
| --- | --- | --- |
| Contract | `test_watch_ultra_simulator_preview_contract.sh` | preview env, script, artifacts, and Ultra targeting are present |
| Watch build | `run_watch_ultra_simulator_preview.sh` | Xcode Debug watchOS simulator build succeeds |
| Raw Watch pixels | `simctl io screenshot` | all scenario captures are `410x502` or `422x514` Ultra-family screenshots |
| Actual simulator body | `screencapture` of `Simulator` window | rounded Ultra simulator window/body is captured for every scenario |

## Deploy/runtime impact

- No deployment or live runtime change.
- No APNs, physical Watch, Codex Desktop, or Project Manager interaction.
- The dedicated simulator is reset by the preview script before use.

## Review risks and open questions

- Risk: a shared simulator can keep stale notification permission prompts.
  Resolution: use and reset a dedicated Agent Pulse preview simulator.
- Risk: raw framebuffers alone can hide rounded-body clipping. Resolution:
  capture the actual Simulator window/body as a retained artifact.

## Validation evidence

- Reopened on 2026-05-16 after the user required a fuller Watch Ultra
  simulator proof matrix instead of build-only proof.
- `bash scripts/verify/test_watch_ultra_simulator_preview_contract.sh`
  passed after adding routed scenario states for pairing, attention, start
  thread, thread-detail messages, thread-detail actions, offline, error, and
  revoked states.
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer bash scripts/verify/run_watch_ultra_simulator_preview.sh`
  passed after installing the watch app into dedicated simulator
  `Agent Pulse Watch Ultra Preview (BF2900A5-B4B9-45C1-9EAD-21A421C6D640)`.
- Final proof generated raw `simctl` Watch screenshots plus actual Simulator
  window/body captures for 13 scenario surfaces:
  pairing, summary, attention inbox, attention detail, attention actions,
  start thread, thread detail context, thread detail messages/artifacts,
  thread detail reply/actions, empty, offline, error, and revoked.
- `git diff --check` passed.
- `bash scripts/verify/test_watch_ultra_simulator_preview_contract.sh`
  passed.
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer bash scripts/verify/run_watch_ultra_simulator_preview.sh`
  passed.
- Preview used dedicated simulator
  `Agent Pulse Watch Ultra Preview (watchOS.26.4)`.
- Raw `simctl` Watch screenshots validated at `422x514`.
- Actual `Simulator` window/body screenshots validated at `628x824`.
- The first shared-simulator attempt exposed a notification-permission prompt;
  the final implementation uses a dedicated reset preview simulator and
  suppresses DEBUG preview push registration.

## TDD evidence

- red signal: initial full preview run exposed the wrong visible state, a
  notification permission prompt from shared simulator state, instead of the
  Agent Pulse summary/detail UI.
- red artifact: first inspected captures showed the watchOS notification
  permission sheet.
- green result: final preview run passed and produced summary/detail raw
  screenshots plus actual Simulator window/body captures from the dedicated
  reset Ultra preview simulator.
- green artifact: `docs/exec-plans/active/watch-ultra-simulator-preview-screenshots/summary.png`
  and `docs/exec-plans/active/watch-ultra-simulator-preview-screenshots/thread-detail.png`
- refactor verification: `git diff --check` and
  `bash scripts/verify/test_watch_ultra_simulator_preview_contract.sh` passed.

## Review evidence

- reviewer: `codex`
- scope: DEBUG-only Watch preview seam and repo-owned Xcode simulator proof
  script.
- result: no production API/runtime behavior changed.

## Completion status

- state: complete

## Frontier routing

- status: single-lane-not-escalated
- task class: implementation
- arbiter: codex

retain-artifact: docs/exec-plans/active/watch-ultra-simulator-preview-screenshots/summary.png
retain-artifact: docs/exec-plans/active/watch-ultra-simulator-preview-screenshots/pairing.png
retain-artifact: docs/exec-plans/active/watch-ultra-simulator-preview-screenshots/attention.png
retain-artifact: docs/exec-plans/active/watch-ultra-simulator-preview-screenshots/attention-detail.png
retain-artifact: docs/exec-plans/active/watch-ultra-simulator-preview-screenshots/attention-detail-actions.png
retain-artifact: docs/exec-plans/active/watch-ultra-simulator-preview-screenshots/start-thread.png
retain-artifact: docs/exec-plans/active/watch-ultra-simulator-preview-screenshots/thread-detail.png
retain-artifact: docs/exec-plans/active/watch-ultra-simulator-preview-screenshots/thread-detail-messages.png
retain-artifact: docs/exec-plans/active/watch-ultra-simulator-preview-screenshots/thread-detail-actions.png
retain-artifact: docs/exec-plans/active/watch-ultra-simulator-preview-screenshots/empty.png
retain-artifact: docs/exec-plans/active/watch-ultra-simulator-preview-screenshots/offline.png
retain-artifact: docs/exec-plans/active/watch-ultra-simulator-preview-screenshots/error.png
retain-artifact: docs/exec-plans/active/watch-ultra-simulator-preview-screenshots/revoked.png
retain-artifact: docs/exec-plans/active/watch-ultra-simulator-preview-screenshots/summary-simulator-window.png
retain-artifact: docs/exec-plans/active/watch-ultra-simulator-preview-screenshots/pairing-simulator-window.png
retain-artifact: docs/exec-plans/active/watch-ultra-simulator-preview-screenshots/attention-simulator-window.png
retain-artifact: docs/exec-plans/active/watch-ultra-simulator-preview-screenshots/attention-detail-simulator-window.png
retain-artifact: docs/exec-plans/active/watch-ultra-simulator-preview-screenshots/attention-detail-actions-simulator-window.png
retain-artifact: docs/exec-plans/active/watch-ultra-simulator-preview-screenshots/start-thread-simulator-window.png
retain-artifact: docs/exec-plans/active/watch-ultra-simulator-preview-screenshots/thread-detail-simulator-window.png
retain-artifact: docs/exec-plans/active/watch-ultra-simulator-preview-screenshots/thread-detail-messages-simulator-window.png
retain-artifact: docs/exec-plans/active/watch-ultra-simulator-preview-screenshots/thread-detail-actions-simulator-window.png
retain-artifact: docs/exec-plans/active/watch-ultra-simulator-preview-screenshots/empty-simulator-window.png
retain-artifact: docs/exec-plans/active/watch-ultra-simulator-preview-screenshots/offline-simulator-window.png
retain-artifact: docs/exec-plans/active/watch-ultra-simulator-preview-screenshots/error-simulator-window.png
retain-artifact: docs/exec-plans/active/watch-ultra-simulator-preview-screenshots/revoked-simulator-window.png
