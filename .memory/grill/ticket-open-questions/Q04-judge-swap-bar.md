# Q04 — Ticket 35: judge-swap bar + policy

**Status:** RESOLVED 2026-07-19 (user accepted recommendation)

## Decision

- **Bar:** candidate judge qualifies when swapping it for the incumbent changes the final consensus median in **<5% of sampled judgments**, AND directional bias stays within **±0.1 mean shift** (bias cap is hard-coded, not tunable — a systematically generous judge manufactures false PASSes).
- **Measurement:** median preservation on re-judged retained outputs (~150–200-judgment sample; <2% bar rejected — not statistically measurable without 500+ re-judgments).
- **Policy sequence:**
  1. **Shadow now** — candidate re-judges retained outputs offline (one-off script pre-ticket-32, `--judge-only` after); zero live impact; can start before ticket 29
  2. **Augment with probation** — only AFTER ticket 29 lands judge-set recording (a judge change today is invisible in the records); 5-judge median is more stable than 4 (true middle vs lower-median tie-break)
  3. **Drop opus leg on probation evidence**

## Budget note (recorded, user-aware)

The opus-4.6 leg spends kiro credits; a haiku-4.5 crush-bedrock leg bills the AWS account with prompt caching disabled (full context re-sent per judge call). A swap moves spend across budgets as much as it reduces it.

## Sequencing constraint

No live judge-set changes before ticket 29 — shadow mode is the only zero-risk activity until then.
