# AgentOS Adoption Plan

## Goal
Adopt the current AgentOS contract for this downstream repo before harness-managed mutation.

## Answers
- repo type: `fullstack-web`
- primary lane: `codex`
- Claude writing workflow: `true`
- Gemini media workflow: `false`
- developer progress panel: `false`
- diagram design workflow: `true`
- engineering discipline workflow: `true`
- continuous local iteration: `false`
- external resume: `false`

## Planned Install Selection
- profile: `frontier`
- enabled features: `core, consultation, browser-containerized, frontier, secondary-lanes, creative-workflow, diagram-design, engineering-discipline`

## Recommendations
- Keep AgentOS setup plan-first: answer project-specific questions before mutation.
- Use current adapter contract surfaces instead of old compatibility inference.
- Route writing tasks to Claude through the creative-workflow feature.
- Use diagram-design as the preferred style for internal explanatory diagrams, with Mermaid/D2/PlantUML/generated graphs reserved for source-of-truth diagrams.
- Use engineering-discipline for bounded clarification, feedback-loop-first debugging, CONTEXT.md domain language, ADRs, and vertical TDD slices.

## Acceptance
- Run install/update with `--accept-adoption-plan` to apply this plan.
- Current AgentOS supports the current adapter contract only; historical behavior belongs to git tags/releases.

## Completion Status
- accepted: `true`
