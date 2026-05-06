# Harness guide

This repository inherits its shared operating model from `agentOS`.
이 저장소는 `agentOS`의 공통 운영 모델을 상속합니다.

## Prompt policy / 프롬프트 정책

- AgentOS prompt surfaces are outcome-first: goal, success criteria,
  constraints, evidence, stop conditions, and final handoff
  - AgentOS 프롬프트 surface는 목표, 성공 기준, 제약, 증거, 중단 조건,
    최종 handoff를 먼저 둡니다.
- Shared law belongs in scripts, schemas, and global docs; repo-local prompts
  should point to those contracts instead of duplicating them
  - 공통 규칙은 scripts, schemas, 전역 문서에 두고, 저장소 로컬 프롬프트는
    중복하지 않고 해당 계약을 가리킵니다.

## Global harness / 전역 하니스

- configured `global_harness_root`: `../agentOS`
- canonical `global_harness_repo`: `https://github.com/Dope-AI-KR/agentOS`

Read the global harness docs for shared workflow, validation, review, MCP, and
deploy/runtime standards.
공유 워크플로우, 검증, 리뷰, MCP, 배포/런타임 기준은 전역 하니스 문서를 읽습니다.

## Adoption plan / 도입 계획

- Harness install/update is plan-first: run `--plan-adoption`, answer the
  project-specific setup questions, then apply with `--accept-adoption-plan`
  - 하니스 install/update는 plan-first입니다. `--plan-adoption`으로 저장소별
    설정 질문에 답한 뒤 `--accept-adoption-plan`으로 적용합니다.
- Current AgentOS supports the current adapter contract only; historical
  behavior belongs to AgentOS git tags/releases
  - 현재 AgentOS는 현재 adapter contract만 지원합니다. 과거 동작은 AgentOS
    git tag/release로 보존합니다.

## Local authority in this repo / 이 저장소의 로컬 권한 문서

Use the smallest set of local truth needed for the request:
요청에 필요한 최소한의 로컬 진실 문서만 사용합니다.

- `repo_harness.toml`, `AGENTS.md`, this guide, and the active execution plan
  define the adapter contract
  - `repo_harness.toml`, `AGENTS.md`, 이 guide, 활성 실행 계획이 어댑터 계약을 정의합니다.
- `docs/HARNESS_CHECKLIST.md` is the generated readiness checklist for the
  current adapter
  - `docs/HARNESS_CHECKLIST.md`는 현재 adapter의 생성형 readiness checklist입니다.
- lane-local context such as `.codex/config.toml`, `GEMINI.md`, `CLAUDE.md`,
  and `.agents/skills/` applies only when that lane is enabled
  - `.codex/config.toml`, `GEMINI.md`, `CLAUDE.md`, `.agents/skills/` 같은
    레인 로컬 컨텍스트는 해당 레인이 활성화될 때만 적용합니다.
- `state-ledger.json`, `WORKING_CONTEXT.md`, and `SESSION_START.md` preserve
  cross-session state
  - `state-ledger.json`, `WORKING_CONTEXT.md`, `SESSION_START.md`는 세션 간 상태를 보존합니다.

## Enabled lanes in this repo / 이 저장소에서 활성화된 레인

- `repo_harness.toml [lane]` is the local source of truth for lane mode, primary lane, enabled lanes, and any role routing
  - `repo_harness.toml [lane]`는 레인 모드, 기본 레인, 활성 레인, 역할 라우팅에 대한 로컬 source of truth입니다.
- `mode = "orchestrated"` means every non-trivial request enters through one orchestrator control plane
  - `mode = "orchestrated"`은 모든 비사소한 요청이 하나의 orchestrator control plane으로 진입한다는 뜻입니다.
- simple work may still collapse to one lane internally, but that is a topology decision inside orchestration
  - 단순 작업은 내부적으로 한 레인으로 collapse될 수 있지만, 그것도 orchestration 내부 topology 결정입니다.
- when secondary lanes are enabled, only the lanes declared in `lane.role_routing` may take delegated work
  - 보조 레인이 활성화되면 `lane.role_routing`에 선언된 레인만 delegated 작업을 맡을 수 있습니다.
- Codex, Claude, and Gemini are orchestrator-compatible lanes; Gemini delegated writes should stay limited to explicit media classes such as image/video generation
  - Codex, Claude, Gemini는 orchestrator-compatible 레인이며 Gemini delegated 쓰기는 image/video generation 같은 명시적 media 클래스에 한해 제한해야 합니다.
- lane-specific wrappers should exist only under the enabled lane directories such as `scripts/codex/`, `scripts/gemini/`, and `scripts/claude/`
  - 레인별 래퍼는 `scripts/codex/`, `scripts/gemini/`, `scripts/claude/`처럼 활성화된 레인 디렉터리에만 존재해야 합니다.

## Lane automation in this repo / 이 저장소의 레인 자동화

- Codex repos use `.codex/config.toml` and `.agents/skills/` for repo-scoped defaults, automatic request routing, and Codex-specific shared methods
  - Codex 저장소는 `.codex/config.toml`과 `.agents/skills/`를 사용해 저장소 범위 기본값, 자동 요청 라우팅, Codex 전용 공유 방법을 관리합니다.
- `repo_harness.toml [runtime]` declares whether the primary lane uses the native AgentOS launcher path or the optional upstream OMX runtime backend
  - `repo_harness.toml [runtime]`는 기본 레인이 AgentOS 기본 실행 경로를 쓸지, 선택적 업스트림 OMX 런타임 백엔드를 쓸지 선언합니다.
- `scripts/harness/doctor_primary_runtime.sh` and `scripts/harness/run_primary_runtime.sh` are the repo-scoped entrypoints that should match the declared primary lane plus runtime backend
  - `scripts/harness/doctor_primary_runtime.sh`, `scripts/harness/run_primary_runtime.sh`는 선언된 기본 레인과 런타임 백엔드에 맞아야 하는 저장소 범위 엔트리포인트입니다.
- `scripts/harness/run_browser_automation.sh` is the repo-scoped browser/UI entrypoint and should keep downstream automation inside Docker by default
  - `scripts/harness/run_browser_automation.sh`는 저장소 범위 브라우저/UI 엔트리포인트이며 downstream 자동화를 기본적으로 Docker 안에 유지해야 합니다.
- `repo_harness.toml [capability_control]` governs browser-external origins and repo-mutating orchestration on harness-owned surfaces
  - `repo_harness.toml [capability_control]`는 하니스가 소유하는 surface에서 browser-external origin과 저장소 변이 orchestration을 제어합니다.
- Gemini repos use `.gemini/settings.json` and `GEMINI.md` for repo-scoped context and automatic request routing
  - Gemini 저장소는 `.gemini/settings.json`과 `GEMINI.md`를 사용해 저장소 범위 컨텍스트와 자동 요청 라우팅을 관리합니다.
- web/content-heavy repos should consider the optional creative workflow preset: Claude for all writing, Gemini for image/video generation, English/Korean together for user-facing copy, and the internal developer progress board preset when a collapsible internal progress panel is useful
  - 웹/콘텐츠 중심 저장소는 선택적 creative workflow preset을 고려해야 합니다. 모든 writing은 Claude, image/video generation은 Gemini, 사용자 노출 copy는 영어/한국어 병기, 그리고 접이식 내부 진행 패널이 필요할 때는 developer progress board preset을 권장합니다.
- repos with internal explanatory diagrams should consider the optional diagram-design preset: Claude handles `diagram-generation`, the preferred output is standalone HTML/SVG, and Mermaid/D2/PlantUML/generated graphs remain the right choice for source-of-truth diagrams
  - 내부 설명 다이어그램이 있는 저장소는 선택적 diagram-design preset을 고려해야 합니다. `diagram-generation`은 Claude가 담당하고 기본 산출물은 standalone HTML/SVG이며, source-of-truth 다이어그램에는 Mermaid/D2/PlantUML/generated graph가 적합합니다.
- engineering repos should consider the optional engineering-discipline preset: bounded clarification before risky work, feedback-loop-first debugging, shared domain language in `CONTEXT.md`, ADRs for durable architecture decisions, and vertical TDD slices
  - 엔지니어링 저장소는 선택적 engineering-discipline preset을 고려해야 합니다. 위험한 작업 전 bounded clarification, feedback-loop-first debugging, `CONTEXT.md`의 공유 도메인 언어, durable architecture decision을 위한 ADR, vertical TDD slice를 사용합니다.
- ordinary engineering requests should flow through the enabled primary lane automatically
  - 일반적인 엔지니어링 요청은 활성화된 기본 레인을 통해 자동으로 흐르도록 구성되어야 합니다.
- if `runtime.backend = "omx"`, AgentOS still owns repo-local truth, TDD evidence, and completion gates while upstream `oh-my-codex` provides the interactive Codex runtime
  - `runtime.backend = "omx"`인 경우에도 저장소 로컬 truth, TDD 증거, 완료 게이트는 AgentOS가 계속 소유하고 업스트림 `oh-my-codex`는 대화형 Codex 런타임만 제공합니다.
- do not run `omx setup --scope project` in an AgentOS repo; the repo-local adapter files remain AgentOS-owned surfaces
  - AgentOS 저장소에서는 `omx setup --scope project`를 실행하지 않습니다. 저장소 로컬 adapter 파일은 계속 AgentOS 소유 surface입니다.
- when the Codex lane is enabled, `scripts/codex/clean_repo_artifacts.sh` should prune disposable screenshots, logs, and delegated run outputs
  - Codex 레인이 활성화된 경우 `scripts/codex/clean_repo_artifacts.sh`가 임시 스크린샷, 로그, delegated run output을 정리해야 합니다.
- `.claude/settings.json`, `CLAUDE.md`, `scripts/claude/bootstrap_repo_claude.sh`, `scripts/claude/run_repo_claude.sh`, and `scripts/claude/doctor_repo_claude.sh` should exist when Claude is the declared primary lane
  - Claude가 선언된 기본 레인인 경우 `.claude/settings.json`, `CLAUDE.md`, `scripts/claude/bootstrap_repo_claude.sh`, `scripts/claude/run_repo_claude.sh`, `scripts/claude/doctor_repo_claude.sh`가 존재해야 합니다.
- `scripts/claude/doctor_claude_bkit.sh` and `scripts/claude/claude_bkit_delegate.sh` should exist only when hybrid routing uses Claude as a secondary lane
  - hybrid 라우팅이 Claude를 보조 레인으로 사용할 때만 `scripts/claude/doctor_claude_bkit.sh`, `scripts/claude/claude_bkit_delegate.sh`가 존재해야 합니다.
- when hybrid routing uses Codex as a secondary lane, the normal Codex repo wrappers remain the intake surface for those routed roles
  - hybrid 라우팅이 Codex를 보조 레인으로 사용할 때는 해당 역할에도 일반 Codex 저장소 래퍼를 그대로 사용합니다.

## TDD in this repo / 이 저장소의 TDD

- `repo_harness.toml [tdd]` is the local source of truth for this repo's TDD mode, fastest test command, fixture strategy, and refactor guard
  - `repo_harness.toml [tdd]`는 이 저장소의 TDD 모드, 가장 빠른 테스트 명령, fixture 전략, refactor 보호 장치에 대한 로컬 source of truth입니다.
- non-trivial work should start with a TDD plan in the active execution plan
  - 비사소한 작업은 활성 실행 계획의 TDD 계획으로 시작해야 합니다.
- non-trivial behavior changes should use a vertical red-green-refactor slice
  first: prove one end-to-end behavior path before spreading work horizontally
  across many layers
  - 비사소한 동작 변경은 먼저 vertical red-green-refactor slice를 사용해야
    합니다. 여러 layer로 수평 확장하기 전에 하나의 end-to-end 동작 경로를
    증명합니다.
- use `bash scripts/harness/run_declared_tdd_check.sh --phase red` and `--phase green` to record the machine-generated red/green artifacts for completion evidence
  - `bash scripts/harness/run_declared_tdd_check.sh --phase red`와 `--phase green`를 사용해 완료 증거에 넣을 machine-generated red/green artifact를 기록합니다.
- declare `tdd.red_signal_regex` so the red phase proves the intended failing seam instead of an arbitrary shell error
  - `tdd.red_signal_regex`를 선언해 red phase가 임의의 shell 오류가 아니라 의도한 failing seam을 증명하도록 합니다.
- completion claims should include red signal, red artifact, green result, green artifact, and refactor evidence in the active execution plan
  - 완료 주장에는 활성 실행 계획에 red signal, red artifact, green result, green artifact, refactor 증거가 포함되어야 합니다.
- `HARNESS_PROGRESS_LEDGER.html` is the shared progress projection for the active execution plan and should be refreshed when task state changes materially
  - `HARNESS_PROGRESS_LEDGER.html`은 활성 실행 계획의 공용 진행 상태 projection이며 작업 상태가 크게 바뀌면 갱신해야 합니다.
- `state-ledger.json`, `WORKING_CONTEXT.md`, and `SESSION_START.md` are the machine-backed state surfaces for cross-session continuity and lane launch context
  - `state-ledger.json`, `WORKING_CONTEXT.md`, `SESSION_START.md`는 세션 간 연속성과 레인 실행 컨텍스트를 위한 machine-backed 상태 surface입니다.
- when `repo_harness.toml [autonomy].allow_infinite_local_iteration = true`, this repo must also carry the `termination-supervisor` feature and a real `[termination_supervisor]` section
  - `repo_harness.toml [autonomy].allow_infinite_local_iteration = true`인 경우 이 저장소는 `termination-supervisor` feature와 실제 `[termination_supervisor]` 섹션도 함께 가져야 합니다.
- `install.sh` / `update.sh` auto-backfill that supervisor adoption when possible; explicitly disabling it while keeping infinite local iteration will fail verification
  - `install.sh` / `update.sh`는 가능할 때 이 supervisor adoption을 자동 보정하며, infinite local iteration을 유지한 채 명시적으로 비활성화하면 verification에 실패합니다.
- completion-gate supervision now suspends when the same gate failure repeats instead of looping forever on identical evidence
  - completion-gate supervision은 동일한 gate 실패가 반복되면 같은 증거로 무한 반복하지 않고 suspend합니다.
- if the repo changes enforceable behavior without a clear TDD loop, the adapter is incomplete
  - 저장소가 명확한 TDD 루프 없이 강제 가능한 동작을 변경한다면 어댑터가 불완전한 상태입니다.

This repository must pass the global repository execution gate before local
bootstrap or reusable CI can proceed, and non-trivial work must have an active
execution plan file with completion evidence before CI can accept the claim.
로컬 bootstrap이나 reusable CI가 진행되기 전에 전역 저장소 실행 게이트를 통과해야 하며,
비사소한 작업은 completion evidence가 포함된 활성 실행 계획 파일이 있어야 CI가 완료 주장을 받아들입니다.

Disposable artifacts should stay disposable: keep only evidence explicitly
retained by `retain-artifact: relative/path` lines in the active execution plan,
and, when the Codex lane is enabled, prune the rest through
`scripts/codex/clean_repo_artifacts.sh`.
임시 artifact는 임시로 남겨야 합니다. 활성 실행 계획의
`retain-artifact: relative/path` 라인으로 보관한 evidence만 남기고, 나머지는
Codex 레인이 활성화된 경우 `scripts/codex/clean_repo_artifacts.sh`로 정리합니다.

## Where to add new guidance / 새 지침을 어디에 둘지

- shared rules across multiple repositories:
  - add them to `agentOS`
- this repository's topology, commands, or MCP endpoints:
  - add them here, in `AGENTS.md`, `repo_harness.toml`, or `docs/MCP_CONTRACT.md`
- one feature or owner layer only:
  - add the guidance beside the owning code or feature docs

Keep the repo-local adapter small. Point to the global harness for shared
policy instead of duplicating it here.
로컬 어댑터는 작게 유지하고, 공유 정책은 여기서 중복하지 말고 전역 하니스를 참조합니다.
