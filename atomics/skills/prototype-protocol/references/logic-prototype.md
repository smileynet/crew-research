# Logic Prototype Reference

## When to Use

- "Does this state machine handle the edge case where X then Y?"
- "Does this data model let me represent the case where..."
- "What should the API shape look like before writing it?"
- Anything where you want to press buttons and watch state change.

## Module Shape Options

Pick based on the question:

| Shape | When |
|-------|------|
| Pure reducer `(state, action) => state` | Discrete events, single state value |
| State machine (explicit states + transitions) | "Which actions are legal right now?" is the question |
| Pure functions over a data type | No implicit current state, just transformations |
| Class with clear method surface | Logic genuinely owns ongoing internal state |

## TUI Pattern

```
┌─────────────────────────────────────┐
│  Current State (pretty-printed)     │
│  field1: value                      │
│  field2: value                      │
│  status: ACTIVE                     │
├─────────────────────────────────────┤
│  [a] add item  [d] delete  [q] quit│
└─────────────────────────────────────┘
```

- Clear screen on every tick (don't append to scrollback)
- Bold field names, dim less-important context
- Keyboard shortcuts listed at bottom
- Whole frame fits one screen

## Isolation Rule

The logic module must be **pure** — no I/O, no terminal code, no console.log for control flow. The TUI imports it; nothing flows back. This is what makes the prototype useful past its lifetime.
