---
type: research
title: "Cross-family judge panels — pros, cons, and items needing attention"
---

# Cross-Family Judging — Analysis

Ticket 35 / ADR 0010 follow-on, 2026-07-27. Operator direction: judges should be
cross-family for objectivity, on top of the frontier-tier policy.

Evidence: `.scratch/research/judge-panel-diversity.md`,
`.scratch/research/judge-self-preference.md`, `.scratch/research/judge-aggregation.md`.
Harness facts below were read from `tools/evals/harness/run.sh` at commit 672724b.

## Where we actually stand

The panel is already cross-family by construction — one leg per tool, and each tool
brings a different family (kiro→Claude, codex→OpenAI, crush→GLM or Bedrock, agy→Gemini).
Cross-family was never a stated requirement, though, so nothing enforces it, and on
this machine it collapses:

| Leg | Family | Status on corp |
|-----|--------|----------------|
| kiro-cli | Anthropic | live (opus-5, probed) |
| codex | OpenAI | **dead in the agent sandbox** — wrapper cannot write its AWS config temp file |
| crush | GLM (personal) / Bedrock Claude (corp) | needs `CREW_CRUSH_JUDGE_MODEL`; unset ⇒ probe fails |
| agy | Gemini | policy-blocked (CREW_ENV=corp) |

So a corp run today judges with **one Claude model** — and the agent under test also
runs Claude. That is same-family judging with a panel of one, recorded as a median.

## Pros of cross-family

- **It is the only replicated mitigation for family affinity.** Preference Leakage
  (ICLR 2026) decomposes the effect cleanly: same model 23.6%, same family same series
  8.9%, same family different series 2.8%. Judges score at chance (41–53%) when asked
  to *identify* their own family's output yet still reward it — the signal is style and
  format, not recognition, so no prompt instruction can ask it away. Ablating style cut
  the effect 17.5%→9.0%; rewording did nothing [L4:established].
- **Family-structured calibration bias cancels in a mixed panel.** RoPoLL measured the
  whole Claude family at −0.5 to −0.8 uniformly negative on a 0–4 scale, small open
  models uniformly positive, Qwen near zero. A median over mixed-direction bias is
  robust by construction; a median over one family inherits that family's offset whole
  [L4:reported].
- **Prompt fragility is judge-specific and does not transfer.** In PoLL, GPT-4's kappa
  moved 0.518→0.725 across prompt variants, and prompts tuned for one judge did not
  transfer to another. A mixed panel spreads that risk instead of concentrating it
  [L4:established].
- **Diverse small panels beat a single strong judge on the original benchmark.** PoLL
  (3 disjoint families, small models) beat single GPT-4 on 5 of 6 comparisons at 7–8×
  lower cost, with the smallest deviation spread from humans [L4:established].
- **It removes a conflict of interest that is hard to argue away.** Our judged
  artifacts are Claude-produced. A Claude-only panel is defensible only with a bias
  argument nobody outside the project will accept on faith.

## Cons and honest counter-evidence

- **Cross-family diversity does not buy statistical independence.** The strongest 2026
  measurement (Apple preprint, 9 judges / 7 families, 100 human annotations per item)
  found effective sample size 2.18 out of 9, independence ratio 24%, and — directly
  against intuition — the three most correlated judge pairs were all *cross-family*
  (Claude×Gemini 0.603, GPT-4o×Claude 0.588). Restricting to one best judge per family
  **lowered** n_eff to 1.93, and the best single judge matched or beat the full panel in
  every condition [L4:reported, single group].
- **Correlated errors are structural, not incidental.** ICML 2025 (peer-reviewed,
  349+ models): conditional on both being wrong, models agree 60% where chance is 33%.
  More accurate models are *more* correlated — models are converging, so this worsens
  as the roster improves [L4:established].
- **Self-preference is mostly not self-preference.** An outcome-matched control across
  37,448 pairs found evaluator uncertainty explains 89.6% of measured self-preference;
  only 10.4% survives, and roughly half of prior experiments lose significance. Same
  family at equal quality has never been isolated [L4:reported].
- **Combining both policies is the most expensive configuration available.** PoLL's
  win came from cheap diverse judges; the tier policy forbids that. Frontier × 3–4
  families is maximum spend for a benefit the newest evidence sizes as small — on
  classification tasks. On open-ended agent output it is unmeasured in either direction.
- **More legs, more failure surface.** Each leg is a separate CLI with its own auth,
  sandbox, and policy constraints. Two of our four are down on this machine right now.
- **Unanimity is not confidence.** Unanimous 9-judge panels were 90.9% accurate where
  independence predicts 99.99%; 51 items had all nine wrong. A cross-family panel
  agreeing does not mean the answer is right [L4:reported].

## Recommendation

Adopt cross-family as a **requirement with a floor**, and justify it on bias grounds —
not accuracy grounds. Specifically: a panel verdict requires **≥3 judges spanning ≥2
families**; anything less is recorded as a degraded measurement rather than a
consensus. Do not add a 5th or 6th leg chasing independence — the evidence puts the
ceiling near n_eff 2–2.6 regardless of count, and the money is better spent on trials
(44.7% of score variance is within-question noise; 3 trials buy ~90% consensus fidelity).

Two things we already do right and should keep: median aggregation (RoPoLL proves the
mean has unbounded bias under any contamination rate, with real parser-failure rates of
0.6–3.4%; our median is the tuning-free robust choice) and pointwise 1–5 scoring
(more robust than pairwise, and 0–5 measured as the optimal granularity).

Explicitly do **not** add per-judge calibration: the published warning is that sharing
one calibration across compared systems can point a comparison the wrong way with high
apparent confidence.

## Items needing attention

Ordered by consequence. Each is independently ticketable.

**A1 — Panel collapses to one Claude judge on corp (highest).** Same-family judging
with N=1, recorded as a median. Fix in two parts: restore a second family (repair the
codex sandbox failure, or add a non-Anthropic Bedrock leg via direct `invoke-model` —
already in ticket 35's constraint list as needing a spike), and enforce the floor
below.

**A2 — N=1 and N=2 scores are emitted as consensus.** The harness records
`judges.live`/`excluded` in `meta.json` and a per-row `judges` array, but the score
field itself is indistinguishable from a 4-judge median, and the run banner still says
`consensus`. Add a degraded marker to each row (judge count + family count) and to the
summary. RoPoLL's rule is blunt: **N=2 is not a panel** — the median of two is their
mean, and the unbounded-bias result reapplies. Report two single-judge scores instead.

**A3 — Even-panel median rounds down, undocumented.** `median_idx=(n-1)/2` takes the
lower of two middle scores. That is deterministic (good) but arbitrary and unrecorded;
a 2-judge panel is therefore min-biased. Either document it as the rule or switch to
the half-point median, and settle it cheaply by re-scoring an existing results dir both
ways.

**A4 — Family affinity is inside our delta thresholds.** Same-family-series affinity
is roughly a 3–9% thumb on the scale. Our thresholds are 0.5–1.0 points on a 5-point
scale (18 defs use 0), so a single-family panel can plausibly move a near-threshold
verdict. Declare a noise floor: when the panel is single-family, deltas below ~0.3
points are not evidence.

**A5 — The judge prompt is an unhashed experimental variable.** `def_hash` covers the
definition and fixtures; `env_id` covers adapter, tool version, model, and judge set.
The judge prompt and rubric live in `run.sh` and are covered by neither — yet prompt
rewording flipped majority verdicts in 25% of cases in one study. Add a judge-prompt
hash to the identity scheme so a template edit reads as drift instead of a silent score
change.

**A6 — `trials: 1` in `judges/default.yaml` is dead config.** Nothing reads it; trials
come from the definition or the CLI (default 3). Misleading in the file that now also
carries the tier policy. Delete it or wire it.

**A7 — Panel composition differs per machine, so scores are not cross-machine
comparable.** Corp loses agy by policy; codex is environment-dependent. `env_id`
already encodes the judge set, so this is visible rather than silent — but there is no
declared canonical panel to deviate *from*. Declare one, and treat machine-local
panels as degraded when they differ.

**A8 — Do not use agreement as a quality signal anywhere.** If any report treats judge
agreement as confidence, remove it; unanimous panels carry ~9% error. Related: when we
eventually measure judge agreement, use ICC rather than Pearson, and report a
chance-corrected statistic — raw agreement overstates it by 34–41 points.

## Open questions

- The n_eff ≈ 2 ceiling has only been measured on classification, NLI, and pairwise
  preference — never on open-ended generation, which is all we judge. Our own γ̄ is
  measurable from any retained results dir with per-judge scores; nobody should
  cargo-cult the number 3 without it.
- Nobody has replicated PoLL's comparison against the *best* individual judge on PoLL's
  own datasets, so "panel beats single judge" and "best single judge beats panel" are
  both live claims resting on different baselines.
- Family affinity at equal quality has never been isolated, and nothing at all measures
  it for agentic or code-artifact judging.
