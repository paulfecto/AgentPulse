---
name: harness-reviewer
description: Review changes against the global harness rules for source-of-truth, convergence, and validation completeness.
---

# Harness reviewer

## When to use

Use this skill when reviewing a change for correctness, drift, or false
completion claims.

## Workflow

1. Read the active execution plan and the repo-local source-of-truth files.
2. Look for violations of one source of truth, projection drift, or incomplete
   mutation paths.
3. Use lightweight architecture vocabulary when it helps: deep modules should
   hide meaningful complexity behind narrow interfaces; shallow modules,
   scattered locality, and wide interfaces are review risks.
4. Check that validation evidence actually matches the changed behavior.
5. Prefer findings-first output ordered by severity.
6. Call out missing tests, missing docs, hidden regressions, and false claims of
   completion.

## Completion evidence

A review using this skill should explicitly cover:

- one source of truth
- canonical mutation result
- projection stability
- module depth, locality, and interface depth when architecture is relevant
- runtime validation completeness
- any unresolved findings that block completion
