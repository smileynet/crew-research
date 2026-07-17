---
created_at: 2026-07-17T14:00:00+00:00
base_commit: 10e575b
handoff_key: review-followup-tickets
---

# Handoff

## Objective
Close out the project-review follow-up backlog: 11/12 tickets done; ticket 09 (clean eval baseline) is the only open item — its run is in flight, only the post-run analysis remains.

## Constraints
- NEVER edit eval harness scripts while a run is live
- Background runs MUST use `setsid` — nohup alone dies with the launching kiro session (killed the first t12 run at 11/35)
- `~/.kiro/steering/` has unmanaged user drift: `references/environment-gotchas.md` (another live session maintains it; redeploys clobber the section pointer in project-conventions.md — cosmetic, refs eager-load anyway). Never add a references prune loop to init.sh without a symlink/allowlist escape — a top-level prune already ate archwright-conventions.md once (restored as symlink; symlinks are prune-safe)
- `pgrep/pkill -f` self-match gotcha: pattern in your own command line kills your own shell

## Prior Decisions
- okf-bundle + hooks/session-start-prime.json DELETED (unwired; superseded by recall-session-start steering) — spec line corrected
- recall installs ONLY from `./tools/recall` (PyPI name squatted); installed 0.2.0
- Steering slimmed to 387 always-on lines; tool-installation.md demoted to project-level
- t12 rerun verdict: calibration good (71.4% pass), consensus judging NOT too strict

## Current State
Work status: `docs/plan.md` ticket table (all current). **Ticket 09 baseline run LIVE**: PID 1757091, log `/tmp/baseline-t09.log`, script `/tmp/baseline-t09.sh`, started 10:41 UTC at commit 24d9691. Phase 1 = judged suite (11/35 done at 14:00 UTC, ~17 min/eval → ends ~18:00); phase 2 = activation suite (`run-activation.sh --all`). Terminal log line: `BASELINE RUN COMPLETE`. Judged results land in per-run dir `tools/evals/results/2026-07-17T10-41-09Z/`; activation results in `results/activation-*`. So far 8✅/3❌ — all 3 failures match the known-gap triage (no new regressions).

## Next Steps
1. When run completes: tally judged pass/fail + activation TPR/FPR; compare per-eval vs t12 merged results (batch A `results/2026-07-16T21-11-16Z/` + batch B per-def dirs `2026-07-17T00*..09*`) and vs `2026-07-15T12-56-23Z` where names overlap (only 12 defs overlap — suite was renamed/retired)
2. Triage each failure: regression vs known gap, using the classification in Evidence below
3. Write baseline record to `docs/development/` with date + commit 24d9691; mark ticket 09 done in `.tickets/` + plan.md; commit
4. Follow-up candidates (new tickets if pursued): architecture-deepening rework (1.00 score, 0/6 activation); feedback-loop pair (both evals fail post-merge); recall-check steering compliance (21% field rate); planning-cycles overlap review (1 activation/30d vs sdd 6 + grill 6)

## Fog
- None blocking. Open question parked: should the generator inline-trim steering references (they defeat progressive loading — batch5 cross-cutting finding #1)? No ticket exists.

## Evidence
- t12 analysis: `docs/eval-results-2026-07-17.md` (incl. run mechanics + acceptance)
- Usage report: `docs/development/session-skill-usage-2026-07-17.md` (spike PASS: activation detectable from transcripts)
- Failure triage for t09 comparison — genuine skill gaps: architecture-deepening-rubber-stamp, feedback-loop{,-tighten}, type-error-diagnosis, prototype-branch-picking; cross-model: grill-question-dithering-codex, code-review-security, cross-tool-planning-with-skills; small-model capability: code-edit (3.44 near-miss), instruction-following
- Commits this arc: b37724f (t03+t12) → 2d4c164 (t04) → cd78f2c (t06) → 1af6756 (t07) → 24d9691 (t08) → e80a2e8 (t10) → 10e575b (handoff)
- Scratch cleaned: r2-r3-audit, r7-spec-statuses, skill-review/, eval-review/, tooling-audit/, debounce.ts all deleted (promoted or obsolete)
