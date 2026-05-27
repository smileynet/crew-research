---
name: prototype-protocol
description: >
  Build throwaway prototypes that answer a specific design question. Use when
  user wants to prototype, sanity-check a data model, explore UI options, test
  a state machine, or says "let me play with it." Routes between logic (TUI)
  and UI (multi-variant page) branches.
metadata:
  type: protocol
  invocation: both
  practice: null
---

# Prototype Protocol

A prototype is **throwaway code that answers a question**. The question decides the shape.

## Pick a Branch

Identify which question is being answered:

- **"Does this logic/state model work?"** → Logic branch. Build a tiny interactive terminal app that pushes the state machine through cases hard to reason about on paper.
- **"What should this look like?"** → UI branch. Generate several radically different UI variations on a single route, switchable via URL param.

If ambiguous: backend module → logic; page/component → UI. State the assumption.

## Rules (Both Branches)

1. **Throwaway from day one.** Name it so readers know it's a prototype, not production.
2. **One command to run.** Use the project's existing task runner.
3. **No persistence by default.** State lives in memory.
4. **Skip the polish.** No tests, no error handling beyond runnable, no abstractions.
5. **Surface the state.** After every action, print/render the full relevant state.
6. **Capture the answer.** The answer is the only thing worth keeping — commit message, ADR, or NOTES.md.
7. **Delete or absorb when done.** Don't leave prototypes rotting in the repo.

## Logic Branch (TUI State Explorer)

1. State the question explicitly (top-of-file comment)
2. Isolate logic in a **portable pure module** (reducer, state machine, or pure functions) — no I/O
3. Build the thinnest TUI shell: clear screen, render state, show keyboard shortcuts, loop
4. Hand over the run command — user drives it
5. Capture what was learned; delete the TUI shell, keep the logic module if validated

See [references/logic-prototype.md](references/logic-prototype.md) for detailed TUI patterns.

## UI Branch (Multi-Variant Page)

1. State the question and pick N variants (default 3, max 5)
2. Generate **structurally different** variants (different layout, hierarchy, affordance — not just colors)
3. Wire with `?variant=` URL param + floating switcher bar
4. Prefer embedding in an existing page (sub-shape A) over a new throwaway route (sub-shape B)
5. User picks a winner or combines elements; delete losers, fold winner into real code

See [references/ui-prototype.md](references/ui-prototype.md) for switcher implementation.

## Anti-Patterns

- Variants that differ only in color/copy (that's a tweak, not a prototype)
- Adding tests to prototype code
- Wiring to real mutations or databases
- Generalizing ("what if we wanted X later")
- Promoting prototype directly to production without rewriting
- Leaving prototypes in the repo after the question is answered

## When Done

Write down: **what question was asked** and **what answer was found**. This goes in a commit message, ADR, issue, or NOTES.md. Then delete the prototype artifacts.
