---
name: harness-executor
description: Automatically route normal repository requests through the agentOS workflow by reading the adapter files first, choosing plan-vs-execution correctly, and enforcing validation/review before completion.
---

# Harness executor

## When to use

Use this skill as the default intake path for ordinary repo work such as:

- implement a feature
- fix a bug
- refactor a subsystem
- investigate behavior
- review a change
- audit MCP or runtime impact

## Workflow

Goal:

- route the request through the repo-local AgentOS adapter and finish with
  recorded evidence.

Success criteria:

- classify the request as explanation, review, implementation, MCP or contract
  change, handoff, or closeout
- use the smallest relevant local context before editing
- create or update an active execution plan before complex, ambiguous, or
  non-trivial code changes
- create or refresh `docs/exec-plans/active/mission.json` before broad, risky,
  architectural, release, or project-level implementation
- run validation and record evidence before claiming completion

Constraints:

- use `harness-planner` when planning is needed
- when the optional `harness-diagnose` skill is available, use it for bug
  reports, failing checks, or unclear regressions before making broad repairs
- use `harness-reviewer`, `harness-runtime-verifier`, or `harness-mcp-auditor`
  when the task needs those proof paths
- add `retain-artifact: relative/path` lines only for evidence that must survive
  cleanup
- rely on the launcher and cleanup wrappers to prune disposable screenshots,
  temporary images, Playwright captures, and delegated run outputs

Evidence required:

- validation evidence
- passing mission proof when Mission Mode is active
- review evidence when required by the harness policy
- completion status in the active execution plan
- retained artifact paths when durable evidence is needed

If the same workflow keeps repeating, convert the method into a shared skill.
If the workflow becomes stable and recurring, turn it into an automation only
after the manual loop is reliable.

## Completion evidence

This skill is complete only when the execution plan contains:

- the validation evidence
- the review evidence
- the completion status
- any retained artifact paths that must survive cleanup
