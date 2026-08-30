---
id: "146"
title: "Implement the data-modeling skill (create + review modes, references, code-review cross-link, full-tier entry)"
status: open
blocked_by: []
---

# Implement the data-modeling skill (create + review modes, references, code-review cross-link, full-tier entry)

Follow-on to ticket 145 (research + proposal, closed). Research + decisions are in
145's resolution and `.scratch/research/145-*.md` + `.scratch/subagent-raw/145-*.md`.
Read 145's resolution before starting.

## What to build

A new on-demand skill `atomics/skills/data-modeling/` that helps CREATE and REVIEW
data structures so invalid states are unrepresentable. Decision from 145: standalone
skill (NOT always-on steering, NOT a 3rd code-review axis).

1. **SKILL.md** (<100 lines, `type: protocol`, `invocation: both`, `practice: null`)
   - Frontmatter `description` with distinctive triggers (no collisions checked in 145):
     "model this data, data structure, invalid states, make illegal states unrepresentable,
     discriminated union, sum type, enum vs booleans, source of truth, primitive obsession,
     parse don't validate, data-structure review".
   - **Create mode** (authoring): sum types over mutually-exclusive booleans; new-type
     wrappers over primitives; parse-don't-validate at trust boundaries; single source of
     truth in the type shape (no derivable/redundant state).
   - **Review mode** (gate): apply the checklist, end with one verdict line (mirror
     code-review's verdict structure). Gate-shaped ("fix before presenting") per
     eval-proven "gates > suggestions".

2. **references/patterns.md** — per-language sum-type / exhaustiveness / wrapper idioms
   + gotchas (from 145 research):
   - Rust: native enums, compiler-enforced match; reject `_ =>` catch-all.
   - TypeScript: discriminated union on literal tag + `default: assertNever(x)`; verify tsc in CI.
   - Python: `Literal`/`Enum`/`Union` + `assert_never`; STATIC-ONLY — verify a type checker runs in CI.
   - Go: no native sum types — sealed interface (unexported marker) + `go-check-sumtype` linter;
     nil is always an extra invalid state.

3. **references/review-checklist.md** — the ~13-item checklist in two groups:
   - Type-shape (King/Wlaschin): state-count audit, deletable downstream guards, enum-vs-optional-fields,
     boundary parsing, primitive obsession, validating/smart constructors, illegal-transition modeling,
     exhaustive matching.
   - Persistence/schema (normalization lit): one-fact-in-one-place, explicit key/constraint strategy,
     denormalize only after a proven bottleneck, denormalization-drift check.

4. **Cross-link into code-review** — add a pointer from
   `atomics/skills/code-review/references/smells.md` ("for deeper data-modeling review, see the
   data-modeling skill") and DEDUP the Primitive Obsession one-liner to a single owner.
   code-review declares the seam; data-modeling owns the depth.

5. **Tier entry** — add `data-modeling` to `compositions/tiers/full.yaml` under `# Build`
   (peer to code-review/architecture-deepening). NOT basic, NOT project-level.

6. **Deploy + verify** — `mise run validate` (cross-links resolve), `mise run generate`,
   redeploy global, confirm the skill lands and activates.

## Design gate (AGENTS.md 3 questions)

Tension? Mild — create-side nudge vs over-application (turning every bool into an enum). Durable
invariant? No. Rejects a plausible alternative? Yes — rejects "3rd code-review axis" and "always-on
steering" (both reasoned-out in 145). Net: likely build directly; no archwright pipeline needed, but
carry the over-application tension into the eval (ticket 147 task 2).

## Acceptance criteria

- [ ] `atomics/skills/data-modeling/SKILL.md` exists, <100 lines, valid frontmatter, both modes
- [ ] `references/patterns.md` (per-language) + `references/review-checklist.md` (~13 items, 2 groups)
- [ ] code-review cross-link added; Primitive Obsession one-liner dedup'd to one owner
- [ ] added to full.yaml under # Build; `mise run validate` passes
- [ ] deployed + activation smoke-checked (skill triggers on data-modeling phrasings)
- [ ] eval defs are ticket 147's scope (not this ticket)
