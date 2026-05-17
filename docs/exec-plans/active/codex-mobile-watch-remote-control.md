# Execution plan

Bring Codex mobile remote-control semantics to AgentPulse Watch while keeping
the helper as the only public gateway to the local Codex app-server.

- status: complete
- owner: codex
- started: 2026-05-16

## Target behavior

- The Watch can continue existing Codex-visible threads, send follow-ups, stop
  runs, answer `requestUserInput`, and approve all surfaced Codex actions after
  explicit confirmation.
- The Watch can start a new Codex thread from a known helper project, without
  arbitrary path entry.
- The Watch can review compact artifacts from the same helper-visible transcript
  data used by tablet/mobile clients: file references, file changes, images,
  plans, command output, reasoning summaries, model, goal, permissions, and
  active turn state.
- `AGENT_PULSE_DISABLE_CODEX_DESKTOP=1` keeps desktop IPC/open control disabled;
  Codex approval decisions use the spawned app-server bridge in this mode.
- The public Watch pairing target remains `https://beta.dope-ai.kr/agent-pulse`.

## Inputs and constraints

- Execute directly on `main`.
- Preserve existing dirty repo state and do not revert unrelated active plan or
  Watch preview changes.
- Do not expose raw `codex app-server` on the public network.
- Do not restart, focus, kill, or IPC-control Codex Desktop.
- APNs credentials remain outside git.
- Docker is required for Node/helper validation gates.

## Owning layer

- Owner: `codex`
- Product layers: shared Watch/helper contracts, helper routes, Codex app-server
  approval bridge, watchOS data models, Watch navigation, and Watch transcript
  rendering.
- Harness layers: active execution-plan evidence, progress ledger, AgentOS
  checklist, and verification evidence.

## Schema-sync guard

- Local Codex binary: `codex-cli 0.131.0-alpha.9`.
- Local `codex app-server --help` supports `stdio://`, `unix://`,
  `unix://PATH`, and `off`; it does not expose documented `ws://` flags.
- Generated temporary schemas with:
  `/Applications/Codex.app/Contents/Resources/codex app-server generate-json-schema --experimental --out <tmp>`.
- Inspected generated approval/thread/turn methods, including
  `item/commandExecution/requestApproval`, `item/fileChange/requestApproval`,
  `item/tool/requestUserInput`, `item/permissions/requestApproval`,
  `thread/*`, `turn/*`, `turn/diff/updated`,
  `item/commandExecution/terminalInteraction`, and file-change notifications.
- Temporary schema directory was deleted after inspection.

## Planned write set

- `docs/exec-plans/active/codex-mobile-watch-remote-control.md`
- `packages/shared/src/index.ts`
- `packages/shared/src/schemas.test.ts`
- `apps/helper/src/server/agent-pulse-server.ts`
- `apps/helper/src/server/agent-pulse-server.test.ts`
- `apps/watchos/AgentPulseWatch/AgentPulseWatch/AgentPulseClient.swift`
- `apps/watchos/AgentPulseWatch/AgentPulseWatch/AgentPulseStore.swift`
- `apps/watchos/AgentPulseWatch/AgentPulseWatch/Models.swift`
- `apps/watchos/AgentPulseWatch/AgentPulseWatch/ContentView.swift`
- `apps/watchos/AgentPulseWatch/AgentPulseWatch/ThreadDetailView.swift`
- large-file cohesion watchlist, preserve-only unless touched by unrelated
  active work:
  - `apps/helper/src/claude/claude-code.ts`
  - `apps/helper/src/codex/app-server-chat.test.ts`
  - `apps/helper/src/codex/app-server-chat.ts`
  - `apps/helper/src/codex/codex-mirror.test.ts`
  - `apps/helper/src/codex/codex-mirror.ts`
  - `apps/helper/src/copilot/copilot.ts`
  - `apps/helper/src/server/cloudflare-tunnel.ts`
  - `apps/tablet/src/App.test.tsx`
  - `apps/tablet/src/App.tsx`
  - `apps/tablet/src/Dashboard.tsx`
  - `apps/tablet/src/Sidebar.tsx`
  - `apps/tablet/src/ThreadView.tsx`
  - `apps/tablet/src/api.ts`
  - `apps/tablet/src/threadRendering.test.ts`

## File cohesion plan

- file: `apps/helper/src/server/agent-pulse-server.ts`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/helper/src/server/watch-remote-control-routes.ts`
- file: `apps/helper/src/server/agent-pulse-server.test.ts`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/helper/src/server/watch-remote-control-routes.test.ts`
- file: `packages/shared/src/index.ts`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `packages/shared/src/watch-remote-control.ts`
- file: `apps/watchos/AgentPulseWatch/AgentPulseWatch/AgentPulseStore.swift`
  classification: `handwritten-source`
  disposition: `deferred-split`
  reason-code: `deferred-decomposition`
  split-target: `apps/watchos/AgentPulseWatch/AgentPulseWatch/AttentionStore.swift`
- file: `apps/watchos/AgentPulseWatch/AgentPulseWatch/ContentView.swift`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/watchos/AgentPulseWatch/AgentPulseWatch/AttentionView.swift`
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

## Interface or contract changes

- Extend `/watch/summary` with remote-control capability flags and a compact
  attention count.
- Add `GET /watch/attention` for Watch-shaped approval and prompt items.
- Preserve `POST /threads/:threadId/approvals/:requestId`, but route Codex
  decisions through app-server when desktop control is disabled.
- Preserve `/thread/open` desktop-control blocking in the beta Watch runtime.
- Restrict Watch-created new Codex threads to known project ids from
  `/projects/list`; no arbitrary Watch filesystem path entry.
- Decode and render transcript metadata, file references, file changes,
  attachments, plan items, goal, model, permission mode, and active turn state.

## Acceptance criteria

- Watch can continue existing Codex-visible threads, reply, stop runs, answer
  prompt requests, and approve surfaced Codex actions after explicit
  confirmation.
- Watch can start a new Codex thread from a known project only.
- Watch detail presents compact artifact cards without exposing raw local paths
  beyond helper-mediated display paths/references.
- Desktop control remains disabled where configured; Codex Desktop IPC/open is
  not required for Watch approvals.
- Docker `pnpm test`, `pnpm typecheck`, and `pnpm build` pass.
- Watch simulator build passes.

## TDD plan

- smallest failing check: `pnpm exec vitest run packages/shared/src/schemas.test.ts apps/helper/src/server/agent-pulse-server.test.ts`
- fixture or seam: shared Zod contracts, in-memory paired device registry,
  mocked Codex app-server pending requests, mocked `respondToApproval`, and
  mocked project list/start-thread seams.
- green condition: targeted Watch attention, app-server approval routing, and
  project-only Watch thread-start tests pass, followed by full Docker product
  gates and Watch simulator build.
- refactor guard: `git diff --check`, Docker `pnpm typecheck`, Docker
  `pnpm build`, and AgentOS verification gates.

## Validation matrix

| Surface | Check | Proof |
| --- | --- | --- |
| Codex schema guard | local `codex app-server generate-json-schema --experimental` | local methods inspected and temp directory deleted |
| Shared contracts | `packages/shared/src/schemas.test.ts` | Watch summary and attention payload schemas pass |
| Helper API | `apps/helper/src/server/agent-pulse-server.test.ts` | attention, desktop-disabled approval, and project-only start pass |
| Watch app | `xcodebuild` watchOS simulator build | Swift decode/navigation/rendering compiles |
| Product gates | Docker `pnpm test`, `pnpm typecheck`, `pnpm build` | full product gate passes |
| Harness | AgentOS verifiers | adapter and plan evidence remain valid |

## Deploy/runtime impact

- No live macmini deploy, Project Manager mutation, helper restart, Codex
  Desktop focus/restart/kill, or physical Watch installation is part of this
  code pass.
- Existing public pairing target remains
  `https://beta.dope-ai.kr/agent-pulse`.
- APNs credentials remain separate and are not read or modified.

## Review risks and open questions

- The exact first-party ChatGPT mobile relay is not public API; this change
  copies the documented capability model while retaining AgentPulse helper
  authentication as the public gateway.
- Physical Watch APNs notification behavior still requires local APNs key
  material and a signed device install; this pass validates the foreground
  control surfaces and simulator build.
- File preview content stays helper-mediated; the Watch currently renders
  compact cards rather than opening full file preview text.

## Validation plan

- Targeted helper/shared tests for Watch attention, app-server approval routing
  under desktop-disabled mode, project-only Watch thread start, Watch summary
  capabilities, and artifact-safe transcript surfaces.
- Watch simulator build after Swift changes.
- Docker gates: `pnpm test`, `pnpm typecheck`, `pnpm build`.
- Runtime proof only if a safe helper is already running; do not disturb Codex
  Desktop or Project Manager.

## Validation evidence

- commands run: Docker `pnpm exec vitest run packages/shared/src/schemas.test.ts apps/helper/src/server/agent-pulse-server.test.ts`; Docker `pnpm test`; Docker `pnpm typecheck`; Docker `pnpm build`; Watch simulator `xcodebuild`; `git diff --check`; AgentOS `verify_harness.py`, `verify_protocol.py`, and `verify_exec_plan.py --stage start`.
- runtime proof: local `http://127.0.0.1:55110/health/get` returned AgentPulse JSON with `codexAppServer: "connected"`; process list showed real `/Applications/Codex.app/Contents/Resources/codex app-server` processes and no `/tmp/fake-bin/codex` entry in the filtered command output.
- remaining gaps: public `https://beta.dope-ai.kr/agent-pulse/health/get` still returned Project Manager HTML instead of AgentPulse JSON, so live beta routing remains a separate deployment blocker; APNs/physical Watch install was not run in this code pass.
- Docker targeted tests passed:
  `pnpm exec vitest run packages/shared/src/schemas.test.ts apps/helper/src/server/agent-pulse-server.test.ts`
  with 122 tests passing.
- Docker product gates passed:
  `pnpm test` with 553 tests passing,
  `pnpm typecheck`, and `pnpm build`.
- Watch simulator build passed with:
  `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project apps/watchos/AgentPulseWatch/AgentPulseWatch.xcodeproj -scheme AgentPulseWatch -destination 'platform=watchOS Simulator,id=2E3189FB-CBD8-406C-9BCB-94CD7AA20D3D' CODE_SIGNING_ALLOWED=NO build`.
- `git diff --check` passed.

## TDD evidence

- red signal: initial Watch simulator build failed on `ContentView.swift`
  confirmation state handling and a complex optional expression.
- red artifact: Xcode build output from the failed simulator compile in this
  rollout; not recorded as a harness `.tdd-runs` artifact because product tests
  were required to run inside Docker.
- green result: after splitting the answer decision and fixing state shadowing,
  the Watch simulator build passed.
- green artifact: Docker gate output and Watch simulator build output from this
  rollout; not recorded as a harness `.tdd-runs` artifact because local `pnpm`
  is unavailable and product tests were run inside Docker.
- widened green: targeted Docker tests passed for shared schemas and helper
  Watch remote-control routes, then full Docker product gates passed.
- refactor verification: `git diff --check`, Docker `pnpm typecheck`, Docker
  `pnpm build`, and Watch simulator build passed.

## Review evidence

- reviewer: `codex`
- source docs checked: OpenAI Codex remote-connection/app-server docs confirm
  remote actions and warn not to expose an unauthenticated app-server listener
  publicly.
- local review scope: helper public gateway boundary, desktop-control-disabled
  approval path, Watch project-only thread creation, confirmation flows, and
  artifact rendering.
- unresolved findings: physical Watch/APNs delivery was not run in this code
  pass because no APNs secret material or physical install step was requested
  during validation.

## Completion status

- state: validation-complete.
- remaining live-runtime step: deploy/install this build and pair/refresh the
  physical Watch against `https://beta.dope-ai.kr/agent-pulse` when the user
  wants device rollout.

## Frontier routing

- status: single-lane-not-escalated.
- task class: implementation
- arbiter: codex

## Progress log

- 2026-05-16: Captured dirty starting state and Codex schema-sync evidence.
- 2026-05-16: Added Watch attention schema, summary capability flags, and
  helper `/watch/attention` response shape.
- 2026-05-16: Routed Codex approvals through app-server when desktop control is
  disabled, preserving `/thread/open` blocking semantics.
- 2026-05-16: Added Watch Attention and New Thread surfaces with confirmation
  dialogs for approvals, prompt answers, stopping, and project-only thread
  starts.
- 2026-05-16: Added Watch transcript artifact cards for active turn state,
  model, reasoning, permissions, goal, plan items, image/file references, and
  file-change summaries.
- 2026-05-16: Ran Docker tests/typecheck/build and Watch simulator build.
