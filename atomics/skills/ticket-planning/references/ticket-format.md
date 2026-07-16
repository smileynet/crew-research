# Ticket File Format

## Location

`.tickets/{NN}-{slug}.md` — one file per ticket, numbered for ordering.

## Full Template

```markdown
---
id: "NN"
title: "Short behavioral title"
status: open | active | done | blocked
blocked_by: []    # list of ticket IDs that must be done first
spec: "{spec-slug}"
---

# {Title}

## What to build

End-to-end behavior from the user's perspective — NOT implementation steps.
Describe WHAT the system should do, not HOW to build it.
Avoid file paths and line numbers (they go stale). Reference interfaces, types, contracts.

## Context

- **Relevant files:** {paths the implementer should read first}
- **Relevant decisions:** {ADR or spec sections that inform this work}
- **Domain terms:** {any non-obvious vocabulary, link to CONTEXT.md}

## Acceptance criteria

- [ ] Criterion 1 (concrete, testable, independently verifiable)
- [ ] Criterion 2
- [ ] Criterion 3

## Research / Spikes (if applicable)

- **Research:** {question to answer} — method: {web search / codebase / docs}
- **Spike:** {hypothesis to prove} — time-box: {hours} — pass/fail: {criteria}

## Out of scope

- {What this ticket does NOT include}
- {Adjacent work that should be a separate ticket}
```

## Triage States

| Status | Meaning | Enters when |
|--------|---------|-------------|
| `open` | Available for work | Created, unblocked |
| `blocked` | Waiting on dependencies | Any `blocked_by` ticket not done |
| `active` | Currently being worked | Agent/user starts work |
| `done` | Completed, verified | All acceptance criteria pass |

## Principles

- **Behavioral, not procedural** — "User can export CSV" not "add CSV renderer to ExportService"
- **Durable over precise** — interfaces and contracts, not file paths and line numbers
- **One concern per ticket** — if title needs "and", split
- **Acceptance criteria are the contract** — work is done when these pass, nothing more
