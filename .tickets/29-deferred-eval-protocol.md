---
id: "29"
title: "Deferred eval protocol: adapter-scoped defs, access probes, judge visibility, owed-run ledger"
status: open
blocked_by: []
spec: "t09-baseline-followups"
---

# Deferred eval protocol: adapter-scoped defs, access probes, judge visibility, owed-run ledger

## What to build

The mechanism for running a multi-adapter eval suite on machines with partial tool access. This machine has crush on PATH but no model access, and no agy access — today that produces silently-degraded judging and would blind-run crush-designed defs under kiro-cli. Principle (borrowed from the extension protocol): gaps are pending-with-reason, never silent.

## Context

- **Verified on this machine (2026-07-19):** crush judge spawns per judging call (`command -v` passes) and produces no valid score; every "consensus" score in local results is a ~2-judge median (opus+codex) — indistinguishable in scores.jsonl from a 4-judge run because judge participation is never persisted (`judge_dir` is rm -rf'd, "median of N judges" reasons don't reach scores.jsonl)
- **Upstream 5a23e45** added 3 crush-designed image defs that `run.sh --all` will run under kiro-cli (def selection: all non-activation yaml; no adapter field in schema)
- **Results are gitignored** — cross-machine coordination must ride on committed docs
- **Files:** `tools/evals/harness/run.sh` (def selection ~line 92, judging ~line 295, scores emission), def schema docs in `tools/evals/README.md` if present

## Acceptance criteria

- [ ] Defs support `adapters: [name, ...]` frontmatter; when the running adapter isn't listed, run.sh emits a SKIP row with reason (`needs adapter: X`) in output and scores.jsonl — skips excluded from pass/fail tallies and from `--skip-completed` completion (a SKIP is not a completed def)
- [ ] Adapter access probe: cheap liveness check (tiny prompt, ~15s timeout) once per run per adapter, replacing bare `command -v` for both agent invocation and judge inclusion; no-access → SKIP-with-reason (defs) / exclusion (judges)
- [ ] Judge participation persisted per trial in scores.jsonl (names + count); baseline records state the judge set used
- [ ] Committed owed-run ledger (`docs/development/deferred-runs.md`): def, required adapter, reason, owed-since, filled-when-run; seeded with the 3 image defs
- [ ] Conformance: at least one deliberately non-matching def SKIPs (not fails, not passes) in a test run

## Out of scope

- Getting crush/agy access on this machine
- The image defs' own content fixes (ticket 30)
