---
created_at: 2026-07-31T21:21:00-07:00
base_commit: d933532
handoff_key: judge-infra-to-harness-rebuild
---

# Handoff

## Objective
Complete eval harness infrastructure improvements, then explore the harness architecture rebuild (ticket 69).

## Constraints
- CREW_ENV=personal (full tool access incl. agy)
- recall: Python version at `tools/recall/`, installed editable; Rust rebuild at `D:/code/recall`
- tkt: Rust binary at `D:/code/tkt` (`cargo install --path D:/code/tkt`)
- Ticket 70 (restore second judge family) is env:corp — cannot be worked here
- Repo occasionally loses its clone between sessions on this machine (recloned 2× today)

## Prior Decisions
- Judge template: extract to file, hash raw bytes, no normalization (ticket 72)
- Noise floor: 0.5 for single-family panels (ticket 71)
- Agreement ≠ confidence: audit found all claims already correct (ticket 74)
- γ̄ unmeasurable: per-judge scores not retained; documented as gap
- Harness rebuild language: Go (research consensus — I/O-bound, fast compile, goroutines)
- tkt/recall tickets removed from this repo — live in their own projects

## Current State
Tickets 71, 72, 74 closed this session. Project cleanup done (mise.toml fixed, handoff fresh, lint clean). See `docs/plan.md` § "Frontier (2026-07-29)" for the task graph — only ticket 69 and the corp-only 70-73 remain open.

## Next Steps
1. **Ticket 69** — eval harness architecture rebuild exploration. Research done (`.scratch/research/eval-harness-arch-2026.md` — local only). Remaining ACs: Go vs Rust decision (Go), keep vs extract, architecture sketch, def format decision, migration plan, usage audit, incident post-mortem.
2. After 69: implementation tickets from the architecture decision

## Fog
- Keep harness in crew-research vs extract? (tight coupling to skill paths vs clean binary)
- YAML defs vs code-based? (industry uses YAML; Inspect AI uses decorators)
- Whether dual-run methodology should change (challenge but probably keep)
- Inter-trial variance: unmeasured, 3 trials assumed adequate

## Evidence
- Noise floor test: `bash tools/evals/harness/test-noise-floor.sh` (8/8)
- Lint: `bash tools/lint/check-crosslinks.sh` (0 errors)
- Research artifacts (local, untracked): `.scratch/research/{judge-noise-floor,judge-identity-hash,eval-harness-arch,inter-rater-reliability}-2026.md`
- Dry-run: `bash tools/evals/harness/run.sh --dry-run --definition activation-adr-authoring`
