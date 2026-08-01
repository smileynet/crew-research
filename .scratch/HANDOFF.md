---
created_at: 2026-07-31T21:00:00-07:00
base_commit: d262845
handoff_key: judge-infrastructure-complete
---

# Handoff

## Objective
Improve eval harness quality and prepare for architecture rebuild. Judge infrastructure tickets (71, 72, 74) are done; eval harness rebuild exploration (69) is next.

## Constraints
- recall installed editable (`uv tool install -e ./tools/recall`); use `--force --reinstall` after pulls
- mise tasks for recall use `uv run --directory tools/recall` (never `uv tool run --from recall` — PyPI squatting)
- CREW_ENV=personal on this machine (full tool access)
- tkt is now a Rust binary at D:/code/tkt (installed via `cargo install --path D:/code/tkt`)
- recall Rust rebuild in progress at D:/code/recall (Python version still installed from tools/recall)

## Prior Decisions
- Judge hash: extract template to file, hash raw bytes, no whitespace normalization (JudgeSense: JSS 0.389-0.992)
- Noise floor: 0.5 points for single-family panels (MDE at 3 trials + systematic bias)
- Agreement ≠ confidence: ADR 0010 covers this; all existing claims already correct
- γ̄ unmeasurable: per-judge scores not retained (only median stored); documented as measurement gap
- Eval harness rebuild: Go recommended over Rust (I/O-bound, fast compile matters)

## Current State
Judge infrastructure complete (tickets 71, 72, 74 closed this session). Tool extraction done: tkt and recall have their own repos with their own tickets. Remaining frontier for this machine: ticket 69 (eval harness architecture rebuild — exploration/decision, not implementation).

## Next Steps
1. **Ticket 69** — Eval harness rebuild exploration (Go vs Rust confirmed as Go by research; keep in crew-research vs extract; architecture sketch; migration plan). Research already done in `.scratch/research/eval-harness-arch-2026.md` (local only, not committed).
2. **Ticket 70** — Restore second judge family (env: corp — wrong machine)
3. Check if any new tickets emerge from the harness rebuild decision

## Fog
- Whether the eval harness should stay in crew-research or extract (tight coupling argument vs clean binary argument)
- Whether YAML definitions should stay or migrate to code-based (Inspect AI pattern)
- Trial repetition: is 3 sufficient? Inter-trial variance is unmeasured.

## Evidence
- Noise floor test: `bash tools/evals/harness/test-noise-floor.sh` (8 tests)
- Lint: `bash tools/lint/check-crosslinks.sh`
- Research: `.scratch/research/*.md` (4 files, local-only — judge noise, identity hash, eval arch, inter-rater)
