---
name: harness-domain-language
description: Maintain repo-local shared vocabulary in CONTEXT.md and suggest ADRs only within execution-plan write boundaries.
---

# Harness domain language

## When to use

Use this skill when repeated terminology, architectural naming, or durable
decisions are causing drift across plans, reviews, code, tests, or docs.

## Workflow

1. Read `repo_harness.toml [engineering_discipline]` for the configured context
   path and ADR directory.
2. Check the active execution plan before editing `CONTEXT.md` or ADR files.
3. Add terms only when they reduce repeated explanation or prevent real
   misunderstanding.
4. Keep domain language short: term, meaning, source of truth, and common
   confusion.
5. Suggest an ADR only for durable architectural decisions, not ordinary task
   notes.
6. Never use this skill to bypass the planned write set or create broad
   documentation churn.

## Completion evidence

This skill is complete only when the handoff records:

- whether `CONTEXT.md` changed
- whether an ADR was added or only suggested
- the execution-plan write-set line that authorized the documentation change
- any domain term that still needs product-owner confirmation
