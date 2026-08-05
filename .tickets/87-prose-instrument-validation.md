---
id: "87"
title: "Validate the prose linter as an instrument (E-INST-1, no agent calls)"
status: open
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

- [ ] Three labeled sets scored, ~12 docs each: hand-written crew-research prose, LLM first
      drafts of the same doc types, and the source's before/after samples as positive control
- [ ] Discrimination reported as distribution overlap between the human and LLM sets — not a
      single mean per set
- [ ] Per-category false-positive rates on technical content, with the known suspects checked
      explicitly: unfenced code and CLI output (`strip_code` only handles fenced/inline),
      quoted source text, and deliberate house style (semicolons, contractions)
- [ ] Verdict recorded for ticket 84: gate / paired-delta probe only / reject, with the
      overlap numbers as the evidence
- [ ] Findings written to `docs/development/` and the design doc's E-INST-1 section updated
      with actuals

## Out of scope

- Any agent generation beyond producing the LLM first-draft set
- Adapting or rewriting the linter (that is ticket 84, and this ticket's result may make it moot)
- Threshold tuning — if the sets overlap, no threshold is defensible at any value
