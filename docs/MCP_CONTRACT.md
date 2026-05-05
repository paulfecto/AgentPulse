# MCP Contract / MCP 계약

AgentPulse does not expose a repo-owned MCP server today. This file records
that negative contract so future MCP work has an explicit place to update.
Codex MCP elicitation and approval events may still appear in provider
transcripts; AgentPulse only displays and answers those through the helper's
existing authenticated approval routes.

## User outcome / 사용자 결과

No MCP surface is exposed by AgentPulse. Users interact through the paired
browser UI and the helper HTTP/WebSocket API.

## Surface split / surface 분리

### Default surface / 기본 surface

- target user / 대상 사용자:
- allowed operations / 허용 작업: none; no repo-owned MCP default surface exists.

### Admin surface / 관리자 surface

- target user / 대상 사용자:
- allowed operations / 허용 작업: none; no repo-owned MCP admin surface exists.
- higher-risk mutations / 고위험 mutation: keep admin/device/remote-access mutations on helper HTTP routes guarded by existing auth.

## Guide-first rules / 가이드 우선 규칙

- which guide or contract must be read first / 먼저 읽어야 하는 가이드 또는 계약: `README.md`, `docs/REMOTE_ACCESS_REQUIREMENTS.md`, and `repo_harness.toml`.
- when tools should refuse or redirect / 도구가 거부하거나 우회해야 하는 상황: refuse any claim that AgentPulse exposes a supported MCP server until a real MCP entrypoint and schema are added.

## Auth model / 인증 모델

- auth type / 인증 유형: not applicable for MCP; helper HTTP uses paired device tokens/admin bearer tokens.
- user identity model / 사용자 식별 모델: paired personal devices, not MCP identities.
- secret handling rules / 비밀정보 처리 규칙: do not expose provider tokens, pairing tokens, APNs tokens, or tunnel credentials through any future MCP surface.

## Read boundaries / 읽기 경계

- allowed reads / 허용 읽기: none via MCP today.
- disallowed reads / 금지 읽기: raw provider files, raw SQLite databases, keychain records, local credentials, and raw provider endpoints.

## Mutation boundaries / mutation 경계

- allowed writes / 허용 쓰기: none via MCP today.
- disallowed writes / 금지 쓰기: device pairing/revoke, settings, remote access, provider sends, stops, approvals, and file-change actions unless implemented through a future reviewed MCP contract.

## Canonical mutation path / 정식 mutation 경로

- backend path used by UI and MCP / UI와 MCP가 함께 쓰는 backend 경로: none for MCP; UI uses the helper API routes in `apps/helper/src/server/agent-pulse-server.ts`.
- canonical mutation result shape / 정식 mutation 결과 형태: not applicable for MCP.
- canonical realtime result shape when applicable / 필요 시 정식 realtime 결과 형태: not applicable for MCP; browser clients use helper WebSocket live events.

## Runtime verification expectations / 런타임 검증 기대치

- health checks / health 점검: helper `/health/get` remains the runtime health surface.
- affected-flow checks / 영향 경로 점검: run `pnpm test`, `pnpm typecheck`, and affected helper/tablet tests.
- MCP/UI agreement checks / MCP와 UI 일치성 점검: if MCP is added later, prove every MCP mutation shares the same helper-side authorization and response contract as the browser UI.
