# AGENTS.md

This file is the repo-local adapter for the global harness in `agentOS`.
이 파일은 `agentOS` 전역 하니스에 대한 저장소 로컬 어댑터입니다.

Keep this file small and repository-specific. Do not duplicate the global
operating model here.
이 파일은 작고 저장소 전용으로 유지하고, 전역 운영 모델을 중복해서 적지 않습니다.

## Goal / 목표

Resolve repo work through the declared AgentOS adapter while keeping local
product truth in this repository.
선언된 AgentOS 어댑터를 통해 저장소 작업을 해결하되, 제품별 진실은 이 저장소에 둡니다.

## Success criteria / 성공 기준

- use the smallest relevant repo context before editing
  - 코드 수정 전 필요한 최소 저장소 컨텍스트만 확인합니다.
- keep non-trivial work tied to a real execution plan under
  `docs/exec-plans/active/`
  - 비사소한 작업은 `docs/exec-plans/active/` 아래의 실제 실행 계획과 연결합니다.
- finish with validation, TDD evidence when behavior changes, and review or
  consultation evidence when required
  - 동작 변경은 검증, TDD 증거, 필요한 리뷰 또는 consultation 증거와 함께 마무리합니다.
- leave repo-local adapter files aligned with `repo_harness.toml`
  - 저장소 로컬 어댑터 파일을 `repo_harness.toml`과 일치시킵니다.

## Global safety rules / 전역 안전 규칙

- never run `rm -rf ~/`, `rm -rf ~`, `rm -rf /`, or `rm -rf /*`
  - `rm -rf ~/`, `rm -rf ~`, `rm -rf /`, `rm -rf /*`는 절대 실행하지 않습니다.
- never run recursive deletion on broad paths such as `~`, `/`, `/Users`, `/home`, or `/Volumes`
  - `~`, `/`, `/Users`, `/home`, `/Volumes` 같은 넓은 경로에는 recursive deletion을 실행하지 않습니다.
- when deletion is required, target specific narrow paths and confirm with the user first
  - 삭제가 필요할 때는 구체적이고 좁은 경로만 대상으로 삼고 먼저 사용자 확인을 받습니다.

## Lane selection / 레인 선택

- `repo_harness.toml [lane]` is the local source of truth for lane mode, primary lane, and delegated role routing
  - `repo_harness.toml [lane]`는 레인 모드, 기본 레인, delegated 역할 라우팅에 대한 로컬 source of truth입니다.
- `mode = "orchestrated"` means this repo enters through one orchestrator control plane by default
  - `mode = "orchestrated"`은 이 저장소가 기본적으로 하나의 orchestrator control plane으로 진입한다는 뜻입니다.
- simple work may still collapse to one lane internally; secondary lanes are used only for the roles declared in `lane.role_routing`
  - 단순 작업은 내부적으로 한 레인으로 collapse될 수 있고, 보조 레인은 `lane.role_routing`에 선언된 역할에만 사용합니다.
- Codex, Claude, and Gemini are orchestrator-compatible lanes; Gemini delegated writes should stay limited to explicit media classes such as image/video generation
  - Codex, Claude, Gemini는 orchestrator-compatible 레인이며 Gemini delegated 쓰기는 image/video generation 같은 명시적 media 클래스에 한해 제한해야 합니다.
- do not use Claude/BKit or any other external lane unless `repo_harness.toml [lane]` enables it
  - `repo_harness.toml [lane]`가 활성화하지 않은 Claude/BKit 또는 다른 외부 레인은 사용하지 않습니다.
- even in orchestrated mode, keep the declared primary lane as the default mutation owner and use secondary lanes only for the delegated roles declared in `lane.role_routing`
  - orchestrated 모드에서도 선언된 기본 레인을 기본 mutation owner로 유지하고 보조 레인은 `lane.role_routing`에 선언된 delegated 역할에만 사용합니다.

## Primary-lane request routing / 기본 레인 요청 라우팅

- ordinary engineering requests are harness-managed by default
  - 일반 엔지니어링 요청은 기본적으로 하니스 관리 요청입니다.
- enter through `bash scripts/harness/run_primary_runtime.sh` and check new
  runtime paths with `bash scripts/harness/doctor_primary_runtime.sh`
  - 기본 진입은 `bash scripts/harness/run_primary_runtime.sh`이며, 새 런타임 경로는
    `bash scripts/harness/doctor_primary_runtime.sh`로 확인합니다.
- route browser automation through `bash scripts/harness/run_browser_automation.sh`
  and obey `[capability_control]`
  - 브라우저 자동화는 `bash scripts/harness/run_browser_automation.sh`로 실행하고
    `[capability_control]`를 따릅니다.
- if `runtime.backend = "omx"`, do not run `omx setup --scope project`;
  AgentOS owns the repo-local adapter files
  - `runtime.backend = "omx"`인 경우 `omx setup --scope project`를 실행하지 않습니다.
    저장소 로컬 adapter 파일은 AgentOS가 소유합니다.
- use `.agents/skills/harness-executor` for non-trivial Codex or Claude work
  when that lane is enabled
  - 해당 레인이 활성화된 경우 비사소한 Codex 또는 Claude 작업은
    `.agents/skills/harness-executor`를 사용합니다.
- before harness install/update setup changes, run the adoption planner and
  apply only with `--accept-adoption-plan`
  - 하니스 install/update 설정 변경 전에는 adoption planner를 실행하고
    `--accept-adoption-plan`으로만 적용합니다.
- if the creative workflow preset is enabled, route writing to Claude,
  image/video generation to Gemini, and keep user-facing copy in English and Korean
  - creative workflow preset이 활성화되면 writing은 Claude, image/video generation은
    Gemini로 보내고 사용자 노출 copy는 영어/한국어 병기로 유지합니다.
- if the diagram-design preset is enabled, route internal explanatory diagrams
  as `diagram-generation` to Claude; keep Mermaid/D2/PlantUML/generated graphs
  for source-of-truth diagrams that must stay text-diffable or tool-generated
  - diagram-design preset이 활성화되면 내부 설명 다이어그램은
    `diagram-generation`으로 Claude에 라우팅합니다. text diff나 도구 생성이
    필요한 source-of-truth 다이어그램은 Mermaid/D2/PlantUML/generated graph를
    유지합니다.
- if the engineering-discipline preset is enabled, use bounded clarification
  for risky ambiguity, diagnose bugs through a tight feedback loop, keep shared
  vocabulary in `CONTEXT.md`, and record durable architectural decisions as ADRs
  only when the execution plan allows those writes
  - engineering-discipline preset이 활성화되면 위험한 모호성에는 bounded
    clarification을 사용하고, 버그는 좁은 feedback loop로 진단하며, 공유
    용어는 `CONTEXT.md`에 두고, durable architecture decision은 실행 계획이
    허용한 경우에만 ADR로 기록합니다.
- keep repeatable methods in lane-local reusable surfaces instead of restating
  them in prompts
  - 반복 가능한 방법은 프롬프트에 반복하지 말고 레인 로컬 재사용 surface에 둡니다.

## Repository map / 저장소 구조

- product entrypoints / 제품 진입점: `README.md`, `apps/helper/src/dev-server.ts`, `apps/helper/src/main.ts`, `apps/tablet/src/App.tsx`, `extension/run.sh`
- backend or services / 백엔드 또는 서비스: `apps/helper/src/server/agent-pulse-server.ts`, provider adapters under `apps/helper/src/{codex,claude,copilot}`, shared contracts in `packages/shared/src/index.ts`
- frontend or UI / 프론트엔드 또는 UI: React/Vite tablet app under `apps/tablet/src`
- infra or deploy / 인프라 또는 배포: OpenAssist extension files under `extension/`, local dev runners under `scripts/`, Cloudflare tunnel supervision under `apps/helper/src/server/cloudflare-tunnel.ts`

## Local source-of-truth rules / 로컬 source-of-truth 규칙

- canonical product truth lives in / 정식 제품 진실 데이터 위치: shared Zod schemas in `packages/shared/src/index.ts`, helper route/provider behavior in `apps/helper/src`, and tablet UI state/transport behavior in `apps/tablet/src`
- projection or derived surfaces / projection 또는 파생 surface: README screenshots/copy, product requirement docs under `docs/`, generated AgentOS checklist/ledger surfaces under `docs/exec-plans`
- feature-specific invariants / 기능별 불변 조건: paired devices talk only to the helper, raw provider files/endpoints stay server-side, mobile send remains gated by helper settings, and remote access must keep origin/device auth checks intact

## Runtime and deploy topology / 런타임 및 배포 토폴로지

- environments / 환경: macOS helper plus browser clients on local loopback/LAN or optional Cloudflare Tunnel
- deploy path / 배포 경로: `pnpm build` produces shared, tablet, and helper bundles; the OpenAssist extension launches `apps/helper/dist/dev-server.js`
- health or smoke endpoints / health 또는 smoke 엔드포인트: helper exposes `/health/get` and `/health`; local smoke uses `pnpm dev:run:local`

## Validation commands / 검증 명령

- frontend build / 프론트엔드 빌드: `pnpm --filter @agent-pulse/tablet build`
- backend boot / 백엔드 부트: `pnpm --filter @agent-pulse/helper build`
- targeted checks / 대상 검증: `pnpm test`, `pnpm typecheck`
- runtime smoke / 런타임 스모크: `pnpm dev:run:local`, then verify `/health/get` on the printed helper URL

## TDD method / TDD 방법

- default TDD mode from `repo_harness.toml [tdd]` / `repo_harness.toml [tdd]`의 기본 TDD 모드: contract-first vertical slices
- fastest test command to run red-green-refactor loops / red-green-refactor 루프에 사용할 가장 빠른 테스트 명령: `pnpm test`
- fixture or seam strategy / fixture 또는 seam 전략: use Vitest temp directories, in-memory auth stores, mocked provider transports, and jsdom browser APIs
- refactor guard / refactor 보호 장치: run `pnpm typecheck` and `pnpm build` after behavior-impacting changes
- start enforceable behavior changes with the smallest failing check that proves
  the intended seam
  - 강제 가능한 동작 변경은 의도한 seam을 증명하는 가장 작은 실패 체크로 시작합니다.
- for non-trivial behavior changes, prefer a vertical red-green-refactor slice
  that proves one user-visible or contract-visible path end to end before
  widening horizontally across layers
  - 비사소한 동작 변경은 여러 layer를 수평으로 넓히기 전에 하나의 사용자
    노출 또는 계약 노출 경로를 끝까지 증명하는 vertical red-green-refactor
    slice를 우선합니다.
- record red, green, and refactor evidence in the active execution plan
  - red, green, refactor 증거는 활성 실행 계획에 기록합니다.

## Evidence required / 필요한 증거

- validation commands and results / 검증 명령과 결과
- TDD red/green/refactor evidence for enforceable behavior changes / 동작 변경의 TDD red/green/refactor 증거
- review or consultation evidence when required by harness policy / 하니스 정책이 요구하는 리뷰 또는 consultation 증거
- refreshed progress ledger after material task-state changes through
  `bash scripts/harness/update_progress_ledger.sh`
  - 중요한 작업 상태 변경 후 `bash scripts/harness/update_progress_ledger.sh`로
    progress ledger를 갱신합니다.
- retained artifacts only when explicitly listed as `retain-artifact: relative/path` / 명시된 `retain-artifact: relative/path`만 보존

## Stop conditions / 중단 조건

- stop only when the active plan is complete, validation evidence is recorded,
  or a real blocker artifact explains why completion is impossible now
  - 활성 계획이 완료되고 검증 증거가 기록되었거나, 지금 완료할 수 없는 이유를 실제
    blocker artifact가 설명할 때만 중단합니다.
- before final handoff, run lane cleanup when available and keep disposable
  screenshots, captures, logs, and delegated outputs out of durable state
  - 최종 handoff 전 가능한 lane cleanup을 실행하고 임시 스크린샷, 캡처, 로그,
    delegated output은 durable state에 남기지 않습니다.

## Shared harness skills / 공용 하니스 스킬

- shared skill root / 공용 스킬 루트: `.agents/skills`
- automatic request router / 자동 요청 라우터: `harness-executor`
- planner / 계획 수립: `harness-planner`
- reviewer / 리뷰: `harness-reviewer`
- runtime verifier / 런타임 검증: `harness-runtime-verifier`
- MCP auditor / MCP 점검: `harness-mcp-auditor`
- handoff / 핸드오프: `harness-handoff`
- engineering discipline optional methods / 선택형 엔지니어링 규율 방법:
  `harness-clarifier`, `harness-diagnose`, `harness-domain-language`

## Local MCP surfaces / 로컬 MCP surface

- AgentPulse does not expose a repo-owned MCP server; `repo_harness.toml` declares `has_mcp = false`.
- Codex MCP elicitation approvals may appear inside provider transcripts and are mediated through the helper approval routes.
- default surface / 기본 surface: no MCP tool surface owned by this repo.
- admin surface / 관리자 surface: no MCP admin surface owned by this repo.
- mutation rules / mutation 규칙: MCP-originated provider requests must follow the same helper approval/auth path as tablet approval actions.

## Directory-specific instructions / 디렉터리별 지침

- `apps/helper/`: preserve helper-only access to raw provider files, local agent transports, pairing stores, and Cloudflare tunnel state.
- `apps/tablet/`: keep browser clients same-origin with the helper; do not bypass shared schemas for API payloads.
- `packages/shared/`: update schemas and tests before changing helper/tablet wire contracts.
- `extension/`: keep OpenAssist lifecycle assumptions aligned with the helper build output and configured helper port.
