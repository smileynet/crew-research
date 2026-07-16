---
id: "11"
title: "Eval sessions cannot write outside their workdir"
status: done
blocked_by: []
spec: "project-review-followup"
---

# Eval sessions cannot write outside their workdir

## What to build

An eval-spawned agent session writes only inside its temp workdir. Repo files (README.md was overwritten; 30 artifacts leaked to repo root) can never be touched by an eval run again.

## Context

- **Relevant files:** `tools/evals/harness/run.sh` invoke_agent (the `cd "$workdir"` is function-local but sessions still leaked), `.kiro/steering/eval-execution.md`
- **Incident:** 2026-07-15 run leaked ~30 files to repo root and overwrote README.md mid-run
- **Hypothesis to verify:** judge sessions or the fixture-less evals run with cwd=repo root

## Acceptance criteria

- [x] Root cause identified: which session type leaks (main agent / judge / activation) and why, with a reproducing trace — **found 2026-07-16:** `run-model-comparison.sh` (not run.sh) ran `closecode` with cwd = repo root (no workdir). Evidence: 4 `model-comparison-*` results dirs timestamped 2026-07-15T20:53→2026-07-16T02:48 overlap the incident window; its code-generation task is "Implement a TypeScript function called `debounce`" → matches leaked `debounce.ts`/`debounce-final.ts`; its kiro judge also ran with `-a` in repo root (second vector). run.sh cds into workdirs and isolates KIRO_HOME — it was blamed by proximity.
- [x] Fix applied (cwd enforcement, permissions.yaml deny, or subshell isolation) — commit 2b699cc: `run_single` uses `mktemp -d` + subshell cd; judge runs in temp dir without `-a`
- [x] Regression check: 5 validation runs (2 fixture-less: rubber-stamp, verification-protocol) — git status identical to pre-run snapshot, zero new untracked files (2026-07-16 20:5x)
- [x] eval-execution steering updated with the mid-run-edit lesson: NEVER edit run.sh while a run is live (2026-07-16 wedge incident) — commit 2b699cc

## Out of scope

- Re-running the full suite (ticket 09)
