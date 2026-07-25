---
id: "55"
title: "Chunk-level embedding cache for recall imports"
status: open
blocked_by: ["53"]
env: either
spec: "recall-import-fix"
---

# Chunk-level embedding cache for recall imports

## What to build

Add a global `chunk_cache` table that maps `(chunk_hash, model_id) → embedding`. When re-importing a modified file, hash each chunk and reuse cached embeddings for unchanged chunks — only call the embedding model for genuinely new content.

## Context

- **Current behavior:** When a file is re-imported (via --force or hash-gate detection), ALL chunks are re-embedded even if most content didn't change. For a large file where one section was edited, this wastes embedding compute on the unchanged sections.
- **Prior art:** CherryHQ cherry-studio designed this exact pattern (issue #15417). The key insight: the reusable unit is the **chunk**, not the file. Cache key: `(sha256(chunk_text), model_id) → vector`.
- **Why it works for recall:** recall already uses heading-aware chunking for imports (`##` boundaries). This gives stable chunk boundaries — editing one section doesn't cascade-invalidate downstream chunks (unlike position-based token-window chunking).
- **Expected benefit:** For a 10-section `.memory/` file where 1 section changed, this saves 90% of embedding calls on re-import. At ~15 chunks/sec for the BGE model, this saves seconds per file — meaningful when 11+ projects are imported.

## Design

```sql
CREATE TABLE IF NOT EXISTS chunk_cache (
    chunk_hash TEXT NOT NULL,
    model_id TEXT NOT NULL,
    embedding BLOB NOT NULL,
    last_used_at INTEGER NOT NULL,
    PRIMARY KEY (chunk_hash, model_id)
);
```

Import logic change (inside the per-chunk loop):
```python
chunk_hash = hashlib.sha256(chunk_text.encode()).hexdigest()[:16]
cached = conn.execute(
    "SELECT embedding FROM chunk_cache WHERE chunk_hash = ? AND model_id = ?",
    (chunk_hash, MODEL_ID)
).fetchone()
if cached:
    embedding = cached[0]  # reuse
    conn.execute("UPDATE chunk_cache SET last_used_at = ? WHERE chunk_hash = ? AND model_id = ?",
                 (now, chunk_hash, MODEL_ID))
else:
    embedding = embedder.embed_document(chunk_text)
    conn.execute("INSERT OR REPLACE INTO chunk_cache VALUES (?, ?, ?, ?)",
                 (chunk_hash, MODEL_ID, embedding, now))
```

## Acceptance criteria

- [ ] `chunk_cache` table created via schema migration
- [ ] Unchanged chunks reuse cached embeddings (verify: import, edit one section, reimport — only the edited section triggers an embed call)
- [ ] Cache key includes model_id (model upgrade naturally invalidates cache)
- [ ] Cache has bounded growth (LRU eviction for entries unused > 30 days, or similar)
- [ ] Total embedding call count is logged/reported for observability
- [ ] Correctness: search results are identical whether chunk was embedded fresh or from cache

## Out of scope

- Applying chunk cache to session ingest (sessions use message-pair chunking with less stable boundaries — benefit is lower)
- Content-defined chunking (CDC) for even more stable boundaries
- Cross-model cache sharing
