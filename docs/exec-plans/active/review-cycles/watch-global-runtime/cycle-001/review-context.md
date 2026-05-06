# Generated Review Context

This artifact is generated review grounding for one AgentOS review cycle.
It is not a source of truth. Regenerate it from the active execution plan and
repo source files before each non-trivial review.

## Source Of Truth

- active execution plan: `docs/exec-plans/active/watch-global-runtime.md`
- global review rubric: `missing`
- domain context: `CONTEXT.md`
- ADR directory: `docs/adr`
- optional convention YAML: `docs/code-convention.yaml`
- optional ADR YAML: `docs/adr.yaml`

## Changed File Summary

```text
M	.agents/.agentOS-skill-manifest.json
M	.agents/skills/harness-reviewer/SKILL.md
M	.codex/config.toml
M	HARNESS_VERSION
M	apps/helper/src/auth/admin.ts
M	apps/helper/src/auth/keychain-store.ts
M	apps/helper/src/dev-server.ts
M	apps/helper/src/main.ts
M	apps/helper/src/server/agent-pulse-server.test.ts
M	apps/helper/src/server/agent-pulse-server.ts
M	apps/helper/src/server/cloudflare-tunnel.test.ts
M	apps/helper/src/server/cloudflare-tunnel.ts
M	apps/helper/src/server/settings.ts
M	apps/tablet/src/App.test.tsx
M	apps/tablet/src/App.tsx
M	apps/tablet/src/styles.css
M	apps/watchos/AgentPulseWatch/AgentPulseWatch/AgentPulseClient.swift
M	apps/watchos/AgentPulseWatch/AgentPulseWatch/AgentPulseStore.swift
M	apps/watchos/AgentPulseWatch/AgentPulseWatch/ContentView.swift
M	apps/watchos/AgentPulseWatch/AgentPulseWatch/Info.plist
M	apps/watchos/AgentPulseWatch/AgentPulseWatch/Models.swift
M	apps/watchos/AgentPulseWatch/AgentPulseWatch/ThreadDetailView.swift
M	apps/watchos/AgentPulseWatch/README.md
M	docs/HARNESS_CHECKLIST.md
M	docs/HARNESS_GUIDE.md
M	docs/exec-plans/.cohesion-history.required
M	docs/exec-plans/active/HARNESS_PROGRESS_LEDGER.html
M	docs/exec-plans/active/SESSION_START.md
M	docs/exec-plans/active/TEAM_PROGRESS_LEDGER.html
M	docs/exec-plans/active/WORKING_CONTEXT.md
M	docs/exec-plans/active/agentos-adoption-plan.json
M	docs/exec-plans/active/agentos-adoption-plan.md
M	docs/exec-plans/active/apple-watch-support.md
M	docs/exec-plans/active/heartbeat.jsonl
M	docs/exec-plans/active/resume-state.json
M	docs/exec-plans/active/state-ledger.json
M	docs/exec-plans/active/task-claim.json
M	docs/exec-plans/completed/agentos-downstream-adoption.md
M	docs/exec-plans/scorecard-proposals/routing-policy-proposal.md
M	package.json
M	packages/shared/src/index.ts
M	repo_harness.toml
M	scripts/_agent_os/resolve_trusted_harness_root.py
```

## Global Review Rubric

Source: `/Volumes/paulfecto/Development_team/AgentPulse/code_review.md`

Not present.


## Active Execution Plan Summary

Source: `docs/exec-plans/active/watch-global-runtime.md`

```text
## Target Behavior

- The Watch app has a real app icon and in-app logo based on the existing Agent
  Pulse mark in `apps/tablet/public/icon.svg`.
- Remote access settings clearly distinguish temporary quick tunnels from the
  stable named Cloudflare tunnel required for anywhere-in-the-world Watch use.
- A dedicated host-side run path starts the real helper with isolated Agent
  Pulse state, real Codex app-server transport, and
  `AGENT_PULSE_DISABLE_CODEX_DESKTOP=1`.
- The helper fails fast on named remote access when `cloudflared` is missing,
  not authenticated, or not configured.
- APNs credentials remain outside git; Watch notifications stay configurable
  through helper settings.

## Owning Layer

- Owner: `codex`
- Product layers: Watch app assets/UI, helper Cloudflare supervisor, tablet
  settings UI, and host runtime launcher.
- Runtime boundary: helper talks to real Codex app-server; desktop UI control is
  disabled for the Watch remote runtime.

## Planned Write Set

- `docs/exec-plans/active/watch-global-runtime.md`
- `packages/shared/src/index.ts`
- `apps/helper/src/server/agent-pulse-server.ts`
- `apps/helper/src/server/agent-pulse-server.test.ts`
- `apps/helper/src/server/cloudflare-tunnel.ts`
- `apps/helper/src/server/cloudflare-tunnel.test.ts`
- `apps/tablet/src/App.tsx`
- `apps/tablet/src/App.test.tsx`
- `apps/tablet/src/styles.css`
- `apps/watchos/AgentPulseWatch/AgentPulseWatch.xcodeproj/project.pbxproj`
- `apps/watchos/AgentPulseWatch/AgentPulseWatch/**`
- `apps/watchos/AgentPulseWatch/README.md`
- `scripts/generate-watch-icons.sh`
- `scripts/watch-remote-helper.sh`

## Acceptance Criteria

- Watch asset catalog contains app icon, accent color, and reusable logo image
  assets.
- Xcode project compiles the asset catalog and uses `AppIcon`.
- Watch pairing/offline/empty states render the Agent Pulse mark.
- Tablet settings can configure named Cloudflare hostname/tunnel name and show
  stable-domain checklist copy.
- Helper named tunnel config has one hostname ingress rule and refuses to start
  named mode before Cloudflare login.
- The dedicated Watch remote launcher keeps Codex Desktop control disabled and
  does not kill existing Codex Desktop processes.
- Docker `pnpm test`, `pnpm typecheck`, and `pnpm build` pass or record a real
  environment blocker.
- Xcode simulator build is attempted with signing disabled.

## Validation Matrix

| Surface | Check | Proof |
| --- | --- | --- |
| Watch branding | `pnpm watch:icons` plus Xcode simulator build | assets compile and `AppIcon` is wired |
| Helper Cloudflare guard | Docker targeted Vitest | named tunnel refuses missing login/hostname |
| Tablet settings | Docker targeted Vitest | stable hostname mode can be configured |
| Shared/watch contract | Docker targeted Vitest and typecheck | `/watch/summary` exposes remote mode |
| Repo gates | Docker `pnpm test`, `pnpm typecheck`, `pnpm build` | product checks pass in disposable container |
| Runtime launcher | static review and fail-fast checks | launcher requires hostname/cloudflared login and disables Codex Desktop control |

## Review Risks And Open Questions

- A stable Cloudflare hostname was not available in this session, so global
  pairing could not be launched or proven end to end.
- APNs credentials were not available, so notification delivery remains an
  external setup blocker.
- The launcher seeds isolated Agent Pulse state and keeps normal macOS `HOME`;
  review focus is making sure that isolation does not change Codex app-server
  authentication state.

## Review Evidence

- reviewer: `codex` using AgentOS harness checks plus targeted diff inspection
  of Cloudflare supervisor, tablet settings, shared schema, Watch SwiftUI, asset
  catalog, and launcher changes.
- review artifact: `docs/exec-plans/active/watch-global-runtime.md`
- unresolved findings: no blocking code findings from local review. External
  blockers remain stable Cloudflare hostname/authentication and APNs key
  material.
```

## Domain Context

Source: `/Volumes/paulfecto/Development_team/AgentPulse/CONTEXT.md`

```text
# Context

This file names the shared domain language for this repository.

Keep it compact. Add terms only when they remove repeated explanation across
plans, reviews, implementation, tests, or docs.

## Domain Terms

- term:
  - meaning:
  - source of truth:
  - do not confuse with:

## Product Boundaries

- owned here:
- owned elsewhere:
- intentionally out of scope:

## Architecture Language

- deep modules:
- shallow modules to avoid:
- locality boundaries:
- interface-depth expectations:

## Decision Notes

- durable architectural decisions should move into `docs/adr/`
- do not update this file unless the active execution plan includes it in the
  planned write set
```


## Markdown ADRs

Source directory: `docs/adr`

### `docs/adr/0000-adr-template.md`

```text
# ADR 0000: Title

- status: proposed
- date: YYYY-MM-DD
- owners:

## Context

What durable architectural pressure forced this decision?

## Decision

What are we choosing?

## Consequences

- positive:
- negative:
- follow-up:

## Boundaries

- this ADR changes:
- this ADR does not change:
- source of truth:
```

## Code Convention YAML

Source: `/Volumes/paulfecto/Development_team/AgentPulse/docs/code-convention.yaml`

Not present.


## ADR YAML

Source: `/Volumes/paulfecto/Development_team/AgentPulse/docs/adr.yaml`

Not present.
