---
name: harness-mcp-auditor
description: Audit MCP guide-first behavior, curated surface boundaries, manifest expectations, and canonical mutation paths.
---

# Harness MCP auditor

## When to use

Use this skill when a task touches MCP surfaces, tool manifests, auth scope, or
canonical mutation paths.

## Workflow

1. Read the repo MCP contract and guide-first instructions first.
2. Confirm the task is using the smallest allowed MCP surface.
3. Check that the callable tools match the declared manifest and user outcome.
4. Verify read or write boundaries and canonical mutation paths.
5. Call out hidden broad-surface drift, auth leaks, or realtime split-brain risk.

## Completion evidence

An MCP audit should verify:

- guide-first rules
- curated vs broad surface boundaries
- callable tool manifest expectations
- canonical backend and realtime mutation paths
- any residual auth or convergence risk
