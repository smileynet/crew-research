---
id: "65"
title: "Investigate: eval harness --dry-run hangs indefinitely"
status: open
blocked_by: []
priority: high
---

# Investigate: eval harness --dry-run hangs indefinitely

## What to build

Diagnose and fix why `bash tools/evals/harness/run.sh --all --dry-run` hangs indefinitely on Windows (Git Bash). A dry-run should complete in seconds (no agent invocations, no judging) — it only parses definitions and reports what would run.

## Context

**Incident (2026-07-27, ticket 30 session):** `run.sh --all --dry-run` was launched at 12:57 PM, still running at 2:09 PM (72 minutes). Two bash.exe processes visible (`Get-CimInstance Win32_Process`). Killed manually. No output captured (piped to grep, not a file).

**Hypotheses:**
1. `--dry-run` still calls `ensure_agent_probed` (access probe) which invokes the agent — would explain the hang if the agent call blocks
2. A yq call on one of the 60 definition files is hanging (malformed YAML, infinite read)
3. Git Bash-specific: a subshell or pipe is waiting on stdin
4. The adapter probe (`kiro-cli chat --no-interactive` with a test prompt) hangs in non-interactive mode without `< /dev/null`

**Investigation approach:**
1. Read `run.sh` dry-run code path — trace what it actually does vs what it should skip
2. Run with `bash -x` on a single def to pinpoint where it blocks
3. If agent probes are the issue: gate them behind `[[ "$DRY_RUN" != true ]]`

## Acceptance criteria

- [ ] Root cause identified and documented
- [ ] `--dry-run` completes in <30 seconds for the full 60-def suite
- [ ] Dry-run output lists all defs with their would-run/would-skip status
- [ ] No agent invocations during dry-run (verified via `bash -x` trace)
