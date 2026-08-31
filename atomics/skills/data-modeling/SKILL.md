---
name: data-modeling
description: "Design and review data structures so invalid states are unrepresentable. Use when modeling domain data, choosing a representation, adding a field/state, or reviewing types/schemas for invalid states, multiple sources of truth, or drift-prone denormalization. Trigger: model this data, data structure, invalid states, make illegal states unrepresentable, discriminated union, sum type, enum vs booleans, source of truth, primitive obsession, parse don't validate, data-structure review."
metadata:
  type: reference
  invocation: both
  practice: null
---

# Data Modeling

Representation shapes implementation. Model the domain so invalid states can't be
constructed — push validity into the type and the downstream guards disappear. Bad
representation is where slop starts and it compounds: each new state multiplies the
call sites you must touch, and every site is one an agent can forget.

## Create side — four moves

1. **Sum types over mutually-exclusive booleans.** `held: bool + sold: bool` permits the
   illegal `held && sold` state; a variant type (`Open | Held | Sold`) makes it
   structurally impossible. Model lifecycles this way so illegal transitions don't
   compile, and let the variant *carry* its data (a `Held` case holds the expiry; `Open`
   doesn't).

2. **New-type wrappers over primitives.** `EmailAddress` / `UserId`, not raw `string` /
   `int`. A primitive holds anything; a wrapper holds only valid values.

3. **Parse, don't validate — at the boundary.** Parse untrusted input once into a precise
   type that is valid by construction, so nothing downstream re-checks it. A validator
   that returns `bool` throws away what it learned; a parser returns the refined type.
   An unvalidated wrapper is theater.

4. **Single source of truth in the type shape.** No derivable or redundant state — an
   O(1) count beside the collection it counts is a second source that can drift. Store
   the fact once; derive the rest.

Per-language mechanisms (enums/unions, exhaustiveness, wrappers) and the gotchas that
silently defeat them: see [references/patterns.md](references/patterns.md).

## When NOT to model harder

The counter-risk is reflexive over-modeling (Goedecke, *"make invalid states
unrepresentable" considered harmful*; Google dropped proto3 `required`). Code should
often be *more* flexible than the domain. Do **not** reach for a richer type when:

- It's a genuine binary with no foreseeable third state.
- It's private/internal with ≤3 usage sites.
- The wrapper buys no validation, unit-safety, or exhaustiveness benefit
  (`Point { x, y }` — any two ints are legitimate).
- It's a script, migration, or prototype with a short lifespan.
- A two-variant enum would carry no data and map 1:1 to true/false.

The line: exempt a *single* genuine binary, but still fix *dependent or combination*
flags (the `held + sold` pair) — those are the real smell, not the lone bool.

## Review side

To audit an existing structure — or when `code-review`'s Standards axis pulls this in —
apply [references/review-lens.md](references/review-lens.md). It carries the
false-positive gates (fire only when the domain has an invariant the type lets slip)
and the checklist. The lens emits findings only; it never issues its own verdict —
`code-review` owns the single merge verdict.

## Scope

Does NOT run a whole-diff review or emit APPROVED/CHANGES — that is `code-review`.
This skill teaches representation design and supplies the data-structure review lens.
