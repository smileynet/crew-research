---
name: architecture-deepening
description: "Find deepening opportunities and run architecture review sessions — refactors that turn shallow modules into deep ones, plus the acceptance loop where the user approves or rejects refactoring candidates. Use when improving architecture, consolidating tightly-coupled modules, reducing complexity, or mid-review when the user accepts/approves candidates (\"accept candidate 3\", \"looks good, keep it\", \"sounds right\"). Trigger: \"shallow modules\", \"deepen\", \"architectural friction\", \"consolidate\", \"simplify interfaces\", \"refactoring review\", \"accept candidate\", \"approve this refactor\", \"architecture review\"."
metadata:
  type: protocol
  invocation: both
  practice: null
---

# Architecture Deepening

Surface architectural friction and propose **deepening opportunities** — refactors that turn shallow modules into deep ones. Aim: testability and navigability.

## MANDATORY GATE: Rubber-Stamp Rejection

Track acceptance streaks throughout any review session. When the user accepts **3+ candidates in a row without modification or pushback**, you MUST NOT record the latest acceptance. Instead:

1. **Hard pause** — decline to lock in the candidate. Name the pattern: "That's N acceptances in a row without modification."
2. **Challenge the weakest candidate** with a concrete trade-off or counter-argument (e.g., speculative generality, lost locality, domains that only look similar).
3. **Ask for reasoning** — "What made candidate N right for you?" or "Are these aligned with your priorities, or should I push harder on trade-offs?"

Only proceed after the user engages with at least one challenge. Fast agreement is a signal of rubber-stamping, not alignment — an unexamined acceptance is worth less than a considered rejection.

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

Walk the design tree: constraints, dependencies, shape of the deepened module, what sits behind the seam, what tests survive. The Rubber-Stamp Rejection gate (above) applies to every acceptance in this loop.

**Side effects during grilling:**
- New module name not in CONTEXT.md? → Add it immediately
- Sharpening a fuzzy term? → Update CONTEXT.md
- User rejects with a load-bearing reason? → Offer an ADR
- Exploring alternative interfaces? → Sketch 2-3 options with trade-offs
- Friction traces to an unresolved design-level tension (not module shape)? → If archwright skills are available, recommend `archwright-resolve` for the tension; code-level deepening stays here

## Output Formats

- **Text** (default): numbered list with problem/solution/benefits per candidate
- **Visual report**: self-contained HTML with diagrams — see [diagrams skill](../diagrams/SKILL.md) for Mermaid/C4 patterns

## Anti-Patterns

- Proposing refactors that contradict ADRs without acknowledging the conflict
- Using vague terms ("component", "service", "boundary") instead of the vocabulary
- Suggesting depth where the module genuinely IS simple (not everything needs deepening)
- Refactoring for testability when the real problem is the interface design
