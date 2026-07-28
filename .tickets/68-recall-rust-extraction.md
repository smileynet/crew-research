---
id: "68"
title: "Explore: extract recall to own repo and rebuild in Rust"
status: open
blocked_by: []
---

# Explore: extract recall to own repo and rebuild in Rust

## What to build

**Exploration ticket — deliverable is a decision + architecture, not implementation.**

Evaluate extracting `tools/recall/` from crew-research into its own repository, rebuilt
in Rust. Recall is the highest-value rebuild candidate: eliminates the uv/Python runtime
dependency, gives single-binary distribution, dramatically improves embedding latency
(fastembed-rs: <5ms vs Python fastembed: ~15ms), and removes the "PyPI squatting" install
footgun permanently.

## Research (completed 2026-07-28)

Findings in `.scratch/research/`:
- `rust-vs-go-cli.md` — Rust strongly recommended (fastembed-rs, rusqlite, sqlite-vec)
- `recall-rebuild-architecture.md` — local search options, embedding runtime, architecture
- `monorepo-decomposition.md` — extraction decision criteria
- `agent-ecosystem-decomposition.md` — memory tool patterns across AI frameworks

## Key architecture questions

1. **Embedding engine:** fastembed-rs (proven, same models as current) vs ort (lower-level)
   vs candle (pure Rust, heavier). fastembed-rs is the clear recommendation.
2. **Storage:** Keep SQLite + FTS5? Add sqlite-vec for HNSW vector search? Current hybrid
   (BM25 + cosine in Python) maps to FTS5 + sqlite-vec in Rust.
3. **Ingestion strategy:** Current batch model (scheduled task every 4h + on-demand) vs
   filesystem watcher vs incremental (file-hash gate already exists from ticket 53).
4. **Search fusion:** Current RRF (Reciprocal Rank Fusion) for BM25+vector — keep or
   simplify?
5. **Agent write-back:** `recall add` for agent-written facts. Keep the wing/room/type
   taxonomy or simplify?
6. **Distribution:** Single binary on GitHub releases + cargo-binstall + brew. No more
   "install from a crew-research clone."
7. **Session review:** What does actual recall usage look like? Which commands are used,
   what's the search-to-add ratio, how often does recall prime fire?

## Challenge existing decisions

- **Wing/room/drawer hierarchy:** Is this overengineered? Do sessions actually use rooms?
  Or is everything just wing + flat search?
- **Chunk-level dedup:** Ticket 55 (deferred) — does the rebuild make this trivial?
- **Scheduled ingestion model:** Should it be event-driven (filesystem watch) instead?
- **The "prime" concept:** Is a fixed prime payload the right interface, or should agents
  just search?

## Acceptance criteria

- [ ] Decision: extract to own repo YES/NO
- [ ] Architecture: storage layer, embedding engine, search fusion algorithm
- [ ] Contract: which commands survive, which change, which are dropped
- [ ] Distribution plan: install methods per platform (no Python/uv dependency)
- [ ] Data migration: can the Rust version read the existing SQLite DB directly?
- [ ] Session usage audit: recall command frequency, search patterns, prime effectiveness
- [ ] Performance targets: embedding latency, search latency, startup time
- [ ] If YES: repo created, scaffold committed

## Out of scope

- Full implementation
- Changing the steering integration (crew-research still detects `recall` on PATH)
