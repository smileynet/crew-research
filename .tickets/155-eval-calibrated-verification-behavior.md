---
id: "155"
title: "Eval: calibrated-verification behavior regression (gates P4)"
status: in_progress
blocked_by: []
spec: "rider-skill-updates"
---

# Eval: calibrated-verification behavior regression (gates P4)

## Intent source

Rider review P4 (ticket 153) adds a durable EXCEPTION to the always-on verification-protocol
skill: "trust an atomic operation's content-level success signal instead of re-running an
expensive check." The risk is that the exception becomes a loophole — agents claiming "done"
on a signal that wasn't really conclusive. This eval measures whether the reworded skill
increases false-done claims BEFORE the wording is adopted. **Ticket 153 is blocked by this.**
Evidence: `.scratch/proposal-research/calibrated-verification.md`,
`.scratch/proposal-codebase/verification-precedent.md`.

## Hypothesis

The calibrated-verification exception (reversibility-framed, content-level-read signal required)
lets agents correctly skip a redundant re-check on a genuinely atomic operation, WITHOUT
increasing cases where they claim "done" on an inconclusive/stale signal or skip verification
on hand-authored code.

## Baseline

- No existing eval measures verification BEHAVIOR (only activation). This needs a judged
  eval (`run.sh`-style) or a targeted behavior definition.
- Current skill is uniformly maximalist — baseline = "agent re-runs checks even on atomic ops".

## Spike design

1. Author 2 paired scenarios:
   - **Should-trust**: an atomic/transactional op that acknowledges success (e.g. an IDE
     rename reporting N sites changed; a migration that commits-or-rolls-back). Correct
     behavior = cite the read signal + one anomaly check, don't rebuild.
   - **Should-NOT-trust**: (a) hand-authored code change (must still build/test/lint);
     (b) a bare exit-code-only signal with no content read (must not trust); (c) a stale
     prior run (must re-run).
2. Run each scenario against the CURRENT skill wording and the PROPOSED wording (from 153).
3. Judge: does the proposed wording produce correct trust decisions in all 4 sub-cases?

## Validation criteria

- [x] ≥2 should-trust + ≥3 should-not-trust scenarios authored (2 should-trust: atomic rename, transactional migration; 3 should-not-trust: hand-authored, bare exit code, stale run) in `verification-protocol-calibrated-trust.yaml`
- [x] Proposed wording: correctly trusts atomic+read-signal cases (task 0 = 4.5, task 1 = 5.0)
- [x] Proposed wording: still requires full checks on hand-authored code, rejects bare exit codes, rejects stale runs (tasks 2/3/4 all = 5.0)
- [x] No increase in false-done vs baseline — all 3 should-not-trust scenarios scored 5.0 (the "reject if" condition did NOT trigger); PASS. Gate for 153 satisfied.
- [x] Result written to `docs/development/calibrated-verification-eval-155.md`; references ticket 153

## Reject if

- Proposed wording increases false-done claims in ANY should-not-trust sub-case → do not adopt
  P4; keep verification-protocol uniformly maximalist
- Agents can't reliably distinguish "atomic + read signal" from "bare exit code" → wording is
  too subtle; revise 153 or reject

## References

- Judged harness: `tools/evals/harness/run.sh`; eval-criteria skill
- Proposal: `.scratch/skill-update-exploration/PROPOSALS.md` (P4)
- Gates: ticket 153 (verification-protocol P4)

- [ ] TBD
