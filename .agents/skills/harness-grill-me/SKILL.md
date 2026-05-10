---
name: harness-grill-me
description: Run an aggressive one-question-at-a-time planning interview until a broad or risky AgentOS task is precise enough to execute.
---

# Harness GrillMe

## When to use

Use this skill before planning or mutation when `[engineering_discipline]` is
enabled and `clarification_mode = "grill-me"`, especially for broad, risky,
ambiguous, architectural, cross-file, or user-facing work.

Do not use it for tiny edits where the missing answer is discoverable by reading
the repo and the write set is already obvious.

## Workflow

1. Inspect the smallest relevant repo context first. Do not ask questions that
   local files, existing plans, schemas, tests, or docs can answer.
2. Build a decision tree for the task:
   - goal and non-goals
   - user-visible behavior
   - data and contract boundaries
   - write-set ownership
   - risk and rollback
   - validation and acceptance
   - deployment, runtime, or operator impact
   - edge cases and failure modes
3. Walk that decision tree one branch at a time.
4. Ask exactly one question at a time and wait for the answer.
5. For every question, include your recommended answer and the consequence of
   accepting it.
6. If the user gives a fuzzy term, propose the precise term and ask whether it
   is correct.
7. If the user's answer conflicts with repo evidence, stop and surface the
   contradiction before continuing.
8. Continue until the plan can name concrete acceptance criteria, owner files,
   non-goals, validation commands, and remaining assumptions.
9. In CI, headless, or non-interactive automation, do not loop forever. Write a
   blocker explaining that GrillMe requires operator input.

## Completion evidence

This skill is complete only when the execution plan or handoff records:

- repo context inspected
- questions asked and answers received
- accepted defaults
- rejected alternatives
- unresolved assumptions or blockers
- final owner files, acceptance criteria, and validation commands
