---
type: specification
title: "Proof Harness Specification (Phase 1)"
---

# Proof Harness Specification (Phase 1)

## Overview

Empirically validates platform assumptions about how AI coding tools behave. Proofs are declarative and portable — same definitions run against any tool via adapters.

## Directory Structure

```
tools/proofs/
├── adapters/          # per-tool CLI profiles
├── definitions/       # declarative proof specs (YAML)
├── harness/           # bash runner: isolation, invocation, grading
└── results/           # timestamped JSON per run
```

## Proof Definition Format

```yaml
id: A4-file-resource-always-loaded
assumption: "file:// resources are always loaded into agent context"
category: context-loading | skill-activation | agent-isolation | tool-capability

fixtures:
  files:
    context-files/canary.md: "The canary phrase is: CANARY_FILE_7X9Q2"
  agents:
    file-resource-agent:
      tools: []
      resources: ["file://context-files/canary.md"]
      prompt: "Report the canary phrase from your pre-loaded context. Be exact."

query: "What is the canary phrase in your pre-loaded context?"

expect:
  present: ["CANARY_FILE_7X9Q2"]
  absent: []

timeout: 90
```

## Proof Definition Fields

| Field | Required | Description |
|-------|----------|-------------|
| `id` | Yes | Unique identifier (e.g., `A4-file-resource-always-loaded`) |
| `assumption` | Yes | Human-readable statement of what's being proven |
| `category` | Yes | Grouping for filtering |
| `fixtures` | Yes | Files and agents to deploy in the test workspace |
| `query` | Yes | The prompt sent to the agent |
| `expect.present` | No | Strings that MUST appear in output |
| `expect.absent` | No | Strings that MUST NOT appear in output |
| `timeout` | No | Seconds before timeout (default: 90) |

## Harness Behavior

1. Create isolated temp workspace (`mktemp -d`)
2. Deploy fixtures (files, agent configs) per adapter format
3. Invoke agent via adapter with query
4. Strip ANSI codes from output
5. Check `expect.present` (all must match, case-insensitive)
6. Check `expect.absent` (none must match, case-insensitive)
7. Record PASS/FAIL with reason
8. Cleanup temp workspace

## Retry Policy

- 1 retry on empty output or timeout (transient infrastructure failure)
- No retry on non-empty output (agent responded — grade it as-is)

## Result Format

```json
{
  "tool": "kiro-cli",
  "tool_version": "2.3.0",
  "timestamp": "2026-05-18T01:13:58Z",
  "passed": 8,
  "failed": 0,
  "total": 8,
  "tests": [
    {"id": "A4-file-resource-always-loaded", "status": "PASS", "reason": ""}
  ]
}
```

## Result Storage

```
tools/proofs/results/{tool}/{timestamp}.json
```

Keyed by tool + version to enable regression tracking across tool updates.

## Categories of Proofs

| Category | What it validates |
|----------|------------------|
| `context-loading` | Eager vs lazy loading behavior (file://, skill://) |
| `skill-activation` | On-demand skill loading triggers correctly |
| `agent-isolation` | Subagents get own context, not parent's |
| `tool-capability` | Glob patterns, resource cascading, etc. |
