---
id: "24"
title: "Activation detection uses live output capture instead of dead code paths"
status: open
blocked_by: []
spec: "t09-baseline-followups"
---

# Activation detection uses live output capture instead of dead code paths

## What to build

Make `check-activation.sh` Strategy 1 (output-based detection) actually fire, or delete it and document that detection rides on the session-DB marker. Today the preferred strategy is dead code and the real mechanism is undocumented.

## Context

- **Found during ticket 19:** `run-activation.sh` discards agent output (`> /dev/null 2>&1`) and never writes the `$workdir/.eval-output` file Strategy 1 reads. The skill-specific markers (recall/handoff/read-handoff cases) have never fired. All activation detection actually happens via Strategy 2: grep the latest `conversations_v2` session-DB entry for the skill's H1.
- **Why it matters:** the DB grep is fragile — it matches the H1 anywhere in a 100KB+ conversation JSON (system prompts, tool listings, echoes), and Strategy 2 depends on kiro-cli's DB schema staying stable. Output capture is cheaper and more direct: kiro logs skill loads, and skill-specific behavioral markers (e.g., "recall search" in output) are stronger evidence than content grep.
- **Files:** `tools/evals/harness/run-activation.sh` (line ~88), `tools/evals/harness/check-activation.sh`
- **Simplest fix shape:** tee agent output to `$workdir/.eval-output` in run-activation.sh (one line); keep the DB strategy as fallback; delete markers for retired defs (recall)

## Acceptance criteria

- [ ] Strategy 1 receives real output (or is deleted with the actual mechanism documented in the script header)
- [ ] Full `run-activation.sh --all` produces the same or better verdicts than the last green run (19/19 defs pass) — no detection regressions
- [ ] Dead skill-specific markers removed or justified in comments

## Out of scope

- Changing activation gates (TPR/FPR thresholds)
- New activation defs (ticket 25)
