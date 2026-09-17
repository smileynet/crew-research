---
id: "153"
title: "verification-protocol: calibrated verification exception (P4)"
status: open
blocked_by: ["155"]
spec: "rider-skill-updates"
---

# verification-protocol: calibrated verification exception (P4)

## Intent source

Rider AIA skill review (2026-09-17) — refactoring-code's "trust the atomic tool's success
signal, don't rebuild" + one high-value anomaly check. Proposal:
`.scratch/skill-update-exploration/PROPOSALS.md` (Rev 2, P4). Evidence:
`.scratch/proposal-research/calibrated-verification.md`,
`.scratch/proposal-codebase/verification-precedent.md`.

## Context

Highest-risk proposal — it adds a durable behavioral EXCEPTION to a load-bearing, always-on
skill. **Blocked by ticket 155** (behavior eval) — do not adopt until the eval shows it
doesn't increase false "done" claims.

Research supports it narrowly: JetBrains blog [L1] (trusting an atomic refactor cut 163
builds → 3, correct); ACID atomicity [L4]; Risk-Based Testing effort ∝ RE=L×I [L4];
idempotency [L4] supplies the guardrail — trust ONLY a genuine success acknowledgment.

Two codebase conflicts to resolve (both verified):
1. **DIRECT conflict** with Violation "Skipping checks because 'it's a small change'" — a
   proportional scheme keyed on diff SIZE reintroduces the banned rationale. Must frame on
   **reversibility / blast-radius, NOT size**.
2. **Tension** with Violation "Trusting a previous run without re-running" — that line is
   about STALE evidence; a FRESH acknowledged atomic signal is different. Name the distinction.
3. Strong repo precedent AGAINST bare signals: "never trust exit code, read OUTPUT CONTENT"
   in 5+ files. Narrow positive seam: eval-execution.md endorses trusting a CONTENT-BEARING
   terminal event AFTER reading it (`runFinished` + non-empty text). → the trusted signal
   must be content-level and actually read.
4. Precedent to cite: enforcement-hierarchy already scales the ENFORCEMENT MECHANISM by
   consequence severity — the repo accepts risk-proportional reasoning on another axis.

**Two files** (Rule 6 one-owner): `atomics/skills/verification-protocol/SKILL.md` AND its
always-on twin `atomics/eager-context/verification.md` must both change or they drift.

## What to build

1. New section after `## Violations`: "Calibrated Verification (narrow, evidence-gated
   exception)". Scale verification to reversibility/blast-radius, NEVER diff size. Applies
   ONLY when: (a) the operation is atomic/transactional and acknowledges completion; (b) the
   success signal is content-level and you READ it (not a bare exit code); (c) paired with
   one high-value anomaly check where cheap. Explicitly NOT a license to skip build/test/lint
   on hand-authored code, NOT a license to trust a stale run.
2. Annotate the two Violations lines with the distinction (stale-evidence vs fresh atomic
   signal; size-is-never-the-basis, reversibility is).
3. Mirror the same change in `atomics/eager-context/verification.md`.

## Acceptance criteria

- [ ] Ticket 155 (behavior eval) closed with a PASS before this is adopted
- [ ] New "Calibrated Verification" section added, framed on reversibility (not size), requiring a content-level READ signal + atomicity + anomaly check
- [ ] Both Violations lines annotated (stale-run distinction; size-not-basis)
- [ ] `atomics/eager-context/verification.md` updated identically (no drift between skill + eager twin)
- [ ] `mise run validate` + `mise run lint` pass; `mise run generate -- kiro-cli` clean
- [ ] `mise run eval:activation` shows no regression for verification-protocol

## Out of scope

- Framing calibration on change size (rejected — see below)
- Any calibration that lets bare exit codes stand in for read output
- Touching other skills' verification language

## Rejected alternatives

- Calibration keyed on diff SIZE ("small changes need less verification") — rejected: it is
  the exact banned Violation rationale and conflates size with risk. Framed on reversibility
  + atomicity + content-level-read signal instead.

## Revisit trigger

If the exception measurably increases "claimed done without real evidence" (session review or
eval), pull it. Re-open ticket 155 for re-measurement on any future change to the wording.

- [ ] TBD
