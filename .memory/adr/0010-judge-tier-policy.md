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
