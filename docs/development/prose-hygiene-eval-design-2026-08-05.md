---
type: research
title: "Prose hygiene eval design — what would prove or disprove the STE claims"
---

# Prose Hygiene Eval Design

Designs measurements that produce data on tickets 83–86 instead of adopting the source's
conclusions. Source record and its known limits: `.memory/specs/ste-prose-hygiene-source.md`.

The arc currently proposes five things. Exactly one of them has evidence behind it, one is
already contradicted by our own corpus, one is not an STE rule at all, and two are
untested in either direction:

| Proposal | Ticket | Evidence status going in |
|----------|--------|--------------------------|
| A writing system reduces slop | 83 | Measured by the author (−50 to −74%), single run per cell, n=6, own-rubric scoring |
| Deterministic prose linter as a gate | 84 | Instrument exists; **our calibration shows it cannot separate our hand-written docs from AI slop** |
| Em dash ban | 83 | **Not an STE rule** — the source excludes em dashes from its violation total and says so explicitly |
| Strict vs flavored modes | 85 | Untested — the source ships both modes but never compared them |
| Slop-word substitution table | 86 | **Zero banned words fire on our corpus**; the effect it targets may not exist here |

## Three design constraints, each from a measured flaw

**1. Never score a rule set with its own rubric.** The linter's 11 categories map one-to-one
onto the STE skill's rules, so the STE condition grades its own homework while the
comparison conditions do not. Every eval below pairs the deterministic form metric with an
independent LLM-judged measure that has no rule vocabulary in common with it.

**2. Absolute linter scores are not gates.** Our hand-written docs score 1.97–5.96 per 100
words against the source's AI baselines of 3.54 and 4.36 — inside the same band. Any
threshold that flags slop flags README.md. All linter use is **within-pair delta on the
same task and same model**, which is what the source itself recommends.

**3. Control for length and for the self-penalizing category.** The treatment cut word count
30% (649→454), and a per-100-word rate rewards shortening for free; report absolute
violations and word count alongside the rate. Report `long_paragraph(>6s)` separately from
the headline: it *rose* under STE (0.31→0.88) and caused the source's one regression, so
folding it into a total hides the treatment's real effect in an instrument artifact.

## E-INST-1 — Is the instrument fit for anything? (run first, no agent calls)

**Question.** Does the linter separate deliberately-written human prose from LLM first-draft
prose on our content types?

**Design.** Three labeled sets, ~12 documents each, scored unmodified: (a) hand-written
crew-research prose (partly collected — the eight files in the source record), (b) LLM
first drafts of the same doc types with no writing guidance, (c) the source's own
before/after samples as a positive control.

**Predictions.** If the instrument is valid, set (b) scores materially above (a) with little
overlap. If distributions overlap — which the eight-file sample already suggests — the
metric is delta-only and **ticket 84 must reject the linter as a gate**, keeping it as a
paired A/B probe.

**Also produces:** per-category false-positive rates on technical content. Known suspects:
code that is not fenced (`strip_code` only removes fenced and inline spans), quoted source
text (our one marketing-adjective hit is "next-generation" inside a verbatim Anthropic
quote), semicolons and contractions that are deliberate house style.

**Gate:** the discrimination result decides 84 outright. No agent time, no spend.

**RESULT (2026-08-05, ticket 87): REJECT AS GATE.** Probability of superiority 0.494 across
all docs (exactly chance) and **0.26 length-matched — our shipped prose scores dirtier than
unguided LLM drafts about three times in four**. No generated doc exceeded our worst shipped
doc; AGENTS.md (5.96) was the dirtiest document in the experiment. The gaps are house style:
contractions 0.90 vs 0.49, semicolons 0.80 vs 0.12, passive voice 0.65 vs 0.46. Set C
reproduced the source's published figures (4.12 vs 4.19 published), so the instrument works
as designed — it just does not transfer to already-edited prose. Two side findings: em dashes
are 3× denser in our prose than in unguided output (2.25 vs 0.77 per 100w), and the
vocabulary categories are near zero in both sets. Full write-up:
`docs/development/prose-instrument-validation-2026-08-05.md`.

## E-SYS-1 — Does a writing system reduce slop on our content? (the headline claim)

**Question.** On our content types and our models, does any writing instruction reduce
measured form violations against an unguided baseline?

**Design.** Five conditions × six tasks × 3 trials × 2–3 adapters (kiro-cli, codex, crush
— cross-model is mandatory, see below). Conditions: `baseline` (no guidance),
`ban-words` (list only), `orwell` (6 rules), `ste-flavored`, `ste-strict`. Tasks drawn
from what we actually produce: an error message, CLI help text, a changelog entry, a README
section, a PR description, an ADR paragraph. Shape: `tools/evals/experiments/`, not a
harness definition — the harness's conditions map to *skill sets*, and these five are
prompt regimes.

**Predictions if the claim is real.** `ste-*` and `orwell` both cut form violations ≥30%
vs baseline, outside trial variance. `ban-words` is inconsistent *across adapters* — this
is the source's own strongest honest finding (3% on Claude, 40% on gpt-5.5) and it is the
cheapest thing to replicate or break.

**Disproof.** No condition separates from baseline once 3 trials of variance are accounted
for; or the ordering is unstable across adapters, in which case there is no portable rule
to ship in a skill.

**Why cross-model is not optional.** Ticket 86 exists because of a Claude-specific artifact
in the source. If we measure on one model we will make the same mistake with our own data.

## E-SUB-1 — Does better form cost substance? (the measurement nobody has made)

**Question.** When the form metric improves, does the output still carry the required
information?

This is the gap the source names and does not test: "STE fixes the FORM of slop, not the
substance." Combined with a 30% word-count drop, an unexamined possibility is that some of
the improvement is information loss.

**Design.** Reuse E-SYS-1's outputs — no extra generation. Each task carries an explicit
fact checklist (the error message must name the file, the cause, and the fix; the changelog
entry must name the user-visible change and the affected version). Score = facts retained
out of facts required, judged, with the rubric written per `eval-criteria` conventions
(PRIMARY / AUTOMATIC FAIL / 3 / 4 / BONUS) and no shared vocabulary with the linter.

**Predictions.** If the rules are harmless, retention is flat across conditions while form
improves — that is the result that would justify adopting them. If retention falls under
`ste-strict`, strict mode is trading substance for form and belongs only where the fact set
is small and bounded (error messages), never on READMEs.

**Gate:** this is the decisive eval for ticket 83. Form improvement with flat retention →
adopt. Form improvement with retention loss → adopt for strict contexts only. No form
improvement → reject the arc.

## E-MODE-1 — Do strict and flavored modes differ by content type? (ticket 85)

**Question.** Is there an interaction between mode and content type, or is one mode simply
better?

**Design.** Read out of E-SYS-1 and E-SUB-1 by content type rather than run separately —
`ste-strict` and `ste-flavored` are already conditions, and the six tasks already span
procedural (error message, CLI help) and prose (README section, PR description).

**Predictions.** If modes are worth their complexity: strict wins on procedural tasks and
loses judged quality on prose tasks — a crossing interaction. If strict wins or loses
everywhere, ticket 85 resolves to single-mode and the complexity is not worth carrying.

## E-VOCAB-1 — Does the vocabulary problem exist here at all? (ticket 86)

**Question.** Do our models, on our tasks, actually emit the slop vocabulary a substitution
table would fix?

**Design.** Count `banned_word` and `marketing_adjective` hits in E-SYS-1's `baseline`
outputs. No new runs.

**Predictions.** Our hand-written corpus produced zero banned words across eight files and
one false-positive marketing adjective. If baseline generations look similar, the failure
mode is absent and **ticket 86 closes as not-applicable** — the right outcome for a fix
aimed at a problem we do not have. If baseline generations differ sharply from our
hand-written prose, that itself is the finding, and the table becomes worth testing against
a ban list.

**Cost of skipping this:** building a 10–20 entry table plus its tests to fix nothing.

## Em dash — reframed, not evaluated yet

The em dash ban in ticket 83 has no basis in the source: STE bans the semicolon, not the em
dash, and the linter reports em dashes outside its violation total. It is a house-style
preference, and a costly one — 718 occurrences across `atomics/`, 57 of 60 skill files, 60
in AGENTS.md. If it is still wanted, it needs its own question ("does removing em dashes
change judged clarity?") and its own before/after judged comparison. It should not ride
along inside a ticket justified by STE data.

## Sequencing and cost

1. **E-INST-1** — no agent calls, decides ticket 84, and calibrates every later metric.
2. **E-VOCAB-1's precondition** — can be answered from E-SYS-1 baselines, so it costs nothing extra.
3. **E-SYS-1** — the expensive one: 5 conditions × 6 tasks × 3 trials × 2–3 adapters = 90–135 generations. Background per `.kiro/steering/eval-execution.md`; never inline.
4. **E-SUB-1 / E-MODE-1** — judged read-outs over E-SYS-1's retained outputs, no regeneration.

**Judging constraint.** The judged halves inherit ADR 0010: a panel verdict needs ≥3 judges
across ≥2 families, and every corp run is currently degraded to a single Claude judge
(ticket 70). The deterministic halves can run today. The judged halves either wait on 70 or
run flagged as degraded — and a single-family panel judging prose quality is exactly the
case where family affinity (≈3–9%) sits inside the effect size we are chasing.

## What this design refuses to do

- Adopt a 50–74% figure as our own. It is a linter-score delta on someone else's corpus,
  scored by the treatment's own rubric, at n=6 with one run per cell.
- Gate anything on absolute linter scores while our own README sits inside the slop band.
- Ship a rule because it is lintable. Lintability is what makes a rule cheap to enforce; it
  is not evidence the rule improves anything.
