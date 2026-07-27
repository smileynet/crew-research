---
id: "63"
title: "Add pytest unit test suite for recall (normalize + migration + CLI smoke)"
status: done
blocked_by: []
env: either
---

# Add pytest unit test suite for recall (normalize + migration + CLI smoke)

## What to build

A proper pytest test suite for the recall CLI tool covering the highest-risk untested areas: session format parsing, schema migrations, and CLI command surface.

## Context

- **Current state:** Only 5 integration proofs (G-K) exist, covering import/search pipeline invariants. Zero unit tests. normalize.py (3 JSONL parsers), store.py migrations, and all CLI commands have no automated coverage.
- **Risk:** normalize.py silently loses session data if parsing regresses. Migrations run once per DB upgrade — a break affects all users simultaneously. CLI flag changes go undetected.
- **Research:** Best practices (Google Testing Blog, sqlite-utils, Click docs) recommend: in-memory DBs for store tests, CliRunner or subprocess for CLI tests, mock embedder for speed, real model for proofs.

## Implementation

1. Declare test dependencies in pyproject.toml (`pytest>=8.0`, `pytest-cov`)
2. Create `tools/recall/tests/` with conftest.py (mock embedder fixture, temp DB fixture)
3. `test_normalize.py` — unit tests for all 3 JSONL parsers (happy + error paths)
4. `test_store.py` — migration chain (v1→v4), sources table operations
5. `test_cli.py` — subprocess smoke tests for all commands (exit codes + key output)
6. Add `mise run test:recall` task

## Acceptance criteria

- [ ] `mise run test:recall` runs pytest and passes
- [ ] normalize.py: all 3 format parsers tested (valid input + malformed input)
- [ ] store.py: migration from v1→v4 tested with in-memory DB
- [ ] CLI: all commands tested via subprocess with isolated RECALL_DB
- [ ] Embedder mocked for unit tests (proofs keep real model for fidelity)
- [ ] Test deps declared as optional-dependencies in pyproject.toml

## Out of scope

- Coverage gates or CI setup
- tkt test improvements (separate ticket if needed)
- Performance/scale testing

## Resolution (2026-07-27)

50 tests pass via mise run test:recall (13s). Covers normalize.py (3 parsers), store.py (migration v1-v4 + sources CRUD), and all CLI commands (subprocess smoke). Mock embedder fixture for speed.
