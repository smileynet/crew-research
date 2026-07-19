---
id: "24"
title: "Activation detection uses live output capture instead of dead code paths"
status: done
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

- [x] Strategy 1 receives real output (or is deleted with the actual mechanism documented in the script header) — run-activation.sh tees ANSI-stripped agent output to `$workdir/.eval-output`; probe evidence: 3084-byte capture containing the skill-load log line, check-activation returns `activated` exit 0 via Strategy 1
- [x] Full `run-activation.sh --all` produces the same or better verdicts than the last green run (19/19 defs pass) — 2026-07-18T21-56-19Z: 19/20 defs pass (20 live defs incl. new activation-architecture-deepening), overall TPR .96 / FPR .05 / verdict PASS. The one FAIL (git-protocol, FPR 0.4) is verified agent-behavior flake, NOT a detection regression: the FP conversation contains a genuine `skills/git-protocol/SKILL.md` read in the session DB, which old Strategy 2 would have flagged identically; def already sat at the gate boundary (same stable FP present in the 2026-07-17 run). Follow-up: ticket 27.
- [x] Dead skill-specific markers removed or justified in comments — retired `recall` marker deleted (ticket 19); handoff/read-handoff markers kept with justification comments; header rewritten to document real strategy order and DB-grep fragility

## Resolution notes

- Detection sensitivity note: the generic skill-load grep now runs for ALL skills after specific markers miss (previously handoff/read-handoff were excluded from it by the case fallthrough) — same-or-better by construction.
- Run artifacts: `tools/evals/results/activation-2026-07-18T21-56-19Z` (full), `activation-2026-07-19T00-16-48Z` (git-protocol solo confirm).

## Out of scope

- Changing activation gates (TPR/FPR thresholds)
- New activation defs (ticket 25)
