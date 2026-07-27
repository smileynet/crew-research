---
type: research
title: "Model positioning by documented size and intended use (ticket 35, phase 1)"
---

# Model Positioning — Documented Size and Intended Use

Ticket 35, phase 1. Deliberately **cost-free**: what vendors say each candidate is
FOR, before any price or spend enters the decision (operator direction, 2026-07-27).
Cost enters in phase 2; the shadow study measures agreement in phase 3.

Sources: `.scratch/research/model-positioning-{claude,openai,open-weight}.md` and
`.scratch/research/judge-model-suitability.md` (4 parallel research passes, 2026-07-27).

## Candidate roster (what this machine can actually reach)

`kiro-cli chat --list-models` on corp, 2026-07-27 [L1:verified]. Credit multipliers
shown for later phases only — they played no part in phase-1 shortlisting.

| Model | Vendor tier language | Size published? | Context | Credits |
|-------|---------------------|-----------------|---------|---------|
| claude-opus-5 | "complex agentic coding and enterprise work" | No | 1M | 2.20x |
| claude-sonnet-5 | "best combination of speed and intelligence" | No | 1M | 1.30x |
| claude-haiku-4.5 | "fastest model with near-frontier intelligence" | No | 200k | 0.40x |
| claude-fable-5 | "next-generation intelligence for long-running agents" | No | 1M | 4.40x |
| gpt-5.6-sol | "frontier model for complex professional work" | No | 1.05M | 2.40x |
| gpt-5.6-terra | "balances intelligence and cost" | No | 1.05M | 1.20x |
| gpt-5.6-luna | "cost-sensitive, high-volume workloads" | No | 1.05M | 0.60x |
| glm-5 | agentic coding + search/office/knowledge work | 744B total / 40B active | 200k | 0.50x |
| deepseek-3.2 | reasoning-first, agentic tool use second | 685B total / ~37B active¹ | 164k | 0.25x |
| minimax-m2.5 | agentic deliverables (Word/PPT/Excel) | 230B total / 10B active¹ | 196k | 0.25x |
| minimax-m2.1 | agentic coding/tool use | 230B / 10B | 196k | 0.15x |
| qwen3-coder-next | coding-specialized, **non-thinking only** | 80B total / 3B active | 262k | 0.05x |
| agi-nova-beta-1m | internal SWE beta | undisclosed | 1M | 0.01x |

¹ active-parameter figure absent from that model's own card; third-party or
family-level attribution. Anthropic and OpenAI publish **no** parameter counts for
any current model — every circulating figure is estimate [L4:verified].

Bedrock (`sabiggin-isengard`/us-west-2, via crush) reaches the same Claude family
plus non-Anthropic hosts; it is a delivery path, not a distinct candidate set. Its
own judge allowlist floors at Nova Micro / Llama 70B / Haiku-class — no sub-8B judge
is offered, which is itself a vendor signal about the judging floor.

## The finding that matters most

**No vendor documents a model tier for grading or LLM-as-judge work.** Anthropic's
eval guide specifies rubric mechanics (1–5 scales, reason-then-discard) and names no
model. OpenAI's grader allowlist tops out at gpt-4o/4.1/o3 and excludes every GPT-5.x
variant, and the Graders API is documented as deprecating. Tier choice is deferred to
the reader's own measurements in both cases [L4:verified].

The one adjacent endorsement is Anthropic naming Haiku 4.5 explicitly for
**classification** — "a smaller model like Claude Haiku 4.5 is typically ideal … for
classification tasks where specialized knowledge or complex reasoning is required,
Sonnet or Opus may be a better choice" [L4:verified]. Rubric grading of free-form
agent output sits on the wrong side of that caveat, so this is suggestive, not
licensing.

Consequence: our judge choice cannot be justified by documentation. It has to be
measured locally — which is what the shadow study is for.

## What the judging literature says about the floor

- **Capability floor is sharp, then size stops mattering.** 54-judge study
  (arXiv 2510.09738): 23 models judged within human agreement range spanning 27B–72B;
  sub-4B collapsed (llama-3.2-1b κ = 0.005). Training and alignment outweigh
  parameter count above the floor [L4:established].
- **Cheap tiers fail on validity, not consistency.** 21-judge / 541k-judgment study
  (arXiv 2606.19544): a cheap model had the cohort's highest test–retest reliability
  *and* near-worst position bias. Within one family, position bias varied 70×
  (Pro 0.002 vs Flash 0.125). Cost-tier judges degrade ~3× on hard items where
  frontier judges *improve* [L4:established].
- **Style/markdown bias now dominates** (0.10–0.76, TMLR 2026), far above position
  bias (≤0.04). Our eval outputs vary a lot in markdown density — this is a live risk
  for us, not a theoretical one.
- **Mid-tier + debiasing can beat frontier at a fraction of the cost** (TMLR 2026),
  which is the optimistic case for this whole exercise.
- **Every published agreement number comes from RAG accuracy, chat preference, or
  correctness pairs — not free-form multi-step agent output.** The 27B–72B
  "human-like" band is unvalidated for our shape of task.

## Phase-1 shortlist for the shadow study

Judged on documented intent alone; ordering is not a cost ordering.

| Candidate | Why it qualifies | Reservation |
|-----------|------------------|-------------|
| claude-haiku-4.5 | only model any vendor names for classification-style scoring; same family as the incumbent kiro judge | 200k context (lowest in roster — fine for judge prompts, verify if outputs grow); no adaptive thinking |
| gpt-5.6-luna | vendor-positioned for high-volume work; identical envelope + full effort ladder to its frontier siblings, so effort can substitute for tier | tiers differ in price and prose only; no first-party capability delta published — the "smaller" claim is unverifiable |
| glm-5 | already the incumbent crush judge leg; 40B active is inside the measured human-range band | positioned for coding/office agentics, not evaluation |
| deepseek-3.2 | reasoning-first positioning is the closest documented match to reason-before-score | no Jinja chat template; official output parser documented as unfit for production without error handling |

**Excluded at phase 1, with reason** (not "too cheap" — wrong documented shape):

- `qwen3-coder-next` — 3B active parameters and non-thinking-only. Reason-before-score
  is our scoring contract and this family never emits reasoning blocks; 3B active also
  sits near the collapse zone the judging literature identifies.
- `minimax-m2.1` / `m2.5` — 10B active, positioned for document deliverables; no
  evaluation or classification positioning at all.
- `agi-nova-beta-1m` — internal SWE beta; no published positioning to reason from.
- `claude-fable-5` — carries an explicit no-customer-data/ITAR/PII restriction and is
  the most expensive model in the roster; wrong direction for this study.

Exclusions are documented, not deleted — if a shortlist candidate fails the
agreement bar, these are the reserve pool and the reason each was passed over is on
record.

## Consequence for ticket 35's acceptance bar (needs an operator decision)

The recorded qualification bar is *median shift < 5% AND mean bias within ±0.1*. The
research surfaces a specific problem with the first half: raw/exact agreement
overstates chance-corrected agreement by 33.8–41.3 pp across all 21 judges in the
Berkeley cohort — "85% agreement" corresponds to κ ≈ 0.48. A median-shift metric is
in that raw family, so a candidate can clear it while agreeing with the incumbent
consensus barely better than chance.

Two additions are proposed (neither weakens the existing bar):

1. Report a chance-corrected agreement statistic alongside median shift.
2. Stratify the sample so it includes discriminating/hard definitions rather than a
   uniform draw — the ~3× degradation of cheap judges is concentrated exactly there.

The ±0.1 mean-bias cap stays non-negotiable as recorded.

## Open questions

- Do the three GPT-5.6 tiers differ in anything but price? No first-party capability
  delta was found — if not, effort level may be the better lever than tier.
- Does effort/reasoning configuration move judge agreement more than model choice?
  The best-measured judge cohort deliberately suppressed reasoning traces, i.e. it
  excluded the mitigation Anthropic recommends most.
- Every shortlisted family already has a successor shipping (GLM-5.1/5.2, DeepSeek V4,
  MiniMax M2.7/M3). Measure this generation or chase current?
- Legacy Claude 4.5/4.6/4.7/4.8 tier descriptions were not captured (JS-collapsed
  docs section) — matters only if we compare against the incumbent opus-4.6's own
  documented positioning.
