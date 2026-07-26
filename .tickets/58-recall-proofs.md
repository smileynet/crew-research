---
id: "58"
title: "Recall proofs: idempotency, wing isolation, name normalization"
status: open
blocked_by: ["56"]
env: either
spec: "recall-import-fix"
---

# Recall proofs: idempotency, wing isolation, name normalization

## What to build

Platform proofs (automated tests) that verify recall's import/ingest correctness properties. These run as part of `mise run proofs` and catch regressions.

## Context

- The --force nuke bug (ticket 52) went undetected for weeks because there were no automated checks on import behavior.
- The wing name split (ticket 56) accumulated silently because no test verifies normalization.
- Proofs are the crew-research mechanism for testing platform assumptions that, if violated, would silently degrade quality.

## Proofs to write

### G. Import idempotency
- Import a fixture `.memory/` dir
- Import it again (same args)
- Assert: chunk count stable (no accumulation), zero files imported on second run

### H. --force wing isolation
- Import wing A and wing B
- Force-reimport wing A
- Assert: wing B chunk count unchanged
- Assert: wing A chunk count matches fresh import

### I. Wing name normalization
- `recall import dir --wing foo-bar` (explicit hyphenated)
- `recall import dir` (auto-derive from dir named `foo-bar`)
- Assert: both land in wing `foo_bar` (same normalized name)
- `recall search "query" --wing foo_bar` returns results from both imports

### J. Cross-wing search (eval-adjacent)
- Import two wings with known content
- Search without `--wing` for a term present in both
- Assert: results include content from both wings

### K. Search relevance after force-reimport
- Import a wing, note search results for a query
- Force-reimport the same wing
- Assert: same query returns equivalent results (chunk IDs change but content matches)

## Implementation

Proofs go in `tools/proofs/definitions/` as YAML definitions with the recall-specific adapter, or as standalone shell scripts in `tools/proofs/recall/` if they need direct DB access. Each proof:
- Sets up a temp DB (`RECALL_DB=/tmp/proof-recall-*.sqlite3`)
- Runs import/search commands
- Asserts invariants
- Cleans up

## Acceptance criteria

- [ ] 5 proof scripts (G-K) exist and pass on this machine
- [ ] Proofs use an isolated temp DB (never touch the real `~/.recall/recall.sqlite3`)
- [ ] Proofs run via `mise run proofs` or a recall-specific task
- [ ] Proofs document the invariant being tested (comment header)
- [ ] At least one proof would have CAUGHT the --force nuke if it existed before ticket 52

## Out of scope

- Eval definitions for recall search quality (existing `recall-search-precision.yaml` covers agent routing; these proofs cover the storage layer)
- Performance benchmarks (not a correctness concern at current scale)
