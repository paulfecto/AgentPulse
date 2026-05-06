# Agent Pulse Diagram Style Guide

Use this guide for AgentOS diagram-design artifacts under `docs/diagrams`.
Source-of-truth diagrams that need text diffs should stay in Mermaid, D2,
PlantUML, or generated graph formats.

## Purpose

- Prefer diagrams only when they clarify architecture, process, ownership, or
  product flow better than a short paragraph or table.
- Keep each diagram focused on one message with one or two focal elements.
- Build standalone HTML artifacts with inline SVG and CSS unless an execution
  plan explicitly chooses a text-diffable source-of-truth format.

## Visual Language

- Use semantic tokens instead of ad hoc colors:
  - `paper`: `#f8fafc`
  - `ink`: `#172033`
  - `muted`: `#5f6b7a`
  - `soft`: `#e9eef5`
  - `rule`: `#cfd8e3`
  - `accent`: `#2563eb`
  - `accent-tint`: `#dbeafe`
  - `link`: `#4f46e5`
- Use the accent only for the focal path, owner, or state.
- Avoid glow, heavy shadows, rainbow palettes, dense legends, and decorative
  backgrounds.

## Layout

- Use a 4px spacing grid and generous whitespace.
- Prefer direct labels over legends.
- Keep labels short, readable, and outside connector paths.
- Split the diagram when the reader would need more than one pass to understand
  the structure.

## Typography

- Use a plain system sans-serif stack for labels.
- Reserve monospace text for technical fragments such as ports, commands,
  schema fields, URLs, and protocols.
- Do not shrink text below readable UI-documentation sizes to fit too much into
  one diagram.

## Review Checklist

- The title names the diagram's subject.
- The primary message is obvious without a legend.
- The focal element uses the only strong accent.
- The artifact is self-contained and opens locally.
- Any source-of-truth exception is documented in the active execution plan.
