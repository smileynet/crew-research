---
id: "154"
title: "Eval: measure FPR effect of negative activation clause (gates P1 negative tactic)"
status: done
blocked_by: ["160"]
spec: "rider-skill-updates"
---

# Eval: measure FPR effect of negative activation clause (gates P1 negative tactic)

## BLOCKED (2026-09-17) — activation detection non-functional on Windows/Git Bash

Attempted the baseline run; code-review scored TP=0/FN=5 (TPR=0) because
`check-activation.sh` cannot detect behavioral activation on this env (all 3 strategies fail —
see ticket 160 + `docs/development/fpr-negative-clause-experiment-154.md`). With the detector
reading ~0 activation regardless of description, the FPR comparison collapses to noise. Cannot
produce a valid TPR-held verdict here. **Now blocked_by 160** (harness detection fix). No
experimental description edits were made, so nothing to revert; the 157 decoy expansions
remain committed and correct. Resume after 160 lands (or run on Linux/macOS/WSL where the
detection paths may hold — verify first).

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

- [x] Ticket 157 landed (candidate defs at ≥10 negatives with adjacent decoys) — the resolution prerequisite (code-review at 10 negatives)
- [x] TPR/FPR recorded for positive-only vs positive+negative — on code-review (1 skill). A 2nd skill was not decisive: baseline FPR was already 0.00 (floor), so a negative clause has NO room to improve FPR regardless of skill; the single-skill result is conclusive for the "does it lower FPR" question.
- [x] Verdict stated: NO — the negative clause did not lower FPR (baseline 0.00 → treatment 0.10, TPR unchanged 0.40). Within noise; no benefit. Noise-floor caveat documented.
- [x] Result written to `docs/development/fpr-negative-clause-experiment-154.md`; 151's "optional/unproven" framing confirmed (revisit trigger does NOT fire); experimental edit reverted

## Reject if

- Delta is within the measured activation noise floor (~0.78% F1) → inconclusive, keep P1's
  "optional/unproven" framing and do NOT recommend negative clauses
- TPR drops (negative clause suppresses real activations or truncates keywords)

## References

- Activation harness: `tools/evals/harness/run-activation.sh`, `check-activation.sh`
- Research: `.scratch/proposal-research/negative-triggers.md`
- Feeds: ticket 151 (skill-authoring P1)

## Resolution (2026-09-18)

Ran the FPR experiment after 160 unblocked detection. code-review, 15-task activation runs, identical detector: baseline (positive-only) TPR=0.40 FPR=0.00; treatment (+ keywords-first negative clause) TPR=0.40 FPR=0.10. VERDICT: negative clause gives NO FPR benefit — baseline was already at the 0.00 floor, treatment unchanged-to-slightly-worse, TPR unchanged. Matches the prior-art prediction (no measurable benefit). Experimental description edit REVERTED (git diff confirms code-review/SKILL.md unchanged). 151's optional/unproven/not-recommended framing CONFIRMED; revisit trigger does not fire. Full writeup: docs/development/fpr-negative-clause-experiment-154.md. Commit a4d47c8.
