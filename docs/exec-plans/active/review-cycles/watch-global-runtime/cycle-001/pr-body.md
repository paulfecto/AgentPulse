# PR Body Draft

This artifact is generated from the active AgentOS execution plan and current
git diff summary. It is review support, not source-of-truth product state.

## Summary

Derived from `docs/exec-plans/active/watch-global-runtime.md`.

## Plan Grounding

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

## Changed Files

```text
.agents/.agentOS-skill-manifest.json               |   5 +-
 .agents/skills/harness-reviewer/SKILL.md           |  25 +-
 .codex/config.toml                                 |   5 +
 HARNESS_VERSION                                    |   2 +-
 apps/helper/src/auth/admin.ts                      |   3 +-
 apps/helper/src/auth/keychain-store.ts             |   2 +-
 apps/helper/src/dev-server.ts                      |   8 +-
 apps/helper/src/main.ts                            |   8 +-
 apps/helper/src/server/agent-pulse-server.test.ts  | 354 ++++++++++++++++++++-
 apps/helper/src/server/agent-pulse-server.ts       | 136 +++++++-
 apps/helper/src/server/cloudflare-tunnel.test.ts   |  40 ++-
 apps/helper/src/server/cloudflare-tunnel.ts        |  16 +-
 apps/helper/src/server/settings.ts                 |  16 +-
 apps/tablet/src/App.test.tsx                       | 122 ++++++-
 apps/tablet/src/App.tsx                            | 139 +++++++-
 apps/tablet/src/styles.css                         |  31 ++
 .../AgentPulseWatch/AgentPulseClient.swift         |   2 +-
 .../AgentPulseWatch/AgentPulseStore.swift          |  77 ++++-
 .../AgentPulseWatch/ContentView.swift              |  79 ++++-
 .../AgentPulseWatch/AgentPulseWatch/Info.plist     |   6 +-
 .../AgentPulseWatch/AgentPulseWatch/Models.swift   |   7 +
 .../AgentPulseWatch/ThreadDetailView.swift         |  27 +-
 apps/watchos/AgentPulseWatch/README.md             |  92 +++++-
 docs/HARNESS_CHECKLIST.md                          |  32 +-
 docs/HARNESS_GUIDE.md                              |   2 +-
 docs/exec-plans/.cohesion-history.required         |   2 +-
 .../exec-plans/active/HARNESS_PROGRESS_LEDGER.html |  62 +++-
 docs/exec-plans/active/SESSION_START.md            |   4 +-
 docs/exec-plans/active/TEAM_PROGRESS_LEDGER.html   |   2 +-
 docs/exec-plans/active/WORKING_CONTEXT.md          |   8 +-
 docs/exec-plans/active/agentos-adoption-plan.json  |  11 +-
 docs/exec-plans/active/agentos-adoption-plan.md    |   4 +-
 docs/exec-plans/active/apple-watch-support.md      |   7 +-
 docs/exec-plans/active/heartbeat.jsonl             |   8 +-
 docs/exec-plans/active/resume-state.json           |   6 +-
 docs/exec-plans/active/state-ledger.json           |   8 +-
 docs/exec-plans/active/task-claim.json             |   6 +-
 .../completed/agentos-downstream-adoption.md       |  14 +-
 .../scorecard-proposals/routing-policy-proposal.md |   2 +-
 package.json                                       |   2 +
 packages/shared/src/index.ts                       |   5 +
 repo_harness.toml                                  | 106 +++---
 scripts/_agent_os/resolve_trusted_harness_root.py  |  14 +
 43 files changed, 1320 insertions(+), 187 deletions(-)
```

## Test Plan

- See the active execution plan validation and TDD evidence.

## Review Notes

- Review against `review-context.md`.
- Copy unresolved blockers back into the active execution plan review evidence.
