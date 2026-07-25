# Recall-Check Compliance Measurement — 2026-07-25 (ticket 23)

Post-gate field measurement of `recall-check` steering compliance: did the 2026-07-18
gate restructure raise the share of history-question sessions that actually run
`recall search` before answering?

## Method

- **Tool:** `mise run session:skills 7` (`tools/session-analyzer/skill_usage.py`, `recall_check_compliance` block added by this ticket's earlier AC)
- **Window:** 7 days ending 2026-07-25 (gate deployed 2026-07-18 — window is entirely post-gate)
- **Comparison:** like-window per session-analysis rules — 7d vs the 7d pre-fix reference
- **Detection regex unchanged** since the 07-17 baseline (comparability preserved)

## Result

| Window | Compliance | Rate |
|--------|-----------|------|
| 30d baseline (pre-gate, 2026-07-17) | 60/284 | 21% |
| 7d pre-fix reference (ending 2026-07-18) | 78/271 | 29% |
| **7d post-gate (ending 2026-07-25)** | **43/122** | **35%** |

**+6 points over the like-window reference (29% → 35%); target (>50%, 2.4× the 30d
baseline) NOT met.** Recorded as a finding per plan: a miss is data, not a blocker.

## Reading

- Direction is right and the like-window comparison is clean, but the gate alone
  moved compliance ~6 points, not the hoped-for 2.4×.
- Known headwinds in the number:
  - The heuristic counts HISTORY-QUESTION sessions by phrasing regex; sessions where
    the answer legitimately lived in current context (a documented skip condition)
    still count as non-compliant — the measured ceiling is well below 100%.
  - Cross-project sessions without recall on PATH (or with stale ingest) can't comply;
    the denominator doesn't exclude them.

## Remediation candidates (for a follow-up ticket if pursued)

1. **Denominator refinement** — exclude sessions where recall isn't on PATH, and/or
   sample-audit N non-compliant sessions to estimate the legitimate-skip share (the
   target may need restating against the true eligible base).
2. **Mechanical enforcement** (guidance-sync P6 principle: corrections-despite-coverage
   → promote prose to mechanism) — a session-start hook or prompt-side gate is the
   next escalation if prose gates plateau.
3. **Re-measure at 30d** (~2026-08-17) for a same-window baseline comparison (21% base).

## Verdict

Gate improved compliance (29% → 35%, like windows) but under target. Ticket closes
with the measurement recorded; remediation is a decision for a future ticket, not
this one (measurement-only scope).
