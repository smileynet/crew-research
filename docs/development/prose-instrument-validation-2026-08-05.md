---
type: research
title: "E-INST-1 results — the prose linter does not discriminate on our corpus"
---

# E-INST-1 Results — Prose Linter Instrument Validation

Ticket 87. Measured 2026-08-05. Reproduce:
`bash tools/evals/experiments/prose-instrument-validation.sh` (set B generations cache to
`tools/evals/results/prose-instrument-cache/`; `GENERATE=0` re-scores without regenerating).

**Verdict: REJECT AS GATE.** The instrument cannot separate our shipped prose from unguided
LLM first drafts. On length-matched documents it ranks the unguided drafts as *cleaner* than
our shipped docs. It remains valid for its designed use — a within-pair before/after delta on
one text — and that is the only way ticket 84 should consider adopting it.

## Sets

- **A — shipped crew-research prose** (n=13): README, AGENTS.md, two ADRs, CONTEXT.md, two
  research docs, four SKILL.md files, two eager-context modules. Honest label: LLM-drafted,
  human-reviewed, written under our style guidance. Not "human-written".
- **B — unguided LLM first drafts** (n=12): matched content types (README intro and
  quickstart, two error messages, CLI help, changelog, PR description, ADR paragraph, API
  docs, getting-started, deprecation notice, design-doc overview). Prompts carried **no**
  length, tone, or style instruction. `KIRO_HOME` pointed at an empty directory so global
  steering could not leak in — the same isolation the eval harness uses for baseline
  conditions.
- **C — the source's own quoted samples** (n=3): positive control.

## Discrimination

| Measure | All docs | Length-matched (≥100 words) |
|---------|----------|------------------------------|
| A median (violations/100w) | 2.85 | 3.06 |
| B median | 2.42 | **2.16** |
| Probability a random B doc scores worse than a random A doc | 0.494 | **0.26** |
| B docs above A's maximum | 0 | 0 |
| Range overlap | 0.68 | — |

0.5 means no discrimination. The all-docs figure of 0.494 is exactly chance. The
length-matched figure of 0.26 is worse than chance **in the wrong direction**: our shipped
prose scores higher (dirtier) than unguided model output about three times out of four. The
length-matched subset is the trustworthy one — the source warns that per-100-word rates are
noise below ~50 words, and 5 of 12 set-B drafts came in under 100 words.

No set-B document exceeded set A's worst score. Our own AGENTS.md (5.96) is the dirtiest
document in the entire experiment.

## Why our prose scores worse

| Category (per 100w) | A shipped | B unguided |
|---------------------|-----------|------------|
| contraction | 0.90 | 0.49 |
| semicolon | 0.80 | 0.12 |
| passive_voice | 0.65 | 0.46 |
| long_paragraph(>6s) | 0.48 | 0.40 |
| long_sentence(>20w) | 0.39 | 0.46 |
| nominalization | 0.13 | 0.21 |
| banned_word | 0.02 | 0.03 |
| marketing_adjective | 0.04 | 0.03 |

Three of the four largest gaps are deliberate house style: we use contractions, we use
semicolons, and we use passive voice where the actor is genuinely unknown or irrelevant.
The instrument scores our style choices as defects. Only `long_sentence` and
`nominalization` run slightly against us, and both are near the noise floor.

## Two incidental findings that change other tickets

**The em dash is a crew-research tell, not an AI tell.** Our shipped prose carries 2.25 em
dashes per 100 words; unguided LLM drafts carry 0.77 — we use them roughly three times as
densely as the unguided model does. 224 em dashes across 13 shipped files versus 25 across
12 generated ones. Whatever an em-dash ban would accomplish, "making our writing sound less
like AI output" is not it, on this model at this date.

**The vocabulary failure mode is absent from both sets.** Banned words land at 0.02 (A) and
0.03 (B) per 100 words; marketing adjectives at 0.04 and 0.03. Neither our writing nor
unguided generation reaches for utilize/leverage/seamless/robust in any quantity. This is
strong preliminary evidence that ticket 86's substitution table addresses a problem we do
not have — pending confirmation on ticket 88's larger baseline sample.

## The instrument itself is not broken

Set C reproduces the source's published numbers: its quoted baseline README sample scored
4.12 here against 4.19 as published, and its STE samples scored 0.0 and low. The linter
measures what its author says it measures, and it responds to the treatment as reported. The
failure is one of transfer — an instrument calibrated on unguided-versus-STE-rewritten text
does not separate *already-edited* prose from unguided prose, because the categories it
counts are dominated by style conventions rather than by slop.

## Consequences

1. **Ticket 84: reject as a gate.** No absolute threshold is defensible — any cut that
   flags unguided drafts flags README.md and AGENTS.md harder. Adopt only as a paired
   before/after probe on a single text, if at all.
2. **Ticket 88 keeps its within-pair-delta-only design.** This result is the evidence for
   that constraint rather than a precaution.
3. **Ticket 83's em dash rule loses its stated rationale entirely** — it was already not an
   STE rule, and it now also fails as an AI-detection signal on our own measurements.
4. **Ticket 86 is probably moot.** Confirm on ticket 88's baselines, then close as
   not-applicable rather than build a table for an absent failure mode.
5. **A genuine open question this surfaced:** are our contractions, semicolons, and passive
   voice good style or unexamined habit? This experiment cannot answer that — the linter has
   no opinion worth trusting here, and the question needs judged clarity, not violation
   counts. It belongs in ticket 88's substance readout, not in a linter threshold.

## Limits of this result

- n=13 and n=12, single generation per prompt, one model family (whatever kiro-cli's `auto`
  selected). The direction is strong and the length-matched effect is large, but this is one
  data point on one corpus.
- Set A is not a human-written control. It is *reviewed* prose. A true human-written control
  would need prose written without model assistance, which we largely do not produce.
- Set C is n=3 extracted blockquotes, adequate as a sanity check and nothing more.
