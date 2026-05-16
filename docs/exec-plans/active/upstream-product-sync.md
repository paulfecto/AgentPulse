# Execution plan

Integrate `upstream/main` from `manikv12/AgentPulse` into local `main` while
preserving the local Watch, beta-domain, AgentOS, APNs, Codex-safe runtime, and
macmini deployment behavior.

- status: in-progress
- owner: codex
- started: 2026-05-16

## Target behavior

- Our `main` includes the upstream product updates through
  `424c294 Address review comments for helper wording`.
- Watch replies still follow the active Codex turn through final assistant
  outcome instead of stopping at reasoning-only partial content.
- Watch list/detail behavior remains local-product-correct: Codex-visible
  threads only, pinned-title semantics preserved, full transcript pagination
  preserved, and subagent child rows excluded.
- The beta runtime still exposes `https://beta.dope-ai.kr/agent-pulse`, keeps
  Codex Desktop IPC/control disabled, and keeps `/thread/open` blocked under
  `AGENT_PULSE_DISABLE_CODEX_DESKTOP=1`.
- Upstream goal controls, permission-mode support, push preferences,
  safe file-preview support, device-management improvements, and packaging docs
  are adopted where compatible.
- AgentOS full-profile adapter remains intact; no fake `external-resume` or
  security configuration is introduced.

## Inputs and constraints

- Execute directly on `main`.
- Do not use a real browser, Computer Use, host browser automation, or physical
  Watch/Xcode testing for this validation pass.
- Run product verification inside Docker containers and clean disposable Docker
  volumes/containers created for this task.
- Do not restart, focus, kill, or IPC-control Codex Desktop.
- Do not modify or restart Project Manager containers.
- `upstream/main` has 12 commits not in local `main`; local `main` has 20
  commits not in upstream.
- A direct merge conflicts in core helper, shared schema, tablet, auth, and
  package files.

## Owning layer

- Owner: `codex`
- Product layers: shared contracts, Codex app-server transport, helper API/auth
  stores/settings, tablet UI/thread rendering, package/build scripts, and docs.
- Harness layers: active execution-plan evidence, consultation-attempt evidence,
  generated ledgers, and AgentOS verification state.

## Planned write set

- `docs/exec-plans/active/upstream-product-sync.md`
- `docs/exec-plans/active/task-claim.json`
- `docs/exec-plans/active/resume-state.json`
- `docs/exec-plans/active/heartbeat.jsonl`
- `docs/exec-plans/active/consultation-attempts/upstream-product-sync/**`
- `docs/exec-plans/active/HARNESS_PROGRESS_LEDGER.html`
- `docs/exec-plans/active/TEAM_PROGRESS_LEDGER.html`
- `docs/exec-plans/active/WORKING_CONTEXT.md`
- `docs/exec-plans/active/state-ledger.json`
- `packages/shared/src/index.ts`
- `packages/shared/src/schemas.test.ts`
- `apps/helper/src/codex/app-server-chat.ts`
- `apps/helper/src/codex/app-server-chat.test.ts`
- `apps/helper/src/codex/app-server-client.ts`
- `apps/helper/src/codex/app-server-client.test.ts`
- `apps/helper/src/codex/codex-mirror.ts`
- `apps/helper/src/codex/codex-mirror.test.ts`
- `apps/helper/src/codex/thread-opener.ts`
- `apps/helper/src/codex/thread-opener.test.ts`
- `apps/helper/src/claude/claude-code.ts`
- `apps/helper/src/claude/usage.ts`
- `apps/helper/src/copilot/copilot.ts`
- `apps/helper/src/copilot/usage.ts`
- `apps/helper/src/chats/shared-chat-paths.ts`
- `apps/helper/src/auth/**`
- `apps/helper/src/platform/**`
- `apps/helper/src/server/agent-pulse-server.ts`
- `apps/helper/src/server/agent-pulse-server.test.ts`
- `apps/helper/src/server/cloudflare-tunnel.ts`
- `apps/helper/src/server/**`
- `apps/helper/src/main.ts`
- `apps/helper/src/dev-server.ts`
- `apps/helper/src/single-instance.ts`
- `apps/helper/src/single-instance.test.ts`
- `apps/helper/package.json`
- `apps/helper/tsup.config.ts`
- `apps/tablet/src/App.tsx`
- `apps/tablet/src/App.test.tsx`
- `apps/tablet/src/Dashboard.tsx`
- `apps/tablet/src/Sidebar.tsx`
- `apps/tablet/src/ThreadView.tsx`
- `apps/tablet/src/api.ts`
- `apps/tablet/src/threadRendering.test.ts`
- `apps/tablet/src/**`
- `apps/tablet/vite.config.ts`
- `.github/workflows/release-npm-package.yml`
- `README.md`
- `docs/REMOTE_ACCESS_REQUIREMENTS.md`
- `docs/TOUCH_APP_REQUIREMENTS.md`
- `package.json`
- `scripts/copy-helper-assets.mjs`
- `scripts/dev-run-all.sh`
- `scripts/dev-run.sh`
- `scripts/package-npm.mjs`

## File cohesion plan

- file: `apps/helper/src/server/agent-pulse-server.ts`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/helper/src/server/agent-pulse-routes.ts`
- file: `apps/helper/src/server/agent-pulse-server.test.ts`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/helper/src/server/agent-pulse-routes.test.ts`
- file: `packages/shared/src/index.ts`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `packages/shared/src/contracts.ts`
- file: `apps/helper/src/codex/app-server-chat.ts`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/helper/src/codex/app-server-turns.ts`
- file: `apps/helper/src/codex/app-server-chat.test.ts`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/helper/src/codex/app-server-turns.test.ts`
- file: `apps/helper/src/codex/codex-mirror.ts`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/helper/src/codex/codex-mirror-events.ts`
- file: `apps/helper/src/codex/codex-mirror.test.ts`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/helper/src/codex/codex-mirror-events.test.ts`
- file: `apps/helper/src/claude/claude-code.ts`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/helper/src/claude/claude-code-transport.ts`
- file: `apps/helper/src/copilot/copilot.ts`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/helper/src/copilot/copilot-transport.ts`
- file: `apps/tablet/src/App.tsx`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/tablet/src/AppShell.tsx`
- file: `apps/tablet/src/App.test.tsx`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/tablet/src/AppShell.test.tsx`
- file: `apps/tablet/src/ThreadView.tsx`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/tablet/src/ThreadConversationView.tsx`
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
- file: `apps/tablet/src/api.ts`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/tablet/src/api-client.ts`
- file: `apps/tablet/src/threadRendering.test.ts`
  classification: `handwritten-source`
  disposition: `deferred-split`
  reason-code: `deferred-decomposition`
  split-target: `apps/tablet/src/threadRendering-focused.test.ts`
- file: `apps/tablet/src/styles.css`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/tablet/src/styles-layout.css`
- file: `apps/helper/src/server/cloudflare-tunnel.ts`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
  split-target: `apps/helper/src/server/cloudflare-tunnel-supervisor.ts`

## Interface or contract changes

- Add upstream-compatible goal, permission-mode, push-preference, file-preview,
  device-rename, and phone-push contracts while retaining existing Watch APNs,
  remoteAccess edge mode, and Watch summary capability contracts.
- Keep `/devices/watch-push` backward compatible and add/retain upstream
  `/devices/phone-push` preference routes only when they use the same
  authenticated device boundary.
- Keep helper API routes internally root-relative so `/agent-pulse/` remains an
  edge-stripped deployment path.
- Preserve short Watch message enforcement and full transcript pagination.

## Acceptance criteria

- Full upstream product updates are integrated without regressing local Watch
  beta-domain behavior.
- Docker `pnpm test`, `pnpm typecheck`, and `pnpm build` pass.
- AgentOS harness/protocol/exec-plan and enabled-feature gates pass.
- Consultation attempt is recorded truthfully: Claude/Gemini review if lanes are
  available, or exact blocked doctor output if not.
- Runtime proof that requires host Codex or physical Watch is not faked; if it
  cannot run under Docker-only constraints, it is recorded as not run.
- Repo is clean after commit/push except unrelated ignored user/runtime files.

## TDD plan

- smallest failing check: `pnpm test apps/helper/src/server/agent-pulse-server.test.ts apps/tablet/src/App.test.tsx`
- fixture or seam: Vitest temp directories, mocked Codex app-server transport,
  in-memory auth/device stores, and jsdom tablet rendering.
- red signal: targeted tests fail for Watch reply follow-through, visible
  thread filtering, full transcript pagination, desktop-control-disabled
  `/thread/open`, goal routes, push preferences, and file-preview safety.
- green condition: targeted tests plus Docker full product gates pass.
- fixture strategy: Vitest temp directories, mocked Codex app-server transport,
  in-memory stores, and jsdom; no real browser, physical Watch, or Codex Desktop
  IPC.
- refactor guard: Docker `pnpm typecheck`, Docker `pnpm build`, and AgentOS
  gates after conflict resolution.

## Validation matrix

| Surface | Check | Proof |
| --- | --- | --- |
| Consultation | Claude/Gemini lane doctors and artifacts | review or blocked evidence recorded |
| Contracts | shared schema tests | new upstream schemas coexist with local Watch contracts |
| Codex transport | app-server chat tests | active turn/goal/permission behavior is preserved |
| Helper APIs | agent-pulse server tests | routes/auth/push/file-preview/desktop-disabled behavior pass |
| Tablet UI | tablet tests | thread rendering, settings, device controls, and theme behavior pass |
| Docker product gates | `pnpm test`, `pnpm typecheck`, `pnpm build` | full repo is green in Docker |
| AgentOS | harness verifiers/doctors | adapter and active plan remain valid |

## Deploy/runtime impact

- No live deployment, host helper restart, Project Manager mutation, Codex
  Desktop control, or physical Watch installation is part of this pass.
- Public beta and physical Watch behavior must be preserved in code and covered
  through mocked/server contract tests.

## Review risks and open questions

- Highest conflict risk is in helper route composition and shared schemas,
  where upstream goal/push/file-preview contracts overlap local Watch/APNs and
  beta-edge contracts.
- Runtime proof against the real Codex app-server and physical Watch cannot be
  honestly completed inside Docker; record those as not-run under the user's
  Docker-only testing constraint.
- Claude/Gemini consultation is requested but currently blocked by repo lane
  configuration; do not fabricate external review.

## Consultation evidence

- Claude doctor, 2026-05-16: blocked with `Claude lane is not enabled for this
  repo.`
- Gemini doctor, 2026-05-16: blocked with `Gemini lane repo surface is missing
  Gemini settings: /Volumes/paulfecto/Development_team/AgentPulse/.gemini/settings.json`

## Validation evidence

- Docker product gate, 2026-05-16: `pnpm test && pnpm typecheck && pnpm build`
  passed in `node:22-bookworm-slim`; result: 41 Vitest files / 549 tests,
  TypeScript `--noEmit`, shared/tablet/helper production builds.
- Docker AgentOS core gates, 2026-05-16: `verify_harness.py`,
  `verify_protocol.py`, and `verify_exec_plan.py --stage start` passed in a
  disposable Python 3.12 container with `git`, `cryptography`, and
  `jsonschema` installed inside the container.
- Docker AgentOS feature gates, 2026-05-16: engineering-discipline doctor,
  termination-supervisor doctor/verifier, proof-orchestration verifier,
  eval-mode verifier, creative-workflow doctor, diagram-design doctor, and
  ui-reference doctor completed. Warning-only notes remain for unavailable
  Claude/Gemini lanes and missing `LAZYWEB_MCP_TOKEN`.
- Static cleanup check, 2026-05-16: `git diff --check` passed and no conflict
  markers or temporary `TRACE`/`DBG` test debug statements were found in the
  touched source/test surfaces.
- Not run by design: real host Codex app-server runtime, real browser, Computer
  Use, physical Watch/Xcode, macmini3 deploy, and Project Manager runtime
  checks. The user constrained this pass to Docker-only testing.

## TDD evidence

- red signal: Docker tablet test initially failed on live usage refresh and
  Codex/OpenAssist activity-summary regressions after the upstream merge.
- green result: `apps/tablet/src/App.test.tsx` passed 106/106 after restoring
  safe no-usage transcript refresh, semantic activity summary labels, direct
  activity rows, and collapsed activity DOM behavior.
- widened green: full Docker `pnpm test` passed 41 files / 549 tests, followed
  by Docker `pnpm typecheck` and Docker `pnpm build`.

## Review evidence

- reviewer: `codex`, with external Claude/Gemini consultation attempted and
  blocked truthfully by lane doctor output.
- review scope: merge conflict resolutions in helper route/auth/settings
  seams, shared schema contracts, tablet live transcript/thread rendering, and
  AgentOS adapter convergence.
- unresolved findings: no blocking code findings from local review. External
  runtime proof remains intentionally not run under the Docker-only constraint.

## Completion status

- state: validation-complete.

## Frontier routing

- status: single-lane-with-blocked-external-consultation.
- task class: implementation
- arbiter: codex
