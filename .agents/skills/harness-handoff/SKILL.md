---
name: harness-handoff
description: Capture bounded-sprint handoff state, including changed files, verified behavior, remaining work, and runtime state.
---

# Harness handoff

## When to use

Use this skill when closing a bounded sprint, preparing the next thread, or
leaving behind durable state for another operator or agent.

## Workflow

1. Summarize what changed and what did not change.
2. Record exact verified behavior and the commands or proofs that back it.
3. List remaining work and open risks without pretending the sprint is done.
4. Name the exact files and runtime state the next operator must inspect first.
5. Distinguish durable evidence from disposable artifacts before cleanup.

## Completion evidence

Capture:

- what changed
- what is verified
- what remains
- exact files and runtime state
- which artifacts are durable evidence vs disposable transient output
- any `retain-artifact:` paths that must survive cleanup

Before closing the sprint, remove disposable screenshots, temporary images,
Playwright captures, and delegated run outputs unless the user asked to keep
them.
