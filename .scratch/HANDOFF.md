---
created_at: 2026-07-27T12:22:00-07:00
base_commit: be49428
handoff_key: recall-completion-testing
---

# Handoff

## Objective
Complete the recall-import-fix spec and extend tooling quality (testing, doctor improvements, tkt features).

## Constraints
- recall installed editable (`uv tool install -e ./tools/recall`); use `--force --reinstall` after pulls (not just `--force`)
- mise tasks for recall use `uv run --directory tools/recall` (never `uv tool run --from recall` — PyPI squatting)
- CREW_ENV=personal on this machine (full tool access)

## Prior Decisions
- Hash-gate for imports: file-level SHA-256 (not chunk-level — that's ticket 55, deferred)
- Proof duplication: kept `_do_import()` duplicated across 5 proofs (research confirms: below extraction threshold at 5 tests)
- tkt --ac: enumerated only, no blanket --all (design constraint preserving audit moment)
- doctor.sh: DEPLOY_HOME pattern from init.sh + PowerShell fallback for MSYS2 prereq checks

## Current State
10 tickets closed this session: 53, 54, 57, 58, 59, 39, 50, 61, 62, 63. The recall-import-fix spec is fully resolved. See `docs/plan.md` for ticket status. Recall test suite: 50 unit tests + 5 integration proofs. tkt test suite: 48 passed (1 machine-specific failure: `test_validate_live_corpora_pass` NotADirectoryError on Windows — pre-existing, unrelated).

## Next Steps
1. **Ticket 55** (chunk embedding cache) — deferred as likely premature; revisit when import times become a pain point
2. **Ticket 30** (image eval defs conformance) — eval maintenance
3. **Ticket 35** (model cost/quality benchmarking) — research ticket
4. **Ticket 64** (sync-plan --fix) — research/decision needed first
5. Deploy recall extension steering: `mise run init -- --global --tier full` (doctor reports missing `recall-session-start`, `recall-check`)

## Fog
- Whether chunk-level embedding cache (ticket 55) provides meaningful speedup at current corpus size (~38K chunks). No measurements exist.
- sync-plan --fix (ticket 64): needs a design decision on whether R9's report-only constraint should be relaxed.

## Evidence
- Recall test suite: `mise run test:recall` (50 tests, ~13s)
- Recall proofs: `mise run proof:recall` (5 proofs, ~30s)
- tkt tests: `mise run test:tkt` (48 passed, ~80s)
- Research artifacts (ephemeral, delete on next cleanup): `.scratch/research/recall-*.md` (4 files from prior session)
