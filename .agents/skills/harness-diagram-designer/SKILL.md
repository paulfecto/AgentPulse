---
name: harness-diagram-designer
description: Create low-density internal explanatory diagrams with AgentOS's diagram-design policy while preserving source-of-truth diagrams in text-diffable formats.
---

# Harness Diagram Designer

## When to use

Use this skill when a downstream repo needs an internal explanatory diagram:
architecture, organization, process flow, system map, responsibility map,
roadmap, or product explanation.

Do not use this skill for source-of-truth diagrams that must stay human-editable
and diffable in pull requests. Use Mermaid, D2, PlantUML, or a generated graph
for those cases.

## Workflow

1. Decide whether a diagram is actually better than prose, bullets, or a table.
   If a short paragraph or table is clearer, do not draw.
2. Choose one diagram grammar: architecture, flowchart, sequence, state,
   ER/data model, timeline, swimlane, quadrant, nested, tree, layers, venn, or
   pyramid. Do not mix grammars unless the task explicitly asks for a hybrid.
3. Load or create the repo-local style guide declared by
   `repo_harness.toml [diagram_design].style_guide_path`.
4. If the style guide is missing or still generic, pause before branded output
   and ask for brand tokens or permission to use the neutral internal style.
5. Produce a standalone HTML file with inline SVG and CSS under the configured
   output root.
6. Keep the diagram low-density: one clear message, 1-2 focal elements, no
   decorative glow, no shadows, no rainbow palette, no unreadable edge labels.

## Design Contract

- Use semantic roles instead of random colors: paper, ink, muted, soft, rule,
  accent, accent-tint, and link.
- Use one accent color for the focal path or focal node only.
- Use clean editorial spacing on a 4px grid.
- Keep labels human-readable; reserve monospace for technical fragments like
  ports, URLs, commands, field types, and protocols.
- Prefer direct labels over legends.
- Split diagrams once the reader would need a guide to understand them.
- Mask labels and nodes so arrows do not bleed through text.
- Keep output self-contained so the artifact can be opened locally.

## Completion evidence

A diagram task is complete only when:

- the output file is written under the configured diagram output root,
- the diagram has one explicit title and one primary message,
- source-of-truth exceptions are documented when Mermaid/D2/PlantUML/generated
  graph output is chosen instead,
- the final response links the generated artifact and states which diagram
  grammar was used.
