---
name: harness-clarifier
description: Run bounded clarification for broad, risky, or ambiguous AgentOS tasks before planning or mutation.
---

# Harness clarifier

## When to use

Use this skill when a request is broad, risky, ambiguous, or likely to mutate
contract surfaces before the repo has enough local truth.

Do not use it for small changes where the answer is discoverable by reading the
repo and running the normal harness gates.

## Workflow

1. Inspect the smallest relevant local context first when it is discoverable.
2. State the exact uncertainty that still changes the plan or write set.
3. Ask one question at a time.
4. Prefer questions with a concrete default and a consequence.
5. Stop asking when the remaining uncertainty can be safely handled by an
   explicit assumption in the execution plan.
6. In CI, headless, or automation contexts, do not enter an unbounded
   interactive loop. Record the assumption or blocker instead.

## Completion evidence

This skill is complete only when the execution plan or handoff records:

- what context was inspected
- the unresolved question or assumption
- the selected default or user answer
- why more questioning is not blocking progress
