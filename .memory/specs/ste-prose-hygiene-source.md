---
type: spec
title: "STE prose-hygiene source material (woosal ep01) — captured record"
---

# STE Prose-Hygiene Source Material — Captured Record

Tracked capture of the material behind tickets 83–86. The working copy lives at
`.references/woosal-blog/` which is **gitignored**, so this file — not the clone — is the
citable record. Re-obtain the clone with:

```bash
git clone --depth 1 https://github.com/woosal1337/blog.git .references/woosal-blog
# material: .references/woosal-blog/videos/ep01-the-cure-for-ai-slop/
```

## Sources

| Source | URL | Authority |
|--------|-----|-----------|
| Episode video | https://www.youtube.com/watch?v=uJblcC4lKYw | [L5] informed commentary |
| Kit (skill, linter, data) | https://github.com/woosal1337/blog/tree/main/videos/ep01-the-cure-for-ai-slop | [L1] first-party artifacts + measured data |
| ASD-STE100 Issue 9 | https://asd-ste100.org | [L2] governing specification (copyrighted — do not paste in full) |

Files in the kit: `ste-writing-skill.md` (the distilled skill, two modes),
`ste-lint.py` (deterministic linter), `experiment-results.md` (cross-model),
`experiment-results-openai.md` (per-category), `before-after-samples.md`,
`run-openai.py` (reproduction script). Captured 2026-08-05.

## What the author measured

6 engineer-writing tasks (README, PR description, API docs, error message,
getting-started, deprecation) × 4 conditions (baseline, banned-words list, Orwell's 6
rules, STE skill) × 2 model families (Claude Sonnet via headless CLI, gpt-5.5 via API).
Metric: **linter violations per 100 words**, length-normalized. Lower is cleaner.

| Condition | Claude Sonnet | gpt-5.5 |
|-----------|---------------|---------|
| baseline | 4.36 | 3.54 |
| banned-words list | 4.21 (−3%) | 2.14 (−40%) |
| Orwell's 6 rules | 2.48 (−43%) | 1.69 (−52%) |
| STE skill | **1.12 (−74%)** | 1.76 (−50%) |

## What the linter actually counts

Eleven categories, summed then normalized per 100 words: `long_sentence(>20w)`,
`semicolon`, `contraction`, `passive_voice`, `ing_main_verb`, `nominalization`,
`phrasal_verb`, `banned_word` (a 45-entry list incl. utilize/leverage/ensure/
comprehensive/additionally), `marketing_adjective` (26 entries), `modal_hedge`,
`long_paragraph(>6s)`. Fenced and inline code are stripped before scoring.

**Em dashes are counted and reported SEPARATELY as `em_dash(slop-marker)` and are NOT
part of the violation total.**

## Corrections to how this material has been characterized

Three claims attached to this source in our tickets do not survive reading it:

1. **STE does not ban the em dash.** The skill file says so explicitly: "the em dash is
   not banned by STE, only the semicolon is — add 'no em dash' yourself if you want it
   gone." The linter treats it as an unscored marker. An em-dash ban is an addition
   someone could choose to make, not an STE rule and not something the data tested.
2. **"Banning words does nothing" is model-specific, and the author says so.** It cut 3%
   on Claude and 40% on gpt-5.5. The author's own honest-part section calls the vivid
   version "a Claude artifact."
3. **The 50–74% figure is a linter-score delta, not a quality measurement.** The author
   states the limits plainly: heuristic linter, n=6, two models, single run per cell,
   "directional, not proof", and "STE fixes the FORM of slop, not the substance. It
   cannot make a hollow paragraph true."

## Known validity problems (ours, not the author's)

- **Scoring circularity.** The linter's 11 categories map one-to-one onto the STE
  skill's own rules. The STE condition is graded by its own rubric while Orwell and
  banned-words are graded by someone else's. Some of STE's margin is teaching to the
  test — unavoidable in a first data point, but it must be broken before we adopt
  anything on the strength of it.
- **One category penalizes the treatment.** `long_paragraph(>6s)` counts paragraphs over
  six sentences. STE produces many short sentences, so paragraphs cross the threshold
  faster: it rose 0.31 → 0.88 under STE on gpt-5.5, and is why STE scored *worse* than
  baseline on one of six tasks (API docs, 3.95 vs 3.54).
- **Word-count confound.** STE cut total words 649 → 454 (−30%). A per-100-word metric
  normalizes rate but not information content; nothing in the experiment checks whether
  the shorter text still answered the task.
- **Short-output noise.** On 17–31-word deprecation notices, one violation reads as
  8–12 per 100 words. The author flags this and says to trust the longer tasks.

## Calibration against our own corpus (measured 2026-08-05)

Their linter, unmodified, over hand-written crew-research content:

| File | words | per 100w | em dashes |
|------|-------|----------|-----------|
| README.md | 610 | 1.97 | 20 |
| AGENTS.md | 671 | 5.96 | 60 |
| writing-style/SKILL.md | 254 | 2.76 | 2 |
| code-review/SKILL.md | 399 | 2.01 | 10 |
| verification-protocol/SKILL.md | 246 | 2.85 | 7 |
| adr/0010-judge-tier-policy.md | 1061 | 3.20 | 20 |
| docs/…/cross-family-judging | 1571 | 3.06 | 41 |
| docs/…/model-positioning | 1156 | 4.24 | 26 |

Three consequences:

1. **Our hand-written docs score inside their AI-slop baseline band** (1.97–5.96 vs
   baselines of 3.54 and 4.36). The instrument does not separate our content from
   generated slop, so an absolute threshold would flag our best work. It is usable as a
   **within-pair delta** (lint a draft, apply a rule set, re-lint) — which is exactly
   what the author recommends — and not as a quality gate.
2. **The vocabulary categories never fire on us.** Zero banned words across all eight
   files; one marketing adjective, and it is a false positive — "next-generation" inside
   a verbatim quote of Anthropic's own product copy. A substitution table (ticket 86)
   targets a failure mode our corpus does not exhibit.
3. **What does fire is deliberate house style**: semicolons (10 in AGENTS.md, 15 in the
   positioning doc), contractions (7 and 7), long paragraphs, and passive voice. Adopting
   these rules as-is means either changing house style on purpose or running an
   instrument that reports style choices as defects.
