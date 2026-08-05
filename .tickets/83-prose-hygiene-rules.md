---
id: "83"
title: "Add prose hygiene rules to writing-style (STE-inspired)"
status: open
blocked_by: ["88"]
env: either
spec: "eval-harness"
---

# Add prose hygiene rules to writing-style (STE-inspired)

## What to build

Add prose-specific rules to the `writing-style` skill, complementing the code-focused
`ai-generation-hygiene` (which covers P1–P9 for code and has zero prose coverage). Which
rules, and whether any of them earn their place, is decided by ticket 88's data — this
ticket applies a result, it does not assume one.

Source record and its limits: `.memory/specs/ste-prose-hygiene-source.md`.
Eval design: `docs/development/prose-hygiene-eval-design-2026-08-05.md`.

## Corrections to this ticket's original premises

Three claims in the first draft of this ticket do not survive reading the source or checking
our own corpus. Recorded here so they are not re-introduced:

1. **The em dash is not an STE rule.** The source skill says so explicitly and its linter
   reports em dashes *outside* the violation total. A ban is a house-style preference with a
   718-occurrence blast radius across `atomics/` (57 of 60 skill files, 60 in AGENTS.md). It
   needs its own question and its own before/after judged comparison — not a ride-along
   inside a ticket justified by STE data.
2. **writing-style already has banned patterns** — filler openers, hedging stacks, narrating
   the obvious, emphasis inflation. The real gap is narrower than "zero mechanical rules":
   those four exist but are not lintable.
3. **"Banning words does nothing" is model-specific.** 3% on Claude, 40% on gpt-5.5, per the
   source's own honest-part section. Any rule shipped on that basis must hold across adapters.

## Acceptance criteria

- [ ] Rules added are the ones ticket 88 measured as effective — each traceable to a
      measured form delta AND flat fact retention, not to the source's headline figure
- [ ] Any rule that improved form while costing substance is scoped to bounded procedural
      text (error messages, CLI help), not applied to prose
- [ ] Rules stated concretely enough to be checkable, with the full pattern list in
      `references/` if it pushes SKILL.md past 100 lines
- [ ] An effectiveness eval definition exists for the added rules (dual-run, per AGENTS.md's
      "add an eval definition if behavior is measurable"). The original AC named a
      writing-style activation eval — no such definition exists; only
      `activation-presentation-writing` and `activation-readme-writing` do
- [ ] Rules that measured no effect are recorded as rejected in the Resolution, so a later
      session does not re-propose them from the same source

## Out of scope

- Em dash ban (own question — see corrections above)
- Building or adopting a linter (ticket 84, gated on 87's instrument verdict)
- Multi-mode support (ticket 85, answered by 88's mode readout)
- Substitution table (ticket 86, may be moot — 88's vocabulary readout decides)
- Full ASD-STE100 vocabulary lockdown (too restrictive for general use)
