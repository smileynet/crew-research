---
name: architecture-deepening
description: "Find deepening opportunities in a codebase — refactors that turn shallow modules into deep ones. Use when user wants to improve architecture, find refactoring opportunities, consolidate tightly-coupled modules, make code more testable, or reduce complexity. Trigger: \"shallow modules\", \"deepen\", \"architectural friction\", \"consolidate\", \"simplify interfaces\"."
metadata:
  type: protocol
  invocation: both
  practice: null
---

# Architecture Deepening

Surface architectural friction and propose **deepening opportunities** — refactors that turn shallow modules into deep ones. Aim: testability and navigability.

## Vocabulary

Use these terms precisely. Full definitions in [references/vocabulary.md](references/vocabulary.md).

| Term | Meaning |
|------|---------|
| **Module** | Anything with an interface and an implementation |
| **Interface** | Everything a caller must know (types, invariants, error modes, ordering) |
| **Depth** | Leverage at the interface — much behavior behind a small interface |
| **Seam** | Where an interface lives; where behavior can be altered without editing in place |
| **Adapter** | A concrete thing satisfying an interface at a seam |
| **Leverage** | What callers get from depth |
| **Locality** | What maintainers get: change, bugs, knowledge concentrated in one place |

## Key Heuristics

- **Deletion test**: imagine deleting the module. Complexity vanishes → pass-through (shallow). Complexity reappears across N callers → earning its keep (deep).
- **The interface is the test surface.** If you can't test through the interface, the interface is wrong.
- **One adapter = hypothetical seam. Two adapters = real seam.**

## Process

### 0. Specify Desired Outcome (before exploring)

Before diving into code, establish what "better" means in USER terms:
- "When a developer adds a new payment method, they touch only ONE module"
- "When a bug appears in notifications, the search space is 2 files, not 12"
- "When we need to swap the email provider, zero business logic changes"

Write 3+ statements in this form. Get user confirmation before exploring.

### 1. Explore

Read the project's domain glossary (CONTEXT.md) and ADRs first. Then explore organically:

- Where does understanding one concept require bouncing between many small modules?
- Where are modules **shallow** — interface nearly as complex as implementation?
- Where have pure functions been extracted just for testability, but real bugs hide in how they're called (no locality)?
- Where do tightly-coupled modules leak across their seams?

Apply the deletion test to anything you suspect is shallow.

### 2. Present Candidates

For each deepening opportunity:

- **Files** — which modules are involved
- **Problem** — why the current architecture causes friction
- **Solution** — plain English description of what would change
- **Benefits** — in terms of locality, leverage, and how tests improve
- **Strength** — `Strong`, `Worth exploring`, or `Speculative`

Use CONTEXT.md vocabulary for domain terms. Flag ADR conflicts only when friction is real enough to warrant revisiting.

Do NOT propose interfaces yet. Ask: "Which of these would you like to explore?"

### 3. Grilling Loop

Walk the design tree: constraints, dependencies, shape of the deepened module, what sits behind the seam, what tests survive.

**Rubber-stamp guard**: If user accepts 3+ candidates in a row without modification or pushback, PAUSE. Say: "You've accepted 3 in a row — are these genuinely aligned with your priorities, or should I push harder on trade-offs?" Challenge the weakest candidate.

**Side effects during grilling:**
- New module name not in CONTEXT.md? → Add it immediately
- Sharpening a fuzzy term? → Update CONTEXT.md
- User rejects with a load-bearing reason? → Offer an ADR
- Exploring alternative interfaces? → Sketch 2-3 options with trade-offs

## Output Formats

- **Text** (default): numbered list with problem/solution/benefits per candidate
- **Visual report**: self-contained HTML with diagrams — see [diagrams skill](../diagrams/SKILL.md) for Mermaid/C4 patterns

## Anti-Patterns

- Proposing refactors that contradict ADRs without acknowledging the conflict
- Using vague terms ("component", "service", "boundary") instead of the vocabulary
- Suggesting depth where the module genuinely IS simple (not everything needs deepening)
- Refactoring for testability when the real problem is the interface design
