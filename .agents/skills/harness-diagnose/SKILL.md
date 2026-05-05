---
name: harness-diagnose
description: Debug failures through a feedback-loop-first method: reproduce, isolate, change one thing, and prove the fix.
---

# Harness diagnose

## When to use

Use this skill for bug reports, failing checks, broken installs, runtime
failures, flaky behavior, or unclear regressions.

## Workflow

1. Reproduce the failure with the smallest deterministic command available.
2. Capture the exact failing signal before hypothesizing.
3. Classify the failure as product, harness, environment, dependency, or
   missing external access.
4. Form one narrow hypothesis tied to the observed signal.
5. Change the smallest owning surface that can test that hypothesis.
6. Rerun the same command first, then broaden validation only after the narrow
   loop is green.
7. If no deterministic loop can be created, write a real blocker with the
   missing proof surface instead of guessing.

## Completion evidence

The diagnosis is complete only when the active execution plan records:

- original failing command and output summary
- narrowed root cause
- changed files or intentionally unchanged files
- green command that proves the fix
- any broader regression checks that were run or explicitly skipped
