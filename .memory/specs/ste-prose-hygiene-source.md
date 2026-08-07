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
| Video transcript | `.references/upload/the-cure-for-ai-slop-is-a-1986-aircraft-manual.md` | [L1] first-party (auto-generated captions, cleaned) |
| Kit (skill, linter, data) | https://github.com/woosal1337/blog/tree/main/videos/ep01-the-cure-for-ai-slop | [L1] first-party artifacts + measured data |
| ASD-STE100 Issue 9 | https://asd-ste100.org | [L2] governing specification (copyrighted — do not paste in full) |

Files in the kit: `ste-writing-skill.md` (the distilled skill, two modes),
`ste-lint.py` (deterministic linter), `experiment-results.md` (cross-model),
`experiment-results-openai.md` (per-category), `before-after-samples.md`,
`run-openai.py` (reproduction script). Captured 2026-08-05. Transcript captured 2026-08-07.

## The author's stated argument (from video transcript)

The video makes a narrower, more honest claim than the tickets originally attributed to it:

**Core thesis:** "Give the model a real writing system and slop drops by half or more.
Every time on every model I tried. STE was the best or tied for best. Banning words one at
a time is just a less reliable version of the right idea."

**Explicit scoping (verbatim or near-verbatim):**
- "Use it where invisible clarity is the entire job. Docs, pull requests, error messages,
  agent output, and nowhere else."
- "Keep it away from anything that needs a voice. Running your marketing copy through STE
  is a torque wrench spec applied to a poem."
- "STE fixes the form of slop, not the substance. A linter can turn a hollow paragraph
  into a clean, confident, well-punctuated hollow paragraph. It cannot make it true."
- "Slop is two problems wearing one coat — bad writing and nothing to say. This fixes the
  first one only."
- The 3% banned-words number "was a Claude quirk, not a law of nature" — GPT hit 40%.
- "My linter is not the full standard... the judgment rules are not the slop rules. Slop
  is the mechanical stuff, and the mechanical stuff is 100% checkable."

**His definition of slop** — six specific mechanical habits, not a vague quality judgment:
1. Synonym rotation (same thing, three names in one paragraph)
2. Hedging stacks (five auxiliary verbs, zero action)
3. Nominalization (frozen verbs: "perform an analysis" instead of "analyze")
4. Marketing adjectives (seamless, robust, powerful, cutting-edge)
5. Run-on sentences (four ideas stitched with em dashes and semicolons)
6. Phrasal verbs (spin up, reach out, dive into)

**The em dash point is the opposite of what the tickets assumed.** The author uses the em
dash as his PRIMARY EXAMPLE of the wrong approach: "You banned the em dashes and you got a
slop paragraph with no em dash in it. That's the entire mistake in one data point." He is
arguing AGAINST em-dash banning, not for it.

**The "10-line rule set" endorsement:** He explicitly validates a minimalist alternative —
"One engineer replied... 'STE100 is a bit too much. I wrote a tiny 10-rule set instead.
90% of the benefit.' And he's not wrong — a short checkable rule set is the product."

**Human evidence he cites** (for completeness, not as claims we adopt):
- Sherback, Dury & Volets 1996: 175 aircraft technicians, comprehension 76%→86% (non-native:
  69%→87% — constraint pulled struggling readers up to native level)
- Microsoft Research 2007: 520 sentences translated into 4 languages, controlled beat normal
  in every language (p<0.001); most effective rule was cutting "flowery and formal phrasing"
- Weakening evidence he names himself: translation gains were small (~0.1 on a 4-point
  scale); an Airbus study found oversimplifying can slow readers down; no study measures
  retention, only comprehension

## Relationship to crew-research's JTBD

| Dimension | His audience | Ours |
|-----------|--------------|------|
| Content produced | Human-readable prose (docs, PRs, error messages for end readers) | Agent-readable instructions (skills, steering, eval criteria) |
| Quality signal | Reader experience — no "AI smell" | Agent behavior delta — does loading this change scores? |
| Validation | Linter score delta | Dual-run evals with judged outcomes |
| Cost of "slop" | Credibility loss with human readers | Wasted context tokens, unfocused agent behavior |

**Overlap zone:** we DO produce human-facing prose — READMEs, changelogs, error messages,
PR descriptions. The author explicitly names those as his target. The question is whether
his finding transfers to our content types and our models (ticket 88).

**What we already ship that maps to his recommendation:** our `writing-style` skill IS the
"short checkable rule set" he endorses as "90% of the benefit." What we lack is the
measurement proving ours works — which is what ticket 88 provides.

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
