---
id: "33"
title: "Result identity hashes: detect which eval results reflect current skill/def/model state"
status: open
blocked_by: ["29"]
spec: "eval-harness"
---

# Result identity hashes: detect which eval results reflect current skill/def/model state

## What to build

Per-row component hashes in scores.jsonl so staleness is computed, not remembered. A result is "current" iff recomputing its hashes today matches what the row recorded. Components stay separate so the drift KIND is visible:

- `skill_hash` — sha256 over `atomics/skills/{slug}/**` (sorted file list, content-concatenated) for every skill in the row's condition; steering evals hash the steering source
- `def_hash` — the def yaml + all referenced fixture files (incl. per-task `fixture:` overrides — ticket 14 precedent: fixture change = non-comparable history)
- `env_id` — adapter + tool version + explicit `--model` or `tool-default` + judge set (ticket 29 field)

Plus a checker: `check-staleness.sh <results-dir>` (or a run.sh flag) that recomputes current hashes, diffs, and reports per def: CURRENT / SKILL-DRIFT / DEF-DRIFT (non-comparable) / ENV-DRIFT.

## Context

- **Motivating incidents:** a03798e mid-run merge made handoff-decaying's 07-17 score describe pre-merge content — found only by manual archaeology (ticket 28 confound); ticket 14's "pre-2026-07-18 history non-comparable" is a prose flag a hash would make mechanical; session-analysis "skill fixed mid-window → restart clock" rule is the same problem in field measurement
- **Payoff beyond staleness:** `--changed-only` mode — run only defs whose hashes drifted since the last baseline (10h suite → minutes after a one-skill edit; same pattern as archwright-check --changed-only)
- **Known limit (document, don't solve):** model identity is the observable id + tool version only; server-side silent model updates behind the same id are invisible
- **Hashing inputs verified 2026-07-19:** conditions.skills lists slugs; fixtures per-task via `tasks[N].fixture`; MODEL is an optional flag defaulting to the tool's default; judge set lands per ticket 29
- **Files:** `tools/evals/harness/run.sh` (row emission), new checker script, `.memory/specs/eval-harness.md` (schema table)

## Acceptance criteria

- [ ] Every scores.jsonl row carries `skill_hash`, `def_hash`, `env_id` (short sha256 prefixes fine); meta.json records the hash algorithm/version
- [ ] Staleness checker reports per-def drift kind against current tree; exit codes per validation contract (0 all current, 1 drift found)
- [ ] Mid-run drift detectable: hashes computed per def at execution time, not once at run start (catches the a03798e-shaped incident)
- [ ] Conformance (anti-vacuous): editing a skill file, a fixture, and running under a different adapter each flips exactly the expected component in the checker's report
- [ ] Optional stretch: `--changed-only <baseline-results-dir>` runs only drifted defs; skipped-as-current defs reported

## Out of scope

- True model-weights identity (unobservable)
- Retroactively hashing old result dirs (they predate the fields; the 2026-07-19 baseline is the last unhashed reference set)
