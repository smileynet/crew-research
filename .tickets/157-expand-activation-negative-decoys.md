---
id: "157"
title: "Expand activation defs to >=10 negative decoys (FPR resolution floor)"
status: open
blocked_by: []
spec: "rider-skill-updates"
---

# Expand activation defs to >=10 negative decoys (FPR resolution floor)

## Intent source

Second research pass for ticket 151/154 (2026-09-17). Codebase review
(`.scratch/proposal-codebase/activation-decoys.md`) found a measurement-resolution floor
that blocks ticket 154 and limits FPR sensitivity for every activation def. Split out
because the fix is reusable beyond the negative-clause experiment — it raises FPR
resolution for ALL affected skills, not just the P1 candidates.

## Problem

`tools/evals/harness/run-activation.sh` computes `FPR = FP/(FP+TN)` entirely from the
`expect_activation: false` (negative) tasks. All 25 active `definitions/activation-*.yaml`
defs currently have exactly **5 negative tasks** (dispatch-review has 6). So:

- **FPR quantum = 1/5 = 0.20 — identical to the gate `FPR_GATE=0.2`.**
- A single false-positive flips FPR 0.0 → 0.20 (pass → boundary).
- **No def can resolve a sub-0.20 FPR delta**, so no description/wording change can be
  measured for its false-activation effect. This is the hard prerequisite behind ticket 154.

Secondary gap: most negatives are *unrelated* (lexically distant), not *adjacent-skill*
decoys (same domain, wrong task) — the highest-value negatives for catching real
misrouting. `activation-code-review.yaml`'s 5 negatives are ALL unrelated
(deploy/UUID/JS-syntax/migration/endpoint) — ZERO adjacent decoys.

## What to build

1. Expand negative tasks to **≥10** (quantum 0.10) for the priority candidates, adding
   **adjacent-skill decoys** (same domain, neighboring skill's job) not just unrelated ones:
   - `activation-code-review.yaml` (highest priority — 0 adjacent today)
   - `activation-testing-guide.yaml`, `activation-planning-cycles.yaml`,
     `activation-data-modeling.yaml`, `activation-research-methodology.yaml`,
     `activation-docs-audit.yaml` (sibling-vocab overlap, all-unrelated negatives today)
2. Model to copy: `activation-dispatch-review.yaml` / `activation-review-new-work.yaml` /
   `activation-project-cleanup.yaml` already carry rich adjacent-skill decoys.
3. Keep positives at their current count (this ticket is negatives-only); do NOT change
   `id:` (immutable) or touch `retired/`.
4. Re-run `mise run eval:activation` on the expanded defs to confirm TPR/FPR still compute
   and the expanded set doesn't regress TPR (adding negatives shouldn't touch positives, but
   verify the harness reads `.tasks|length` correctly per file).

## Acceptance criteria

- [ ] `activation-code-review.yaml` has ≥10 negatives including ≥3 adjacent-skill decoys
- [ ] ≥4 additional priority defs expanded to ≥10 negatives with adjacent decoys added
- [ ] Adjacent decoys are genuine (same-domain wrong-task), verified against the neighbor skill's scope
- [ ] `mise run eval:activation` runs clean on expanded defs; TPR unchanged, FPR now has 0.10 (or finer) quantum
- [ ] No change to `id:` fields; `retired/` untouched
- [ ] `mise run validate` passes

## Out of scope

- Adding/removing POSITIVE tasks (this is negatives-only)
- The negative-clause description experiment itself (that's ticket 154, now blocked by this)
- Rewriting the harness scoring (5→10 is a data change, not a code change)

## Why split from 154

154 measures whether a negative description clause lowers FPR; it cannot produce a usable
signal until the resolution floor is fixed. The fix (more/better decoys) also benefits every
other activation def independent of the experiment, so it earns its own ticket. 154 is now
`blocked_by: 157`.

## References

- Finding: `.scratch/proposal-codebase/activation-decoys.md`
- Harness: `tools/evals/harness/run-activation.sh` (FPR = FP/(FP+TN), gate 0.2)
- Feeds: ticket 154 (negative-clause FPR eval) → ticket 151 (skill-authoring P1)
