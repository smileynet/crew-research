---
created_at: 2026-08-31T12:02:00-07:00
base_commit: c66d731
handoff_key: data-modeling-eval
---

# Handoff

## Objective
Ship + validate the `data-modeling` skill (invalid-states-unrepresentable design/review).
Skill is DONE and deployed (146). Eval infra is built and RAN on Windows (147). Remaining:
optional skill tuning once the eval's own confounds are addressed.

## Constraints
- Windows host + minimal Fedora WSL: the Linux eval harness (`run.sh`/`run-activation.sh`)
  CANNOT run here (kiro-cli is a `.exe` off WSL PATH; no `sqlite3` CLI; setsid dies on
  `wsl.exe` return). Use `tools/evals/scripts/run-eval-windows.py` (native, no WSL).
- `wsl -- bash -c '...'` mangles nested quotes/loop vars/`$?` — run native PowerShell/python
  for non-bash work (see project-conventions windows.md).

## Prior Decisions
- data-modeling = standalone on-demand skill, NOT always-on steering, NOT a 3rd code-review
  axis; review lens cross-linked from code-review Standards (145 resolution).
- eval-execution moved from steering → `eval-harness/references/execution.md` (failed all 3
  eager-context gates). Guidance belongs in skills when situational.
- Did NOT tune the skill from eval FPs: the high FP-rate is EVAL mislabels/criteria, not
  skill over-application (skill is more discerning than the hand-labels).

## Current State
Tickets: 136–141 (known-tools orchestration) + 145/146 (data-modeling) DONE. 147 in_progress.
Working tree clean, all pushed. Eval ran (trials=2): TPR=1.0 both sets; FP-rate 0.8/1.0 traced
to over-generous PASS labels + strict criteria (verified by reading outputs). Full analysis:
`docs/development/data-modeling-eval-2026-08-31.md`.

## Next Steps
1. (147, optional) Re-label corpus: `Consent`/`RunPhase`/likely `PublishResult`/`capabilities`
   are FLAG-worthy (model found real coupling smells). Loosen PASS criteria to reward
   "affirms soundness + NITs". Re-run via run-eval-windows.py, then confusion-matrix.py.
2. Only after that: decide if skill wording needs any change (evidence says probably not).
3. Close 147 or leave as documented-deferred.

## Fog
Whether the near-zero with-skill−baseline delta means the skill adds little on clear-cut
cases, or the single kiro-cli judge just can't discriminate. Needs a 2nd judge to resolve —
don't tune the skill on single-judge signal.

## Evidence
- `docs/development/data-modeling-eval-2026-08-31.md` (results + confusion matrices + finding)
- `tools/evals/definitions/data-modeling-*.yaml` (3 defs), `tools/evals/scripts/run-eval-windows.py`, `confusion-matrix.py`
- Skill: `atomics/skills/data-modeling/` (SKILL.md + references/patterns.md, review-lens.md)
- Commits this session: eb18149→f62c680→c66d731 (guidance, AGENTS dedup, eval-execution move)

## Recommended Updates
- [ ] eval-criteria: PASS-item criteria pattern that doesn't score NITs as fabrication (147 revealed the gap)
- [ ] .tickets: plan.md drift (orphan rows 07/63; ~15 open tickets lack plan rows) — pre-existing, run /plan-ticket-sync
