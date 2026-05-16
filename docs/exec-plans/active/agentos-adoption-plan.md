# AgentOS Adoption Plan

## Goal
Adopt the current AgentOS contract for this downstream repo before harness-managed mutation.

## Answers
- repo type: `fullstack-web`
- primary lane: `codex`
- Claude writing workflow: `true`
- Gemini media workflow: `true`
- developer progress panel: `true`
- diagram design workflow: `true`
- engineering discipline workflow: `true`
- UI reference workflow: `true`
- continuous local iteration: `true`
- external resume: `false`

## Planned Install Selection
- profile: `full`
- enabled features: `core, consultation, browser-containerized, frontier, secondary-lanes, eval-mode, proof-orchestration, termination-supervisor, creative-workflow, developer-progress-board, diagram-design, engineering-discipline, ui-reference`

## Recommendations
- Keep AgentOS setup plan-first: answer project-specific questions before mutation.
- Use current adapter contract surfaces instead of old compatibility inference.
- Route writing tasks to Claude through the creative-workflow feature.
- Route image/video generation to Gemini through the creative-workflow feature.
- Install the collapsible internal developer progress panel preset.
- Use diagram-design as the preferred style for internal explanatory diagrams, with Mermaid/D2/PlantUML/generated graphs reserved for source-of-truth diagrams.
- Use engineering-discipline for GrillMe planning, feedback-loop-first debugging, CONTEXT.md domain language, ADRs, and vertical TDD slices.
- Use ui-reference for Lazyweb-backed UI/UX reference grounding before UI creation, critique, redesign, or polish.
- Use termination-supervisor for continuous local iteration.

## Acceptance
- Run install/update with `--accept-adoption-plan` to apply this plan.
- Current AgentOS supports the current adapter contract only; historical behavior belongs to git tags/releases.

## Completion Status
- accepted: `true`
