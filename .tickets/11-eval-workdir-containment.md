---
id: "11"
title: "Eval sessions cannot write outside their workdir"
status: open
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

- [ ] Root cause identified: which session type leaks (main agent / judge / activation) and why, with a reproducing trace
- [ ] Fix applied (cwd enforcement, permissions.yaml deny, or subshell isolation)
- [ ] Regression check: run 2 evals (one fixture-less), verify `git status` clean after
- [ ] eval-execution steering updated with the mid-run-edit lesson: NEVER edit run.sh while a run is live (2026-07-16 wedge incident)

## Out of scope

- Re-running the full suite (ticket 09)
