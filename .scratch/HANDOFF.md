---
created_at: 2026-07-17T14:30:00+00:00
base_commit: 7f801d2
handoff_key: review-followup-tickets
---

# Handoff

## Objective
Close ticket 09 (clean eval baseline — run in flight, analysis pending), then work the new frontier: tickets 13-16 (session-improvement follow-ups).

## Constraints
- NEVER edit eval harness scripts while a run is live — `tools/evals/harness/run.sh` AND `run-activation.sh` are both owned by the live baseline run until it prints `BASELINE RUN COMPLETE`
- Background runs MUST use `setsid` (nohup dies with the launching kiro session — killed the first t12 run at 11/35; now codified in `.kiro/steering/eval-execution.md`)
- `~/.kiro/steering/` unmanaged drift: `references/environment-gotchas.md` is user-maintained by another live session; personal steering must be SYMLINKS to survive init.sh prune (doctor now warns). Never add a references prune loop without a symlink/allowlist escape.
- `pgrep/pkill -f` self-match: pattern in your own command line kills your own shell — use `ps aux | grep "[p]attern"`

## Prior Decisions
- t12 rerun verdict: threshold calibration good (25/35, 71.4%), consensus judging NOT too strict
- Activation evals now emit explicit PASS/FAIL (gates TPR≥0.5, FPR≤0.2, env-overridable) — applies to t09 phase 2 output
- okf-bundle + session-start-prime hook deleted; recall installs only from `./tools/recall` (PyPI squatted); steering slimmed to 387 always-on lines
- proofs run.sh requires explicit `--definition|--all` (bare invocation = usage + exit 2)

## Current State
Work status: `docs/plan.md` (tickets 01-08, 10-12 done) + `.tickets/` (13-16 open, 09 open). **Ticket 09 baseline run LIVE**: PID 1757091, log `/tmp/baseline-t09.log`, started 10:41 UTC at commit 24d9691. Phase 1 (judged, 35 defs): 11/35 done at 14:28, ~19 min/eval → ends ~21:30 UTC; phase 2 (activation `--all`) follows, +4-5h. Judged results: `tools/evals/results/2026-07-17T10-41-09Z/`; activation: `results/activation-2026-07-17*`. 11 results so far: 8✅/3❌, all 3 failures match known-gap triage — zero new regressions.

## Next Steps
1. Check run: `ps aux | grep "[b]aseline-t09"` + `tr -d '\000' < /tmp/baseline-t09.log | grep -E "✅|❌|COMPLETE"`
2. When complete: tally judged + activation verdicts; per-eval delta vs t12 merged (batch A `results/2026-07-16T21-11-16Z/` + batch B per-def dirs `2026-07-17T00*..09*`) and vs `2026-07-15T12-56-23Z` (only 12 names overlap — suite renamed/retired)
3. Triage each failure with the classification in Evidence; classify regression vs known gap
4. Baseline record → `docs/development/` (date + commit 24d9691), **folding in `.scratch/t09-report-recommendations.md`** (5 judgment items: recall-check gate, planning-cycles overlap, cross-model gaps list, stable def IDs, multi-agent-validation re-measure); mark 09 done in `.tickets/` + plan.md
5. Then frontier = ticket 13 (architecture-deepening rework); 15 (harness resume) becomes safe to implement once the run is done

## Fog
- Ticket 16's decision (how steering references should deploy) is deliberately open — needs an ADR, options in the ticket. No other blocking unknowns.

## Evidence
- t12 analysis: `docs/eval-results-2026-07-17.md` · usage report: `docs/development/session-skill-usage-2026-07-17.md`
- Failure triage — genuine gaps: architecture-deepening-rubber-stamp, feedback-loop{,-tighten}, type-error-diagnosis, prototype-branch-picking; cross-model: grill-question-dithering-codex, code-review-security, cross-tool-planning-with-skills; small-model: code-edit (3.44 near-miss), instruction-following
- Commits: b37724f (t03+t12) → 2d4c164 (t04) → cd78f2c (t06) → 1af6756 (t07) → 24d9691 (t08) → e80a2e8 (t10) → 7f801d2 (session improvements + tickets 13-16)
- Tried & failed this arc: plain nohup for background runs (session-group kill); pkill -f cleanup (self-kill); git add on .scratch files pre-gitignore-fix (now only HANDOFF.md is tracked)
