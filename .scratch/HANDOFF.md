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
Ticket 01 done (commit e0fde71). A parallel eval-improvements arc landed threshold calibration (6ee2d28) and a rerun ticket that collided with ticket 01's ID — renamed to `12-rerun-eval-suite.md` and given `blocked_by: ["05", "11"]` (running with 6 broken defs + uncontained workdir leak would waste 5-6h). Ticket 05 is 1/7 done (context-neutrality already retired). Frontier: 02, 04, 05, 06, 07, 08, 10, 11.

## Next Steps
1. Ticket 05: fix 6 remaining flagged eval defs (mechanical: embed fixtures for architecture-deepening-rubber-stamp/agents-md-authoring/context-budget; judgment: handoff-improves-continuity merge-vs-differentiate, spec-validator description-vs-conditions, verification-protocol task headroom)
2. Ticket 11: contain eval workdir leak (hypothesis: judge or fixture-less sessions)
3. Ticket 12: kick off full rerun in background (nohup pattern) once 05+11 land
4. Foreground while 12 runs: ticket 02 (contradictions — the troubleshooting-protocol merge/re-scope is the judgment call), then 03
5. Parallel-friendly: 04, 06, 07, 08, 10; 09 last (consider merging 12 into 09 if 01-04 all land first)

## Fog
- Whether troubleshooting-protocol should merge into feedback-loop-debugging or re-scope (ticket 02 decision point — R1 batch2 leans merge, batch2 noted a conflicting-protocols hazard either way)
- Whether skill activation is detectable from session transcripts at all (ticket 10 spike)
- What actually leaked cwd in the eval harness (ticket 11 hypothesis: judge or fixture-less sessions)

## Evidence
- Review findings: `.memory/review-2026-07/` (skill-verdicts, eval-verdicts, tooling-audit, batch1-8)
- Overnight eval run scores: `/tmp/full-eval-run.log` (102/105, 32✅/70❌ pre-cleanup) + `tools/evals/results/2026-07-15T12-56-23Z/`
- Commits this arc: e34b30f (deploy fix) → 0f6dcc3 (review done) → 45fc048 (tickets) → e0fde71 (ticket 01)
- Dead scratch (cleanup candidates): `.scratch/r2-r3-audit.md`, `.scratch/r7-spec-statuses.md`, `.scratch/skill-review/`, `.scratch/eval-review/`, `.scratch/tooling-audit/` (all promoted or done)
