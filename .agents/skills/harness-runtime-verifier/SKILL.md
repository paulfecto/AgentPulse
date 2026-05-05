---
name: harness-runtime-verifier
description: Verify runtime claims such as health, affected flow, refresh stability, and convergence.
---

# Harness runtime verifier

## When to use

Use this skill when a change makes a runtime, deploy, health, or user-flow
claim that should not be accepted from static inspection alone.

## Workflow

1. Identify the exact runtime claim from the execution plan.
2. Run the smallest proof that can falsify that claim.
3. Verify the affected flow, not just a generic health endpoint.
4. Check refresh or reload stability when state could drift.
5. Check second-client or cross-surface convergence when relevant.
6. Record the proof in the execution plan.

## Completion evidence

Check and record:

- health
- exact affected flow
- refresh stability
- second-client convergence when relevant
