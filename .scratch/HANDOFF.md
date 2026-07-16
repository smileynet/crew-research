---
created_at: 2026-07-16T18:55:00+00:00
base_commit: e0fde71
handoff_key: review-followup-tickets
---

# Handoff

## Objective
Execute the project-review follow-up backlog: 11 tickets in `.tickets/` (from the 8-ticket deep-dive review completed 2026-07-16, all findings in `.memory/review-2026-07/`).

## Constraints
- Skills <100 lines (references/ overflow); steering pays always-on cost per line
- NEVER edit `tools/evals/harness/run.sh` while an eval run is live (wedged the 17h run at 102/105)
- Steering in tier yamls must live in `atomics/skills/` — lint enforces (bug hit twice)
- Evals: nohup → observe → sleep pattern per `.kiro/steering/eval-execution.md`

## Prior Decisions
- Backlog = `.tickets/` files; plan.md (docs/plan.md) is the authoritative status map
- 21 evals retired (consolidation one-shots); suite = 30 judged + 24 activation defs
- Review verdicts: 53 skills → 32 KEEP / 20 FIX / 1 MERGE; details in `.memory/review-2026-07/`
- recall CLI: installed 0.1.0 is stale vs source AND PyPI name is squatted (ticket 07)

## Current State
Ticket 01 done (commit e0fde71). Frontier per plan.md: 02, 04, 05, 06, 07, 08, 10, 11. Suggested next: ticket 02 (cross-skill contradictions — unblocks 03). Nothing mid-flight; review artifacts promoted from gitignored .scratch to `.memory/review-2026-07/` this session (ticket Context lines updated to match).

## Next Steps
1. Ticket 02: resolve contradictions (troubleshooting-protocol vs feedback-loop-debugging merge/re-scope is the judgment call; rest is mechanical per `.memory/review-2026-07/skill-verdicts.md` P1 table)
2. Then 03 (line budgets — re-run grill + sdd evals after trimming)
3. Parallel-friendly: 06/07/08 (tooling), 10 (session-log usage analysis — has a 1h spike gate), 11 (eval workdir containment)
4. 09 (re-baseline) last — blocked by 01-05 + 11

## Fog
- Whether troubleshooting-protocol should merge into feedback-loop-debugging or re-scope (ticket 02 decision point — R1 batch2 leans merge, batch2 noted a conflicting-protocols hazard either way)
- Whether skill activation is detectable from session transcripts at all (ticket 10 spike)
- What actually leaked cwd in the eval harness (ticket 11 hypothesis: judge or fixture-less sessions)

## Evidence
- Review findings: `.memory/review-2026-07/` (skill-verdicts, eval-verdicts, tooling-audit, batch1-8)
- Overnight eval run scores: `/tmp/full-eval-run.log` (102/105, 32✅/70❌ pre-cleanup) + `tools/evals/results/2026-07-15T12-56-23Z/`
- Commits this arc: e34b30f (deploy fix) → 0f6dcc3 (review done) → 45fc048 (tickets) → e0fde71 (ticket 01)
- Dead scratch (cleanup candidates): `.scratch/r2-r3-audit.md`, `.scratch/r7-spec-statuses.md`, `.scratch/skill-review/`, `.scratch/eval-review/`, `.scratch/tooling-audit/` (all promoted or done)
