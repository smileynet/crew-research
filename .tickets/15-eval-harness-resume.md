---
id: "15"
title: "Interrupted eval runs resume without manual scripting"
status: done
blocked_by: []
spec: "session-improvements-2026-07-17"
---

# Interrupted eval runs resume without manual scripting

## What to build

`run.sh --all --skip-completed <results-dir>` reruns only definitions absent from a prior run's scores.jsonl, writing into ONE results dir per logical run so analysis never has to merge scattered per-definition dirs.

## Context

- **Incident:** the t12 run died at 11/35 (session-group kill); resuming required a hand-written per-definition loop (`/tmp/resume-t12.sh`), which then scattered 24 results across 24 timestamped dirs that had to be merged manually for analysis
- **Files:** `tools/evals/harness/run.sh` (arg parsing ~line 25, DEFS selection ~line 88, results dir creation)
- **Constraint:** do NOT edit run.sh while any eval run is live

## Acceptance criteria

- [ ] `--skip-completed <dir>`: definitions with a scores.jsonl entry in <dir> are skipped with a logged reason; new scores append into <dir> (or a merged copy)
- [ ] Interrupt-then-resume produces one dir with all 35 entries (test with --dry-run: run 3 defs, interrupt, resume, verify single scores.jsonl)
- [ ] Bare `--all` behavior unchanged
- [ ] Usage line documents the flag

## Out of scope

- Checkpointing mid-definition (trial granularity)
