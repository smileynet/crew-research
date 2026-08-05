---
id: "88"
title: "Cross-model writing-system experiment (E-SYS-1) + substance and mode readouts"
status: open
blocked_by: ["87"]
env: either
spec: "eval-harness"
---

# Cross-model writing-system experiment (E-SYS-1)

## What to build

The experiment that decides the prose arc. Five prompt regimes × six of our real content
types × 3 trials × 2–3 adapters, scored on form (deterministic) and substance
(independently judged). Three later questions read out of the same retained outputs at no
extra generation cost.

Design: `docs/development/prose-hygiene-eval-design-2026-08-05.md` (§ E-SYS-1, E-SUB-1,
E-MODE-1, E-VOCAB-1). Shape: `tools/evals/experiments/` — the harness's `conditions` map to
skill sets, and these five are prompt regimes, not skills.

Conditions: `baseline`, `ban-words`, `orwell`, `ste-flavored`, `ste-strict`.
Tasks: error message, CLI help text, changelog entry, README section, PR description, ADR
paragraph — each carrying an explicit required-fact checklist for the substance readout.

## Three rules the measurement must respect

1. **Never score a rule set with its own rubric.** The linter's categories are the STE
   rules, so STE grades its own homework. Every form measure pairs with an independently
   judged measure that shares no rule vocabulary.
2. **Within-pair deltas only** — same task, same model, same trial count. Absolute linter
   scores are not comparable across content types (ticket 87 establishes why).
3. **Report absolute violations and word count next to the per-100-word rate**, and keep
   `long_paragraph(>6s)` out of the headline. The source's treatment cut words 30% (a rate
   metric rewards shortening for free) and that one category rose under the treatment
   (0.31→0.88), causing its only regression.

## Acceptance criteria

- [ ] E-SYS-1: form deltas per condition per adapter, with trial variance stated; verdict on
      whether any regime separates from baseline outside variance
- [ ] Cross-model result on `ban-words` specifically — the source measured 3% on Claude and
      40% on gpt-5.5, so a single-model result here would repeat its central mistake
- [ ] E-SUB-1: fact-retention scores per condition (facts retained / facts required), judged
      with `eval-criteria` rubric structure. This is the decisive one for ticket 83
- [ ] E-MODE-1: strict vs flavored broken out by procedural vs prose content type, with a
      verdict on whether the interaction justifies two modes (ticket 85)
- [ ] E-VOCAB-1: `banned_word` and `marketing_adjective` counts in `baseline` outputs, with a
      verdict on whether ticket 86's failure mode exists in our generations at all
- [ ] Judge panel state recorded per ADR 0010 — a degraded single-family panel must be
      flagged, since family affinity (~3–9%) sits inside the effect size being chased
- [ ] Run in background per `.kiro/steering/eval-execution.md`; never edit the harness mid-run

## Decision this ticket produces

- Form improves, retention flat → adopt rules in writing-style (ticket 83 proceeds, corrected)
- Form improves, retention drops under strict → adopt for bounded procedural text only
- No form improvement outside variance → reject the arc; record why so it is not re-proposed

## Out of scope

- Em dash: not an STE rule and not tested by the source. Separate question, separate before/after
- Adopting the source's 50–74% figure as ours — it is a foreign-corpus, own-rubric, n=6 result
