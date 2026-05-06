# Execution plan

Converge the repository-local AgentOS adapter with the configured upstream
harness root and confirm the repo has the current shared skill surface enabled.

- status: in-progress
- owner: codex
- started: 2026-05-05

## Target behavior

- The official AgentOS downstream installer runs from `../agentOS`
  with the accepted adoption plan.
- The repo remains on `main`.
- Every harness skill materialized under `.agents/skills` is enabled in
  `.codex/config.toml`.
- Enabled AgentOS feature doctors and verifiers pass inside a disposable Docker
  container.
- Obsolete or disposable harness artifacts are either absent, cleaned by a narrow
  harness-owned path, or explicitly recorded as active product work.

## Inputs and constraints

- User requested an AgentOS update/convergence pass with all skills enabled and
  no obsolete repo-local AgentOS surfaces.
- Use the configured harness root from `repo_harness.toml`:
  `../agentOS`.
- Stay on `main` and do not disturb the live Codex Desktop app or helper
  runtime.
- Run verification in Docker when it is a test or gate.
- Do not vendor, symlink, clone, or depend on `mattpocock/skills`; keep the
  engineering-discipline method as AgentOS `pattern-extraction`.
- Treat existing Watch/helper source edits as active product work, not cleanup
  targets for this convergence pass.

## Owning layer

- Owner: `codex`
- Harness-owned surfaces: repo adapter config, generated harness docs, local
  shared skills, Codex skill enablement config, and active execution-plan
  ledgers.
- Product-owned surfaces remain outside this pass unless the installer changes a
  generated adapter boundary.

## Planned write set

- `docs/exec-plans/active/agentos-convergence.md`
- `docs/HARNESS_CHECKLIST.md`
- `docs/exec-plans/active/HARNESS_PROGRESS_LEDGER.html`
- `docs/exec-plans/active/TEAM_PROGRESS_LEDGER.html`
- `docs/exec-plans/active/WORKING_CONTEXT.md`
- `docs/exec-plans/active/state-ledger.json`
- `docs/exec-plans/active/agentos-adoption-plan.md`
- `docs/exec-plans/active/agentos-adoption-plan.json`
- `docs/exec-plans/scorecard-proposals/routing-policy-proposal.md`
- `docs/diagrams/diagram-style-guide.md`
- `.agents/skills/**` if the installer refreshes shared skills
- `.codex/config.toml` if skill enablement drifts
- `repo_harness.toml` if installer convergence changes adapter config
- `packages/shared/src/index.ts` as pre-existing active Watch product work
  observed in the dirty worktree, not modified by this convergence pass
- `apps/helper/src/server/agent-pulse-server.ts` as pre-existing active Watch
  product work observed in the dirty worktree, not modified by this convergence
  pass
- `apps/helper/src/server/agent-pulse-server.test.ts` as pre-existing active
  Watch product work observed in the dirty worktree, not modified by this
  convergence pass
- `apps/tablet/src/App.tsx` as pre-existing active Watch remote/settings
  product work observed in the dirty worktree, not modified by this convergence
  pass
- `apps/tablet/src/App.test.tsx` as pre-existing active Watch remote/settings
  product work observed in the dirty worktree, not modified by this convergence
  pass
- `apps/tablet/src/api.ts` as active Watch remote/path-prefix product work
  observed in the dirty worktree, not modified by this convergence pass

## File cohesion plan

These files exceed the harness size threshold in the current dirty worktree.
This convergence pass only records their active ownership; it does not decompose
or refactor them.

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
- file: `apps/tablet/src/App.test.tsx`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`
- file: `apps/tablet/src/api.ts`
  classification: `handwritten-source`
  disposition: `preserve-only`
  reason-code: `deferred-decomposition`

## Interface or contract changes

- No product API, helper, tablet, or watch contract changes are planned.
- AgentOS adapter contracts should remain at the official installer-selected
  `harness_version` and configured upstream ref unless a later installer run
  changes them.
- Skill enablement is expected to remain a Codex runtime configuration surface in
  `.codex/config.toml`.

## Acceptance criteria

- Installer/update path completes with `--accept-adoption-plan`.
- `repo_harness.toml` resolves to `../agentOS` at the current fetched upstream
  `main` ref selected by the installer.
- `.agents/skills` contains the materialized harness skills.
- `.codex/config.toml` enables every materialized harness skill.
- Docker AgentOS verifiers and enabled feature doctors pass.
- Searches for disabled-feature or external-vendor leftovers find no cleanup
  targets requiring deletion.

## TDD plan

- smallest failing check: Docker AgentOS verifier/doctor run after installer
  convergence, plus a static skill/config consistency check.
- red signal: missing skill, disabled skill config, unsupported adapter schema,
  invalid active execution plan, or obsolete generated feature artifact should
  fail the convergence gate.
- fixture or seam: bind-mount the repo, trusted harness checkout, and its git
  worktree parent into a disposable Python Docker container with `git`,
  `jsonschema`, and `cryptography`.
- green condition: the same Docker container reports harness/protocol/exec-plan
  and enabled feature checks passing.
- refactor guard: inspect `git diff` for harness-owned changes only; no product
  source changes should be introduced by this AgentOS pass.

## Validation matrix

| Surface | Check | Proof |
| --- | --- | --- |
| Installer convergence | `bash ../agentOS/scripts/harness/install.sh --repo "$PWD" --accept-adoption-plan` | official downstream update path succeeds |
| Harness contract | Docker `verify_harness.py`, `verify_protocol.py`, `verify_exec_plan.py --stage start` | adapter and active plan contract are current |
| Enabled features | Docker feature doctors/verifiers | engineering discipline, diagram design, creative workflow, frontier, and termination supervisor remain valid |
| Skills | static Docker/Python config check | all `.agents/skills/*/SKILL.md` skills are enabled in `.codex/config.toml` |
| Obsolete surfaces | targeted `find`/`rg` checks | no disabled-feature or forbidden-vendor leftovers are present |

## Deploy/runtime impact

- No deploy or runtime behavior change is expected.
- The live helper on `55110` and Codex Desktop app are intentionally untouched.
- Docker verification containers use `--rm` and should leave no long-running
  containers.

## Review risks and open questions

- AgentOS optional `developer-progress-board` is not enabled because the
  accepted adoption plan keeps the developer progress panel disabled; this is an
  optional feature, not a missing skill.
- Existing dirty Watch/helper product files are outside this cleanup scope and
  should not be deleted or reverted as obsolete.
- If an enabled feature doctor fails, prefer installer-owned adapter convergence
  before editing product code.

## Validation evidence

- commands run: official installer/update path,
  `generate_repo_checklist.py`, `update_progress_ledger.sh`, Docker
  `verify_harness.py`, Docker `verify_protocol.py`, Docker
  `verify_exec_plan.py --stage start`, Docker enabled feature doctors/verifiers,
  Docker static skill/config check, Docker vendor/reference hygiene check,
  Docker disabled-feature artifact check, and harness cleanup dry-run.
- runtime proof: no product runtime was changed; the live helper and Codex
  Desktop process were intentionally untouched.
- remaining gaps: enabled creative/diagram workflows still recommend Claude and
  Gemini lanes for delegated writing/media work, but `repo_harness.toml [lane]`
  currently enables only Codex by accepted adoption choice.
- installer result: `bash ../agentOS/scripts/harness/install.sh
  --repo "$PWD" --accept-adoption-plan` completed and reported
  `harness_version = "4.8.0"` current.
- Docker AgentOS result: harness verification passed, repository protocol
  checklist passed, execution-plan start gate passed, engineering discipline
  doctor passed with no warnings, diagram-design doctor passed with only the
  Claude-lane recommendation, creative-workflow doctor passed with only
  Claude/Gemini-lane recommendations, termination-supervisor doctor and verifier
  passed, frontier contract verification passed.
- Skill result: all ten materialized `.agents/skills/*/SKILL.md` skills are
  enabled in `.codex/config.toml`.
- Hygiene result: no `mattpocock/skills` vendor/symlink dependency was found;
  only the expected pattern-extraction reference remains. No disabled
  developer-progress, external-resume, or eval artifacts were found.
- Cleanup result: targeted disposable artifact dry-run reported `0` removable
  artifacts.
- Latest AgentOS update result, 2026-05-05: `git -C ../agentOS fetch origin
  main --prune` and `git -C ../agentOS pull --ff-only origin main` completed;
  the downstream installer then reported AgentOS `4.12.2` current at
  `52c63f1d47abc8c8f24605b1f01a05fd16a45019` and updated
  `repo_harness.toml` / `HARNESS_VERSION` accordingly.

## TDD evidence

- red signal: first Docker harness run failed because the Python image lacked
  `jsonschema` for the external termination-supervisor schema reference, then
  plan/progress/liveness gates exposed stale execution-plan surfaces.
- red artifact: transient Docker console output; no durable artifact retained.
- green result: Docker AgentOS gate and static skill/hygiene checks passed after
  adding the missing execution-plan sections, refreshing ledgers, adding the
  diagram style guide, and setting creative workflow copy roots.
- green artifact: transient Docker console output; no durable artifact retained.
- refactor verification: final diff inspection is limited to AgentOS
  adapter/config/doc surfaces plus pre-existing Watch/helper product work.

## Review evidence

- reviewer: `codex` using AgentOS harness checks and targeted diff inspection.
- review artifact: `docs/exec-plans/active/agentos-convergence.md`
- unresolved findings: no blocking AgentOS convergence findings. Claude/Gemini
  lane recommendations remain informational because this repo currently declares
  `lane.enabled = ["codex"]`.

## Completion status

- state: complete.
- ready for merge or deploy: yes for the AgentOS convergence changes; this pass
  did not change product runtime behavior.

## Frontier routing

- status: single-lane-not-escalated.
- task class: release-verification
- arbiter: codex
