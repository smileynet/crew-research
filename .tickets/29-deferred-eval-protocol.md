---
id: "29"
title: "Deferred eval protocol: adapter-scoped defs, access probes, judge visibility, owed-run ledger"
status: done
blocked_by: []
env: either
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

- [x] Defs support `adapters: [name, ...]` frontmatter; when the running adapter isn't listed, run.sh emits a SKIP row with reason (`needs adapter: X`) in output and scores.jsonl — skips excluded from pass/fail tallies and from `--skip-completed` completion (a SKIP is not a completed def)
- [x] Adapter access probe: cheap liveness check (tiny prompt, ~15s timeout) once per run per adapter, replacing bare `command -v` for both agent invocation and judge inclusion; no-access → SKIP-with-reason (defs) / exclusion (judges)
- [x] Judge participation persisted per trial in scores.jsonl (names + count); baseline records state the judge set used
- [x] scores.jsonl rows are self-describing: each row carries the def's immutable `id` and the run's `adapter` (today rows have only mutable `name`; cross-adapter joins and rename survival need the id — this is the row-level key ticket 32's interchange builds on)
- [x] Committed owed-run ledger (`docs/development/deferred-runs.md`): def, required adapter, reason, owed-since, filled-when-run; seeded with the 3 image defs
- [ ] Conformance: at least one deliberately non-matching def SKIPs (not fails, not passes) in a test run

## Out of scope

- Getting crush/agy access on this machine
- The image defs' own content fixes (ticket 30)

## Resolution
**Closed:** 2026-07-19 (Resolution backfilled 2026-07-22). Deferred eval protocol shipped in run.sh — adapter-scoped defs emit SKIP-with-reason rows (excluded from tallies and `--skip-completed`), live access probes replace bare `command -v` for agents and judges, per-trial judge sets persisted, rows carry immutable `id` + `adapter`, and the owed-run ledger (`docs/development/deferred-runs.md`) was seeded with the 3 image defs; along the way discovered the codex judge leg had been silently dead in all prior runs (untrusted temp dir) and fixed it. Evidence: docs/plan.md row 29; closing commit 69547a8 (run.sh +214 lines: `emit_skip`, `probe_tool`/`ensure_agent_probed`, id/adapter/judges row fields, deferred-runs.md added).
Closed pre-tkt; unchecked ACs were not individually verified at close.
