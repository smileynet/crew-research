---
id: "32"
title: "Results support async completion: re-judge mode + cross-machine interchange"
status: open
blocked_by: ["29"]
env: either
spec: "eval-harness"
---

# Results support async completion: re-judge mode + cross-machine interchange

## What to build

Two capabilities that make eval results completable-later rather than frozen at run time:

1. **Re-judge mode** — `run.sh --judge-only <results-dir>`: re-score an existing run's retained `outputs/` against def criteria at the recorded commit, with the currently-reachable judge set. Never overwrites: writes `scores-rejudge-{timestamp}.jsonl` alongside the original, with the judge set recorded per row (ticket 29 schema).
2. **Cross-machine interchange** — a way for a crush/agy-capable machine's runs to land here despite `results/` being gitignored: an export bundle (`run.sh --export <results-dir>` → single tarball/JSON of meta + scores + outputs) and matching import, OR a committed per-run summary format under `docs/development/eval-runs/`. Choose the lighter one that preserves the row-level join keys (def `id`, `adapter`, `judges`).

## Context

- **Feasibility verified 2026-07-19:** raw outputs ARE retained per run (`outputs/{def}-{condition}-task{N}-trial{M}.txt`); meta.json records commit + adapter — so both capabilities are storage-ready today; only tooling and row keys are missing
- **Motivating cases:** (a) local runs scored by a ~2-judge degraded consensus should be upgradable to 4-judge when access exists; (b) crush birth runs for the image defs (ticket 30) happen elsewhere and must be comparable against local kiro runs of the same def `id`s
- **Depends on ticket 29:** row-level `id`/`adapter`/`judges` keys; the deferred-run ledger is where owed re-judges and owed imports get tracked
- **Files:** `tools/evals/harness/run.sh`, `.memory/specs/eval-harness.md` (target schema table)

## Acceptance criteria

- [ ] `--judge-only <results-dir>` produces a versioned rejudge scores file; original scores.jsonl untouched; judge set per row; verdict recomputation reported as a delta vs original
- [ ] Interchange path exists and round-trips: a run exported on machine A imports on machine B with id/adapter/judges intact and joins against B's local runs by def `id`
- [ ] Conformance (anti-vacuous): re-judging a run with deliberately-different judge availability produces a different recorded judge set; importing a tampered bundle (missing id keys) is rejected with a reason
- [ ] Spec's known-gaps table updated to reflect what landed

## Out of scope

- Committing raw results wholesale to git
- Automatic score reconciliation policy (which scores.jsonl "wins" stays a human read of the delta report)
