# Data Modeling — Review Lens

A data-structure review lens. Applied by `code-review`'s Standards axis (alongside the
Fowler smell baseline) or invoked directly against a specific type/schema. It emits
**findings only — no verdict.** `code-review` owns the single merge verdict; run solo,
report a plain assessment, never APPROVED/CHANGES.

## Firing gates (check BEFORE flagging — precision over recall)

Engineers forgive a lens that misses something; they abandon one that cries wolf. A
finding fires only if it passes all of these:

1. **The invariant test (primary gate).** Ask: *what invariant does the domain require
   that this type lets slip, and how could a value reach an illegal state?* If no
   invariant is at risk (`Point { x, y }` — any two ints are legit), **suppress**. If one
   exists (`Money { amount, currency }`, mutually-exclusive flags), fire. Exempt a single
   genuine binary; still fire on *dependent/combination* flags.
2. **NIT-default.** Findings are advisory, phrased "Possible X" — never blocking. A single
   instance stays a NIT; **3+ in one module escalates** to IMPORTANT.
3. **Repo standards override + skip-if-linted.** If a documented convention endorses it, or
   a linter/type checker already enforces it, suppress.
4. **Grounding required.** Cite file:line + the specific rule + a concrete fix. Ungrounded
   "consider an enum" advice is below threshold — suppress. Data modeling is a design/style
   call (judgment, not correctness/security), so it gets NO auto-report override.
5. **No over-modeling.** Do not flag the "When NOT to model harder" cases from SKILL.md
   (genuine binary; private ≤3 sites; wrapper with no benefit; script/prototype; dataless
   two-variant enum). Flagging these provokes premature abstraction — itself a smell.

## Checklist

### Type-shape
1. **State-count audit** — does the type admit combinations the domain forbids (nullable
   pairs, mutually-exclusive booleans, fields valid only in some states)?
2. **Deletable guards** — could a downstream `if x == null` / `assert` be removed if the
   type were more precise?
3. **Enum vs optional fields** — are mutually-exclusive options a variant type rather than
   several optional fields?
4. **Boundary parsing** — is untrusted input parsed into a domain type at the boundary, or
   validated-then-passed-as-primitive?
5. **Primitive obsession** — is a domain concept a bare `string`/`int` that should be a
   wrapper? (Only when it carries an invariant — see gate 1.)
6. **Validating constructors** — do constructors reject invalid values (smart constructor /
   private ctor + factory)?
7. **Illegal transitions** — are state transitions modeled so illegal ones don't compile?
8. **Exhaustive matching** — is the switch/match exhaustive, with no silent catch-all that
   defeats it? (Language-specific — see [patterns.md](patterns.md).)

### Persistence / schema
9. **One fact, one place** — is any datum stored in two places that can disagree?
10. **Key & constraint strategy** — are primary/foreign keys, uniqueness, and not-null
    explicit rather than implied?
11. **Denormalize only after a bottleneck** — is denormalized/duplicated data justified by a
    proven performance need, not convenience?
12. **Denormalization drift** — for any duplicated/derived data, what keeps the copies in
    sync, and can they drift?

## Finding format

```
[NIT] file:line — Possible {issue}: {the invalid state / drift / redundancy it allows}.
  Request: {specific representation change}.
  Reason: {the domain invariant at risk}.
```

Cap at 5 findings. If the representation is sound, say so in one line — do not manufacture
findings.
