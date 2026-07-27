---
id: "65"
title: "Investigate: eval harness --dry-run hangs indefinitely"
status: done
blocked_by: []
priority: high
---

# Investigate: eval harness --dry-run hangs indefinitely

## What to build

Fix `bash tools/evals/harness/run.sh --all --dry-run` so it completes in <30 seconds on Windows (Git Bash). Currently hangs for 60+ minutes.

## Root Cause (confirmed 2026-07-27)

Dry-run correctly skips agent invocations and judging but still enters the full `run_eval()` function which:
1. Computes identity hashes per def (`identity_skill_hash` + `identity_def_hash`) — each spawns 4-6 subprocesses (yq, find, sort, cat, sha256sum in a pipeline)
2. Extracts ~10 fields via separate yq calls per def (name, skill, threshold, timeout, fixture, trials, conditions...)
3. Total: ~750-900 process forks for 39 defs

On Git Bash/MSYS2, each fork costs 60ms-4.7s (degrades with uptime due to Windows Desktop Heap exhaustion). At moderate degradation: 30-75 minutes.

## Fix

Add early-exit in `run_eval` for dry-run mode: after adapter-scoping check, emit the plan line and return immediately — no hash computation, no field extraction, no trial loop.

## Acceptance criteria

- [ ] Root cause identified and documented
- [ ] `--dry-run` completes in <30 seconds for the full 60-def suite
- [ ] Dry-run output lists all defs with their would-run/would-skip status
- [ ] No agent invocations during dry-run (verified via `bash -x` trace)
- [ ] Real runs unaffected (single-def verify)
