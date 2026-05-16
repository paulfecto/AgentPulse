---
name: harness-planner
description: Turn broad requests into bounded sprints with explicit owner files, acceptance, validation, and runtime impact.
---

# Harness planner

## When to use

Use this skill when a request is broad, ambiguous, risky, or large enough that
implementation should not start from intuition alone.

Apply it before code changes when the task needs a real execution plan with:

- goal
- owner files
- acceptance
- validation
- deploy/runtime impact

## Workflow

1. Read the repo adapter in order before planning.
2. For broad, risky, or ambiguous work, run the repo's configured
   engineering-discipline clarification mode:
   - if `clarification_mode = "grill-me"`, use `harness-grill-me` and do not
     write the execution plan until the interview has resolved the decision
     tree or produced an explicit blocker
   - if `clarification_mode = "bounded-interactive"`, use `harness-clarifier`
     for the smaller bounded pass
   - otherwise inspect discoverable code first, then ask only the question that
     changes the plan or write set
3. Define the target behavior and the non-goals.
4. Bound the write set to the smallest owning files or directories.
5. Name the owning layer and any contract surfaces that will change.
6. Write explicit acceptance criteria and a validation matrix.
7. For broad, risky, architectural, release, or project-level work, mark
   `Mission control` as required and prepare the repo for
   `docs/exec-plans/active/mission.json` before implementation starts.
8. Call out deploy/runtime impact and open risks.
9. Write the plan into the target repo's `docs/exec-plans/active/`.

## Completion evidence

The plan is only good enough when:

- the write set is concrete
- acceptance is testable
- validation is named
- broad/risky/project work has a Mission Mode decision
- uncertainty is either answered or recorded as an explicit assumption
- the repo can tell what would count as completion before edits begin
