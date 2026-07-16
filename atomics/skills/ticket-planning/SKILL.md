---
name: ticket-planning
description: "Decompose specs into independently-workable tickets with dependency ordering. Use when breaking a spec into tasks, creating tickets for work, decomposing features into vertical slices, or when someone says 'write tickets for this'. Trigger: tickets, decompose, break into tasks, work breakdown, task graph, what should I work on next."
metadata:
  type: process
  invocation: user-only
  practice: null
---

# Ticket Planning

Decompose a spec into vertical-slice tickets with explicit blocking edges.

## Process

1. **Identify the spec** — read from `.specs/`, PLAN.md reference, or user-provided description
2. **Identify prereqs** — research topics and spikes needed before building (see plan-prereqs)
3. **Decompose into tickets** — each is a vertical slice through all layers
4. **Declare blocking edges** — which tickets must complete before which can start
5. **Write ticket files** — one file per ticket at `.tickets/{NN}-{slug}.md`
6. **Attach to spec** — add Tickets section to the originating spec
7. **Update PLAN.md** — task graph with ticket IDs and work order

## Ticket Sizing Rules

- Each ticket fits in **one fresh context window** — if it wouldn't, split
- Each ticket is **independently demoable** — completing it produces a visible result
- Each ticket is a **vertical slice** — cuts through all layers, not one horizontal layer
- Prereq tickets (research, spikes) come first in the ordering

## Ticket File Format

Write to `.tickets/{NN}-{slug}.md`:

```markdown
---
id: "NN"
title: "Short behavioral title"
status: open
blocked_by: []
spec: "{spec-slug}"
---

# {Title}

## What to build
End-to-end behavior from the user's perspective. NOT implementation steps.

## Context
- Relevant files: {paths that the implementer should read}
- Relevant decisions: {ADRs or spec sections}

## Acceptance criteria
- [ ] Criterion 1 (concrete, testable)
- [ ] Criterion 2

## Research / Spikes (if applicable)
- {question to answer or hypothesis to prove, with time-box}

## Out of scope
- {What this ticket does NOT include}
```

## Triage States

Tickets move through: `open` → `active` → `done` (or `blocked` if waiting on another ticket). The **frontier** is all tickets where `status: open` and all `blocked_by` are `done`.

## After Writing Tickets

1. Update the spec with a `## Tickets` section listing all ticket IDs + titles
2. Update `PLAN.md` task graph: `01-setup → 02-core [P] 03-api → 04-integration`
3. Identify the frontier and propose which ticket to start

## Wide Refactors

For changes that touch many files (renames, retypes), use expand-contract sequencing instead of vertical slices. See [references/wide-refactors.md](references/wide-refactors.md).

## Tool Integration (optional)

If `tk` (wedow/ticket) is on PATH, use it for state transitions:
```bash
tk new "title"              # create
tk start <id>               # claim
tk close <id>               # mark done
tk ready                    # list frontier
tk blocked                  # list blocked tickets
tk dep tree                 # show dependency graph
```

Otherwise, manage status via frontmatter edits directly.

## References

- For wide refactor sequencing, read [references/wide-refactors.md](references/wide-refactors.md)
- For the full ticket file template, read [references/ticket-format.md](references/ticket-format.md)
