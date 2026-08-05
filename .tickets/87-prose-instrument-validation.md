---
id: "87"
title: "Validate the prose linter as an instrument (E-INST-1, no agent calls)"
status: done
blocked_by: []
env: either
spec: "eval-harness"
priority: high
---

# Validate the prose linter as an instrument (E-INST-1)

## What to build

Answer whether the STE linter can separate deliberately-written human prose from LLM
first-draft prose on our content types. This decides ticket 84 outright and calibrates every
metric in ticket 88. Costs no agent time and no spend.

Design: `docs/development/prose-hygiene-eval-design-2026-08-05.md` § E-INST-1.
Source + its known flaws: `.memory/specs/ste-prose-hygiene-source.md`.
Instrument: `.references/woosal-blog/videos/ep01-the-cure-for-ai-slop/ste-lint.py`
(clone command is in the source record — `.references/` is gitignored).

## Why this comes first

Preliminary calibration over eight hand-written crew-research files scored 1.97–5.96
violations per 100 words, against the source's AI-slop baselines of 3.54 (gpt-5.5) and 4.36
(Claude). Our best docs already sit inside the slop band, which means an absolute threshold
would flag README.md. If that holds on a larger labeled sample, the linter is a paired
delta probe and never a gate — and ticket 84 should reject adoption on those grounds rather
than tune a threshold.

## Acceptance criteria

- [x] Three labeled sets scored, ~12 docs each: hand-written crew-research prose, LLM first
      drafts of the same doc types, and the source's before/after samples as positive control
- [x] Discrimination reported as distribution overlap between the human and LLM sets — not a
      single mean per set
- [x] Per-category false-positive rates on technical content, with the known suspects checked
      explicitly: unfenced code and CLI output (`strip_code` only handles fenced/inline),
      quoted source text, and deliberate house style (semicolons, contractions)
- [x] Verdict recorded for ticket 84: gate / paired-delta probe only / reject, with the
      overlap numbers as the evidence
- [x] Findings written to `docs/development/` and the design doc's E-INST-1 section updated
      with actuals

## Out of scope

- Any agent generation beyond producing the LLM first-draft set
- Adapting or rewriting the linter (that is ticket 84, and this ticket's result may make it moot)
- Threshold tuning — if the sets overlap, no threshold is defensible at any value

## Resolution (2026-08-05)

REJECT AS GATE. Probability of superiority B-over-A 0.494 all-docs (chance) and 0.26 length-matched: our shipped prose scores DIRTIER than unguided LLM drafts ~3x in 4. No generated doc exceeded our worst shipped doc; AGENTS.md (5.96) was dirtiest in the experiment. Gaps are house style (contractions 0.90 vs 0.49, semicolons 0.80 vs 0.12, passive 0.65 vs 0.46). Set C reproduced the source's published numbers (4.12 vs 4.19), so the instrument is not broken - it does not transfer to already-edited prose. Side findings: em dashes 3x DENSER in our prose than unguided output (2.25 vs 0.77/100w), so the em-dash-as-AI-tell premise fails on our data; vocabulary categories near zero in both sets, so ticket 86 is probably moot. Ticket 84 verdict: reject as gate, paired before/after probe only. Findings: docs/development/prose-instrument-validation-2026-08-05.md; reproduce via tools/evals/experiments/prose-instrument-validation.sh
