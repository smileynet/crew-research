---
id: "154"
title: "Eval: measure FPR effect of negative activation clause (gates P1 negative tactic)"
status: in_progress
blocked_by: ["160"]
spec: "rider-skill-updates"
---

# Eval: measure FPR effect of negative activation clause (gates P1 negative tactic)

## Intent source

Rider review P1 (ticket 151). Research was INCONCLUSIVE-to-negative on whether a "Do not
use when…" clause in a skill description actually lowers false activation: the one source
recommending it measured no benefit, and all evidence is GPT-family (cross-model transfer
to kiro-cli unverified). This eval settles it empirically before the tactic becomes guidance.
Evidence: `.scratch/proposal-research/negative-triggers.md`,
`.scratch/proposal-codebase/activation-evals.md`.

## Hypothesis

Adding a short negative/exclusion clause to a broad-vocabulary skill's description lowers its
false-positive rate (activates on `expect_activation: false` tasks) WITHOUT lowering its true-
positive rate — on kiro-cli, measured by the existing activation harness.

## Baseline

- Instrument: `tools/evals/harness/run-activation.sh` — `FPR = FP/(FP+TN)`,
  `TPR = TP/(TP+FN)`, gates `FPR_GATE=0.2` / `TPR_GATE=0.5` (env-overridable). Definitions
  are `definitions/activation-*.yaml` with `expect_activation: true/false` tasks.
- **HARD PREREQUISITE (now split to ticket 157, which blocks this):**
  all 25 active defs currently have exactly **5 negative tasks** (dispatch-review has 6), so
  **FPR quantum = 1/5 = 0.20 — identical to the gate.** A single false-positive flips
  0.0→0.20. **No current def can resolve a sub-0.20 FPR delta.** Ticket 157 expands the
  candidates to **≥10 negatives (quantum 0.10)** with adjacent-skill decoys; this eval starts
  once 157 lands (see `.scratch/proposal-codebase/activation-decoys.md`).
- **First target:** `activation-code-review.yaml` — its 5 negatives are ALL unrelated
  (deploy/UUID/JS-syntax/migration/endpoint), ZERO adjacent-skill decoys — the highest-value
  gap. Model to copy: `activation-dispatch-review.yaml` / `activation-review-new-work.yaml` /
  `activation-project-cleanup.yaml` already carry rich adjacent-skill decoys. Edit the per-skill
  YAML directly (no central registry; runner reads `.tasks|length` per file). Do NOT change
  `id:` (immutable) or touch `retired/`.

## Spike design

1. Pick 1-2 broad-vocabulary candidate skills whose triggers overlap common dev chatter
   (e.g. code-review "review/check"; a skill with generic verbs). Confirm each has (or gets)
   an activation definition with enough `expect_activation: false` decoys to move FPR
   meaningfully (add adjacent-skill decoys if needed).
2. Run activation eval on the current (positive-only) description → record TPR/FPR.
3. Add a keywords-first negative clause to the description; regenerate; re-run → record TPR/FPR.
4. Compare. Repeat on the second candidate to guard against single-skill flukes.

## Validation criteria

- [ ] Ticket 157 landed (candidate defs at ≥10 negatives with adjacent decoys) — the resolution prerequisite
- [ ] TPR/FPR recorded for positive-only vs positive+negative on ≥2 skills
- [ ] Verdict stated: does the negative clause lower FPR with TPR held? (with the delta + noise-floor caveat)
- [ ] Result written to `.scratch/` or `docs/development/` and referenced back into ticket 151

## Reject if

- Delta is within the measured activation noise floor (~0.78% F1) → inconclusive, keep P1's
  "optional/unproven" framing and do NOT recommend negative clauses
- TPR drops (negative clause suppresses real activations or truncates keywords)

## References

- Activation harness: `tools/evals/harness/run-activation.sh`, `check-activation.sh`
- Research: `.scratch/proposal-research/negative-triggers.md`
- Feeds: ticket 151 (skill-authoring P1)

- [ ] TBD
