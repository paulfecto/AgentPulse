# Execution plan

Adopt AgentOS 4.8.0 as the repo-local harness adapter for AgentPulse using the clean pinned upstream worktree at `../agentOS-upstream-main`.

## Target behavior

- AgentPulse has a checked-in AgentOS adapter that points to `dope-ai-kr/agentOS` at `11274a64f909ea1ee0a3c92455b4d291ba8ea344`.
- Future repo work enters through the Codex-primary AgentOS surfaces without merging AgentOS product source into AgentPulse.
- The adapter records real AgentPulse validation, TDD, runtime, and MCP truth instead of leaving scaffold placeholders.

## Inputs and constraints

- User requested downstream adoption through the official AgentOS installer.
- Use `../agentOS-upstream-main`, not dirty `../agentOS`.
- Keep existing AgentPulse product code untouched unless adapter verification requires repo-local harness metadata.
- `pnpm` may be unavailable in this shell; if so, record that as an environment blocker for AgentPulse checks.

## Owning layer

- Owner: `codex`
- Layer: repo harness adapter and documentation surfaces.
- Product runtime ownership remains in `apps/helper`, `apps/tablet`, and `packages/shared`.

## Planned write set

- `AGENTS.md`, `HARNESS_VERSION`, `repo_harness.toml`, `CONTEXT.md`
- `.gitignore`
- `docs/HARNESS_CHECKLIST.md`, `docs/HARNESS_GUIDE.md`, `docs/MCP_CONTRACT.md`, `docs/adr/`
- `docs/exec-plans/active/`, `docs/exec-plans/scorecard-proposals/`
- `.agents/`, `.codex/`, `scripts/_agent_os/`, `scripts/codex/`, `scripts/harness/`
- Existing large source files observed by the AgentOS start gate from the current HEAD baseline, not edited by this adapter adoption: `apps/helper/src/claude/claude-code.test.ts`, `apps/helper/src/claude/claude-code.ts`, `apps/helper/src/codex/app-server-chat.test.ts`, `apps/helper/src/codex/app-server-chat.ts`, `apps/helper/src/codex/codex-mirror.test.ts`, `apps/helper/src/codex/codex-mirror.ts`, `apps/helper/src/codex/thread-reader.ts`, `apps/helper/src/copilot/copilot.ts`, `apps/helper/src/server/agent-pulse-server.test.ts`, `apps/helper/src/server/agent-pulse-server.ts`, `apps/tablet/src/App.test.tsx`, `apps/tablet/src/App.tsx`, `apps/tablet/src/Dashboard.tsx`, `apps/tablet/src/Sidebar.tsx`, `apps/tablet/src/ThreadView.tsx`, `apps/tablet/src/api.ts`, `packages/shared/src/index.ts`

## File cohesion plan

The following records preserve AgentPulse product source during this adapter-only adoption. They are listed because the first AgentOS start gate also inspects large source files changed by the current HEAD commit before a task baseline exists.

- file: `apps/helper/src/claude/claude-code.test.ts`
  classification: `handwritten-source`
  disposition: `deferred-split`
  reason-code: `deferred-decomposition`
  split-target: `apps/helper/src/claude/claude-code-streaming.test.ts`
- file: `apps/helper/src/claude/claude-code.ts`
  classification: `handwritten-source`
  disposition: `deferred-split`
  reason-code: `deferred-decomposition`
  split-target: `apps/helper/src/claude/claude-code-session.ts`
- file: `apps/helper/src/codex/app-server-chat.test.ts`
  classification: `handwritten-source`
  disposition: `deferred-split`
  reason-code: `deferred-decomposition`
  split-target: `apps/helper/src/codex/app-server-chat-events.test.ts`
- file: `apps/helper/src/codex/app-server-chat.ts`
  classification: `handwritten-source`
  disposition: `deferred-split`
  reason-code: `deferred-decomposition`
  split-target: `apps/helper/src/codex/app-server-chat-session.ts`
- file: `apps/helper/src/codex/codex-mirror.test.ts`
  classification: `handwritten-source`
  disposition: `deferred-split`
  reason-code: `deferred-decomposition`
  split-target: `apps/helper/src/codex/codex-mirror-files.test.ts`
- file: `apps/helper/src/codex/codex-mirror.ts`
  classification: `handwritten-source`
  disposition: `deferred-split`
  reason-code: `deferred-decomposition`
  split-target: `apps/helper/src/codex/codex-mirror-sync.ts`
- file: `apps/helper/src/codex/thread-reader.ts`
  classification: `handwritten-source`
  disposition: `deferred-split`
  reason-code: `deferred-decomposition`
  split-target: `apps/helper/src/codex/thread-reader-events.ts`
- file: `apps/helper/src/copilot/copilot.ts`
  classification: `handwritten-source`
  disposition: `deferred-split`
  reason-code: `deferred-decomposition`
  split-target: `apps/helper/src/copilot/copilot-session.ts`
- file: `apps/helper/src/server/agent-pulse-server.test.ts`
  classification: `handwritten-source`
  disposition: `deferred-split`
  reason-code: `deferred-decomposition`
  split-target: `apps/helper/src/server/agent-pulse-server-routes.test.ts`
- file: `apps/helper/src/server/agent-pulse-server.ts`
  classification: `handwritten-source`
  disposition: `deferred-split`
  reason-code: `deferred-decomposition`
  split-target: `apps/helper/src/server/agent-pulse-routes.ts`
- file: `apps/tablet/src/App.test.tsx`
  classification: `handwritten-source`
  disposition: `deferred-split`
  reason-code: `deferred-decomposition`
  split-target: `apps/tablet/src/App.provider-flows.test.tsx`
- file: `apps/tablet/src/App.tsx`
  classification: `handwritten-source`
  disposition: `deferred-split`
  reason-code: `deferred-decomposition`
  split-target: `apps/tablet/src/AppShell.tsx`
- file: `apps/tablet/src/Dashboard.tsx`
  classification: `handwritten-source`
  disposition: `deferred-split`
  reason-code: `deferred-decomposition`
  split-target: `apps/tablet/src/DashboardPanels.tsx`
- file: `apps/tablet/src/Sidebar.tsx`
  classification: `handwritten-source`
  disposition: `deferred-split`
  reason-code: `deferred-decomposition`
  split-target: `apps/tablet/src/SidebarThreadList.tsx`
- file: `apps/tablet/src/ThreadView.tsx`
  classification: `handwritten-source`
  disposition: `deferred-split`
  reason-code: `deferred-decomposition`
  split-target: `apps/tablet/src/ThreadTranscript.tsx`
- file: `apps/tablet/src/api.ts`
  classification: `handwritten-source`
  disposition: `deferred-split`
  reason-code: `deferred-decomposition`
  split-target: `apps/tablet/src/api-client.ts`
- file: `packages/shared/src/index.ts`
  classification: `handwritten-source`
  disposition: `deferred-split`
  reason-code: `deferred-decomposition`
  split-target: `packages/shared/src/schemas.ts`

## Interface or contract changes

- Adds AgentOS adapter contracts and Codex lane configuration.
- Declares AgentPulse validation commands, TDD loop, projection surfaces, and no repo-owned MCP server.
- Does not change helper HTTP APIs, tablet APIs, shared Zod schemas, extension manifest behavior, or provider transports.

## Acceptance criteria

- AgentOS installer has accepted the adoption plan and generated the repo-local adapter.
- `repo_harness.toml` points at `../agentOS-upstream-main` and the expected upstream commit.
- AgentOS `verify_harness.py`, `verify_protocol.py`, and `verify_exec_plan.py --stage start` pass.
- AgentPulse checks are run when `pnpm` is available, or the missing package manager is recorded clearly.

## TDD plan

- smallest failing check: `pnpm test` should fail on any broken shared schema, helper route/provider behavior, or tablet rendering contract.
- fixture or seam: use existing Vitest temp directories, in-memory stores, mocked provider transports, and jsdom browser APIs.
- green condition: `pnpm test` passes after adapter adoption without product-source changes.
- refactor guard: run `pnpm typecheck` and `pnpm build` when the package manager is available.

## Validation matrix

| Surface | Check | Proof |
| --- | --- | --- |
| AgentOS adapter | `python3 ../agentOS-upstream-main/scripts/harness/verify_harness.py --repo "$PWD"` | repo-local harness contract is valid |
| AgentOS protocol | `python3 ../agentOS-upstream-main/scripts/harness/verify_protocol.py --repo "$PWD"` | generated state and protocol surfaces are valid |
| Active plan | `python3 ../agentOS-upstream-main/scripts/harness/verify_exec_plan.py --repo "$PWD" --stage start` | this plan has concrete task-start content |
| AgentPulse tests | `pnpm test` | helper, tablet, and shared behavioral tests pass |
| AgentPulse types/build | `pnpm typecheck` and `pnpm build` | TypeScript and bundle contracts compile |

## Deploy/runtime impact

- Runtime product behavior is unchanged.
- New harness wrappers can launch/doctor the Codex-primary runtime.
- Local helper smoke remains `pnpm dev:run:local`, then check `/health/get` on the printed helper URL.

## Review risks and open questions

- AgentOS 4.8.0 requires `allow_infinite_local_iteration = true`, which auto-materializes `termination-supervisor` even though the adoption answers set continuous local iteration to false.
- The generated OpenAssist/package manager checks still depend on `pnpm` being installed in the local shell.
- No product MCP server exists; the adapter marks MCP disabled while preserving a negative MCP contract.

## Validation evidence

- commands run: `bash ../agentOS-upstream-main/scripts/harness/install.sh --repo "$PWD" --accept-adoption-plan` succeeded; Docker AgentOS gate passed with `verify_harness.py`, `verify_protocol.py`, and `verify_exec_plan.py --stage start`; Docker product gate passed with `pnpm test`, `pnpm typecheck`, and `pnpm build` from an ephemeral copied repo.
- runtime proof: product runtime behavior was not changed; production build completed inside Docker.
- remaining gaps: none for downstream adoption; runtime smoke was not started because this task only applies the adapter and product build/test/type gates passed.

## TDD evidence

- red signal: not required for this adapter-only adoption.
- red artifact: not recorded because no product behavior contract was changed.
- green result: Docker `pnpm test` passed 33 test files and 440 tests with `TMPDIR=/worktmp`.
- green artifact: Docker command output in the Codex session; `docs/exec-plans/active/.plan-baselines/agentos-downstream-adoption-e8949d5b52728a0f.json` and `docs/exec-plans/.cohesion-history.json` record the AgentOS start-gate baseline.
- refactor verification: Docker `pnpm typecheck` and Docker `pnpm build` passed.

## Review evidence

- reviewer: `codex`
- review artifact: `docs/exec-plans/active/agentos-downstream-adoption.md`
- unresolved findings: no product-source changes; local package manager remains unavailable, so all product verification was run inside Docker.
- Repo inspection confirmed AgentPulse does not expose a repo-owned MCP server.
- AgentOS verifier inspection confirmed `termination-supervisor` is required by the current harness contract when `allow_infinite_local_iteration = true`.

## Completion status

- state: validation-complete for downstream adoption.
- ready for merge or deploy: yes for the AgentOS adapter adoption; app behavior is unchanged and Docker test/type/build gates passed.

## Frontier routing

- status: single-lane-not-escalated for this adapter adoption.
- task class: implementation
- arbiter: codex
