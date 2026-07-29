---
type: spec
title: "Recall Rust Rebuild — Architecture Design"
---

# Recall Rust Rebuild — Architecture Design

Based on performance analysis (2026-07-29) and 4 research topics. Addresses the 5 measured pain points of the Python implementation.

## Problems to Solve

| # | Problem | Measured | Root Cause |
|---|---------|----------|-----------|
| 1 | No-change scan takes 71-96s | 2,600 files, full read+hash each | No stat cache; Python startup |
| 2 | 822 MB database | 139K × 384-dim float32 embeddings | Raw BLOBs, no quantization |
| 3 | 60% scheduled run failure rate | Unhandled exception in PowerShell wrapper | Wrapper script, Python runtime fragility |
| 4 | 11+ min for 45 new chunks | Python fastembed ~15ms/chunk + batch overhead | Python GIL, no parallelism |
| 5 | 80+ min stuck runs | No timeout, no overlap prevention, no progress reporting | No checkpointing, no lock |

## Architecture

```
recall (single Rust binary, ~5 MB)
├── search "query" [--wing W] [--results N]     ← interactive (fast path)
├── add "fact" --wing W --room R --type T       ← agent write-back
├── ingest [path]                               ← scheduled background task
├── import .memory/ --wing W                    ← manual bulk import
├── prime                                       ← session start payload
├── status                                      ← corpus overview
├── health --json                               ← machine-readable diagnostics
└── forget --wing W [--older-than 90d]          ← GC
```

### Storage Layer

**Single SQLite file** (`~/.recall/recall.sqlite3`), WAL mode:

- `chunks` table: content text + metadata (wing, room, type, source, timestamp)
- `embeddings` table: **int8 quantized vectors** via sqlite-vec (4× smaller than current float32)
- `fts_chunks` virtual table: FTS5 full-text index (BM25 search)
- `scan_cache` table: file path → (mtime, size, content_hash) for stat-based change detection
- `ingest_progress` table: checkpointing for resumable ingestion

**Size projection:** 822 MB → ~250 MB (embeddings: 204 MB × 0.25 = 51 MB; text+FTS stays ~600 MB → VACUUM to ~200 MB)

### Embedding Engine Decision

**Two-tier approach:**

1. **Interactive queries (search, prime):** Use pre-computed embeddings in the DB. Embed the QUERY only — single vector, amortized across invocations. Keep ONNX model loaded only for the duration of the command (~500ms cold start is acceptable for a search command).

2. **Background ingestion:** fastembed-rs with ONNX Runtime. Cold start amortized over the full batch (500ms startup + 10ms/chunk × N chunks). At 45 chunks = 500ms + 450ms = ~1s total vs Python's 11 minutes.

**Alternative to evaluate in spike:** model2vec-rs for queries (instant load, 8K samples/sec, acceptable quality for semantic search ranking). Use full ONNX for ingestion quality, model2vec for query-time only.

### File Scanning (Problem #1 fix)

**Git-style stat cache:**

```
Phase 1: stat scan (~5-20ms for 2,600 files)
  for each file in sessions/:
    current = (mtime, size) via jwalk parallel traversal
    if current == scan_cache[path]: skip
    else: add to changed_list

Phase 2: hash confirmation (only changed files)
  for each changed file:
    hash = sha256(content)
    if hash == scan_cache[path].content_hash: skip (timestamp noise)
    else: mark for ingestion
```

**Expected result:** No-change scan drops from 71-96s → **<100ms** (stat 2,600 files in parallel, compare in-memory cache).

### Crash Safety (Problem #3 fix)

1. **WAL mode** — automatic crash recovery, no manual journal management
2. **Exclusive file lock** (`fs2::try_lock_exclusive`) at process start — prevents concurrent access, auto-releases on crash
3. **Batch commits** — process N files per transaction, commit progress marker
4. **No wrapper script** — the binary IS the entry point for the scheduled task (eliminates PowerShell/Python runtime failures)
5. **Idempotent design** — re-running ingestion on the same files produces the same result (content-hash dedup)

### Overlap & Timeout (Problem #5 fix)

```
fn ingest() {
    let lock = try_lock_exclusive("~/.recall/recall.lock");
    if lock.is_err() {
        eprintln!("another recall process is running, skipping");
        return;  // exit 0 — not a failure
    }
    // ... do work ...
    // lock auto-releases when process exits (even on crash)
}
```

Windows Task Scheduler: `MultipleInstances = IgnoreNew` + `ExecutionTimeLimit = PT30M` (30 min max).

### Search Fusion

Keep current RRF (Reciprocal Rank Fusion) for hybrid search:

```
score = 1/(k + bm25_rank) + 1/(k + vector_rank)
```

With sqlite-vec, vector distance computation happens in-DB (no need to load all vectors into memory). FTS5 handles BM25. Fusion in Rust post-query.

## Spikes Before Building

| # | Spike | Question | Time-box |
|---|-------|----------|----------|
| S1 | fastembed-rs cold start | Is 500ms acceptable? Can we cache the session? | 2h |
| S2 | sqlite-vec int8 quality | Does int8 quantization preserve search ranking for our corpus? | 2h |
| S3 | stat cache on Windows | Does jwalk + mtime comparison hit <100ms on 2,600 NTFS files? | 1h |
| S4 | model2vec-rs quality | Is 10-20% quality loss on MTEB acceptable for recall's semantic search? | 2h |

## Crate Dependencies (estimated)

| Crate | Purpose |
|-------|---------|
| clap | CLI parsing |
| rusqlite | SQLite with FTS5 + bundled sqlite-vec |
| fastembed (or ort) | ONNX embedding inference |
| jwalk | Parallel directory traversal |
| sha2 | Content hashing |
| fs2 | Cross-platform file locking |
| anyhow / thiserror | Error handling |
| serde + serde_json | JSON output, config |
| regex | Query parsing, source matching |

## Migration Path

1. Build Rust recall with same CLI interface
2. Run both in parallel for 1 week (verify search results match)
3. Migrate DB: read Python's sqlite3 → quantize embeddings → write to new schema
4. Switch scheduled task to Rust binary
5. Remove Python recall from crew-research

## Performance Targets

| Operation | Python (current) | Rust (target) |
|-----------|:----------------:|:-------------:|
| No-change scan (2,600 files) | 71-96s | < 500ms |
| Ingest 45 new chunks | 701s | < 5s |
| Search (single query) | ~200ms | < 50ms |
| `recall prime` | ~300ms | < 100ms |
| Cold start (no work) | ~500ms | < 50ms |
| DB size | 822 MB | < 250 MB |
| Failure rate | 60% | 0% (self-healing) |
