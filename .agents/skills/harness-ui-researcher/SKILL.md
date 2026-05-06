---
name: harness-ui-researcher
description: Reference-ground UI creation, critique, redesign, and visual polish through the optional AgentOS ui-reference preset and Lazyweb MCP when configured.
---

# Harness UI Researcher

Use this skill before substantial UI/UX work, especially landing pages, pricing pages, onboarding flows, checkout flows, dashboards, settings pages, mobile app UI, public-facing UI waves, visual critique, redesign, or frontend polish.

## Contract

- First inspect `repo_harness.toml`.
- Use Lazyweb only when `install.enabled_features` contains `ui-reference` and `[ui_reference].enabled = true`.
- Use only the declared Lazyweb MCP endpoint, token environment variable, and allowlisted tools from `[ui_reference]`.
- If Lazyweb is unavailable, tokenless, or offline, continue the UI work and record that reference grounding was skipped. Do not fail the task only because Lazyweb is unavailable.
- Do not install third-party Lazyweb plugins, vendor Lazyweb code, or mutate global agent config.
- Do not commit `LAZYWEB_MCP_TOKEN` or any token value.
- Do not upload private screenshots or confidential product material to external providers unless the active plan and operator explicitly allow it.

## Workflow

1. Classify the UI target: page type, flow, platform, audience, and risk.
2. Check whether `ui-reference` is enabled and whether `LAZYWEB_MCP_TOKEN` is available locally.
3. If available, search Lazyweb for comparable product patterns and flows.
4. Compare the references against the repo's own product intent; extract reusable structure, hierarchy, interaction patterns, and pitfalls.
5. Implement or critique using the references as grounding, not as a pixel-copy source.
6. Cite the reference-backed decisions in the execution notes, including what was used and what was intentionally rejected.

## Output Expectations

- Name the UI pattern evidence used, or state clearly that Lazyweb grounding was skipped.
- Keep decisions generic and defensible: layout hierarchy, affordance, interaction model, empty/loading/error states, responsive behavior, accessibility.
- Preserve AgentOS lane routing: Claude still owns writing through `creative-workflow`; Gemini still owns image/video generation; Lazyweb is UI/UX reference research and critique grounding only.
