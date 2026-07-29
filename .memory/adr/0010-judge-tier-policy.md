---
type: adr
title: "Judges run the best available model, never a cheaper one"
---

# ADR 0010 — Judge Tier Policy

**Date:** 2026-07-27
**Status:** Accepted (operator decision)
**Context ticket:** 35

## Decision

Grading and judging always use the best available model, or at minimum one capability
tier above the model being judged. Cost is not a lever on this role.

Applied within each vendor family, not by collapsing legs onto one model — family
diversity is what makes a consensus median meaningful, so each leg runs its own
family's frontier:

| Leg | Was | Now |
|-----|-----|-----|
| kiro-cli | claude-opus-4.6 | claude-opus-5 (probed live, 2026-07-27) |
| codex | tool default (gpt-5.5) | tool default, pending verification — intended pin `gpt-5.6-sol`; codex cannot be probed from the agent sandbox, and pinning an unverified id would silently shrink the panel |
| crush | glm-5.2 (hardcoded in run.sh) | glm-5.2 from config; `CREW_CRUSH_JUDGE_MODEL` overrides with a `bedrock/us.*` id on corp |
| agy | tool default | tool default (Gemini frontier); policy-blocked on corp |

`claude-fable-5` is the only tier above opus-5 and is the required judge when the
agent under test itself runs opus-5. It carries a no-customer-data/ITAR/PII
restriction — permissible here because eval fixtures are synthetic — at 4.40x credits.

## Why

A cheap judge looks free but buys unmeasurable scores.

- **No vendor licenses it.** Anthropic's eval guide specifies rubric mechanics and
  names no model for the grader role; OpenAI's grader allowlist excludes every GPT-5.x
  variant and is itself deprecating. Bedrock's judge allowlist floors at Haiku/Nova
  Micro class. The one adjacent endorsement — Anthropic naming Haiku 4.5 for
  classification — explicitly excepts tasks needing complex reasoning, which rubric
  grading of free-form agent output is.
- **Cheap tiers fail on validity, not consistency** (arXiv 2606.19544, 21 judges /
  541k judgments): a cheap model posted the cohort's highest test–retest reliability
  alongside near-worst position bias. Within one family, position bias varied 70×
  between the frontier and cost tier. Cost-tier judges degrade roughly 3× on hard
  items — exactly the discriminating cases evals exist to resolve — where frontier
  judges improve.
- **The agreement metric that would have gated a swap is misleading.** Raw agreement
  overstates chance-corrected agreement by 34–41 points across that cohort; 85% raw
  agreement is a kappa near 0.48. A cheap candidate could clear a median-shift bar
  while tracking the incumbent barely better than chance.
- **A judge below the judged model cannot recognise what it is scoring.** Skill evals
  reward reasoning the judge has to follow; a lower tier silently penalises work above
  its own ceiling, and that error is invisible in the score.

## Rejected alternative — the cheap-judge shadow study

Ticket 35 originally planned to have cheap candidates (haiku-4.5 prime) re-judge
retained outputs and qualify a 5th probation leg on a median-shift/bias bar. That is
rejected, not deferred. Do not re-propose it on cost grounds; the evidence above is
the answer. What survives from that ticket is the role table for the roles where a
cheaper model *is* appropriate: session-review prefilter probes, background/lite
subagent tasks (title generation, summaries), and capability-floor measurement via the
`small-model-*` definition family.

## Amendment — cross-family panels (2026-07-29)

Operator direction: judges should also be cross-family, for objectivity. Adopted as a
requirement **with a floor**, justified on bias grounds rather than accuracy grounds —
the distinction matters because the accuracy case does not hold up.

**Rule.** A panel verdict requires **≥3 judges spanning ≥2 vendor families**. Family is
derived from the model id, not the tool: crush pointed at `bedrock/us.anthropic.*` is an
Anthropic leg, so kiro+crush there is one family twice. Below the floor the harness
records the score and stamps the row's `panel` object with `degraded: true` and a
reason; it does not withhold the score, and it does not call it a consensus. `N=2` is
degraded even across two families — the median of two is their mean, so the
unbounded-bias result that motivates median aggregation reapplies.

**Why bias grounds, not accuracy grounds.** Cross-family is the only replicated
mitigation for family affinity (same-family-same-series ≈ 8.9%, running on style and
format signatures judges cannot introspect — ablating style cut it nearly in half,
rewording did nothing), and family-structured calibration bias cancels in a mixed panel
where a single-family median inherits it whole (the Claude family measured uniformly
−0.5 to −0.8 on a 0–4 scale). The accuracy case fails: the strongest 2026 measurement
(9 judges / 7 families, human-annotated) found effective sample size 2.18 of 9, its
three most-correlated pairs were all *cross*-family, one-judge-per-family *lowered*
effective independence, and the best single judge matched or beat the panel in every
condition. ICML 2025 adds that models agree 60% conditional on both being wrong
(chance 33%), worsening as models converge.

**Rejected: adding legs to chase objectivity.** Effective independence saturates near
2–2.6 judges regardless of count, so a 5th or 6th leg buys nothing measurable. Budget
goes to trials instead — 44.7% of score variance is within-question noise, and 3 trials
buy roughly 90% consensus fidelity. Also rejected: per-judge calibration (published
warning: a calibration shared across compared systems can point a comparison the wrong
way with high apparent confidence) and half-point medians on even panels (they invent a
score no judge gave). The even-panel rule is the lower middle score, documented in
`run.sh` and surfaced in the reason string.

**Also decided:** judge agreement is never a confidence signal — unanimous 9-judge
panels carried ~9% error against ~0.02% predicted under independence.

**Consequence.** Every corp run today is degraded: agy is policy-blocked, codex fails in
the agent sandbox, and crush needs a Bedrock model id, leaving one Claude judge scoring
Claude-produced output. That was already true before this amendment; it is now visible
in every row and announced at the top of every run instead of being reconstructable only
from metadata. Restoring a second family is ticket 70.

## Consequences

- Judging gets more expensive on purpose. Judge cost is now a fixed cost of measuring,
  not a variable to optimise.
- **Every retained baseline reads as ENV-DRIFT.** Judge identity is part of `env_id`
  (ADR-adjacent: ticket 33), so `check-staleness.sh` flags prior results rather than
  silently comparing across judge sets. Recompare via
  `run.sh --judge-only <results-dir>` when a comparison actually matters.
- The policy is only enforceable if no leg rides an unpinned default. All four leg
  models now come from `tools/evals/judges/default.yaml`; verify them on tool upgrades
  instead of trusting "default = frontier".
- **Open gap:** the agent under test still runs the tool default (kiro-cli `auto`),
  which is nondeterministic and records as `tool-default` in `env_id`. The
  one-tier-above rule cannot be verified against an unknown tier. Either pin the
  under-test model or run the ceiling judge; unresolved as of this ADR.
