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
2. For non-trivial review, use the latest AgentOS review cycle when present:
   `docs/exec-plans/active/review-cycles/{plan-stem}/latest.json` points to
   the regenerated `review-context.md`, `pr-body.md`, `review-comments.md`,
   and `review-verdict.md`. If no review cycle exists for a broad or risky
   change, run or ask for `prepare_review_cycle.py` before reviewing, or
   explicitly record why review grounding was skipped.
3. Treat `review-context.md` as generated grounding only. The active execution
   plan, repo source files, `code_review.md`, `CONTEXT.md`, and ADR/convention
   files remain the source of truth.
4. Look for violations of one source of truth, projection drift, or incomplete
   mutation paths.
5. Use lightweight architecture vocabulary when it helps: deep modules should
   hide meaningful complexity behind narrow interfaces; shallow modules,
   scattered locality, and wide interfaces are review risks.
6. Check that validation evidence actually matches the changed behavior.
7. Prefer findings-first output ordered by severity.
8. Add an explicit review verdict: `accept`, `reject`, or `needs-work`, with
   rationale, blocking items, accepted items, rejected items, and QA notes.
9. Copy unresolved blockers back into the active execution plan's review
   evidence before completion can be claimed.
10. Call out missing tests, missing docs, hidden regressions, and false claims of
   completion.

## Completion evidence

A review using this skill should explicitly cover:

- one source of truth
- canonical mutation result
- projection stability
- module depth, locality, and interface depth when architecture is relevant
- runtime validation completeness
- review-context artifact used or explicit reason it was skipped
- review verdict and rationale
- any unresolved findings that block completion
