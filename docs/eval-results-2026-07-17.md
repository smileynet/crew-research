# Eval Results — 2026-07-17 (Ticket 12: post-calibration rerun)

Full-suite rerun validating the 2026-07-15 threshold calibration (activation 4→3.5, delta_threshold→0 for 13 evals, 4 retired) plus ticket 05 definition fixes and ticket 11 workdir containment.

## Run Mechanics

- **Batch A** (11 evals): `tools/evals/results/2026-07-16T21-11-16Z/` — original run, killed at 11/35 when the launching kiro session ended (sandbox process-group kill; nohup insufficient — use `setsid` for runs that must outlive the session)
- **Batch B** (24 evals): per-definition dirs `2026-07-17T00-58-49Z` … `2026-07-17T09-38-31Z` — resumed via `setsid`, completed 09:50 UTC
- Judge: 4-model consensus (claude-opus-4.6 + codex + crush + agy), 3 trials
- Per-eval wall time varied 6–67 min (first-run estimate of 8 min was 2-3x optimistic for dual-run defs with consensus judging)
- Workdir containment (ticket 11 fix) held: `git status` clean after both batches

## Headline

| Metric | 2026-07-15 baseline | This run | Ticket 12 target |
|--------|:-------------------:|:--------:|:----------------:|
| Suite size (judged) | 103 (pre-retirement) / 32 comparable | 35 | — |
| Pass rate | 9% (9/103, pre-calibration) | **71.4% (25/35)** | ≥30% ✅ |
| Regressions (prior PASS → FAIL) | — | **0** of 12 overlapping | 0 ✅ |
| Score-1.0 infra failures | 38 (rate-limit artifacts) | **0** (one 1.00 score is genuine — see below) | 0 ✅ |

Note: the ticket named `2026-07-15T03-50-09Z` as the comparison dir; that dir no longer exists. Comparison uses `2026-07-15T12-56-23Z` (the overnight 102/105 run), which is the surviving baseline. Only 12 of 35 definitions overlap by name — the review retired 21 consolidation one-shots and ticket 05 renamed/added definitions, so most of the suite has no prior-run counterpart.

## Overlapping Definitions (12) — baseline → rerun

| Definition | 07-15 | 07-17 | Note |
|------------|:-----:|:-----:|------|
| agents-md-authoring-effectiveness | FAIL | **PASS** | calibration win |
| context-budget-effectiveness | FAIL | **PASS** | calibration win |
| architecture-design-vocabulary | PASS | PASS | |
| cheatsheet-routing | PASS | PASS | |
| code-review-two-axis | PASS | PASS | |
| cross-tool-planning-hono | PASS | PASS | |
| deployment-safety-verdict-gate | PASS | PASS | |
| eval-criteria-improves-scoring | PASS | PASS | |
| architecture-deepening-rubber-stamp | FAIL | FAIL | genuine skill gap (see below) |
| cross-tool-planning-with-skills | FAIL | FAIL | delta 0.17 < 0.3 |
| feedback-loop-effectiveness | FAIL | FAIL | see failure analysis |
| feedback-loop-tighten-effectiveness | FAIL | FAIL | see failure analysis |

## Failures (10) — analysis

**Genuine skill signal (skill content needs work):**

1. **architecture-deepening-rubber-stamp** (1.00, activation 0/6) — known from ticket 05 validation: agent accepts rubber-stamp reviews; skill never activates. Needs content + description work (candidate for a new ticket).
2. **feedback-loop-effectiveness** (3.11 < 3.5) + **feedback-loop-tighten-effectiveness** (3.66 < 4) — both failed post ticket-02 merge of troubleshooting-protocol into feedback-loop-debugging. Worth checking whether the merge diluted the skill's protocol steps; these were also failing pre-merge (07-15 baseline), so not a merge regression, but the merge didn't fix them either.
3. **type-error-diagnosis-reads-before-fix** (2.77 < 3.5) — agent fixes before reading; skill not shifting behavior enough.
4. **prototype-branch-picking-effectiveness** (3.66 < 4) — near-miss; threshold or content.

**Cross-model gaps (skill works on kiro, not codex):**

5. **grill-question-dithering-codex** (delta -0.34 < 0) — the kiro sibling PASSED (delta 0.33) with the same trimmed skill. New definition (no prior result), so not a regression — first measurement of a known cross-model risk.
6. **code-review-security-vulnerability-detection** (delta 0 < 0.75) — new definition; no prior result.
7. **cross-tool-planning-with-skills** (delta 0.17 < 0.3) — persistent since baseline.

**Small-model capability limits (informational, not skill defects):**

8. **small-model-code-edit** (3.44 < 3.5) — near-miss.
9. **small-model-instruction-following** (2.66 < 3.5) — clear capability gap.

## Ticket 03 Verification (line-budget trims)

Trims landed (c54b412) between batch A and batch B, so batch B's grill/sdd evals ran against the trimmed skills:

- grill-idiomatic-patterns ✅ (delta 3.16), grill-research-gates-codex ✅ (delta 1.83), grill-question-dithering-kiro ✅ (delta 0.33)
- spec-driven-development-effectiveness ✅ (5.00 vs 4.00), spec-self-gating ✅ (delta 3.50)
- The one grill failure (dithering-codex) is a cross-model gap on a new definition, not a trim regression

**Verdict: trims preserved skill quality. Ticket 03 acceptance met.**

## Acceptance Check (ticket 12)

- [x] Full suite completes, no score-1.0 infrastructure failures (the single 1.00 is validated genuine signal)
- [x] Pass rate ≥30% — 71.4%
- [x] No new regressions — 0 of 12 overlapping prior-passes failed
- [x] Comparison notes committed (this document; raw results local per gitignore policy)
- [x] Prior score-1.0 rate-limit artifacts eliminated — 0 in 35

## Follow-ups

- Consensus judging is NOT too strict (71% pass) — the ticket's <25% contingency spike is unnecessary
- Ticket 09 (re-baseline) can treat this run as its "before" snapshot once tickets 04 lands
- Candidate new ticket: architecture-deepening content + activation rework (0/6 activation, 1.00 score)
- Candidate investigation: feedback-loop skill pair — only skills with both evals failing post-merge
