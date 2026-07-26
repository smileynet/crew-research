---
id: "53"
title: "Sources manifest + hash-gate for recall imports"
status: done
blocked_by: ["52"]
env: either
spec: "recall-import-fix"
---

# Sources manifest + hash-gate for recall imports

## What to build

Add a `sources` metadata table to the recall DB that tracks content hashes per imported file. On each `recall import` run, compare file hashes against the manifest — skip unchanged, re-import changed, clean up deleted.

## Context

- **Current behavior:** Without `--force`, import skips any file whose `source` key exists in the DB (line 215-220). This means content changes are NEVER picked up — stale data persists indefinitely.
- **With this fix:** The scheduled ingestion script needs no flags at all. The hash-gate handles:
  - Unchanged files → skip (fast path, no embedding cost)
  - Changed files → delete old chunks for that source key, re-chunk, re-embed, insert
  - Deleted files → remove orphaned chunks from the DB
- **Prior art:** MemPalace community built `mempalace-refresh` for this exact gap. ChromaDB/LanceDB/CherryHQ all use caller-owned hash tracking. The industry pattern is manifest-first (research: `.scratch/research/sqlite-fts-dedup.md`).

## Design

```sql
CREATE TABLE IF NOT EXISTS sources (
    path TEXT NOT NULL,
    wing TEXT NOT NULL,
    content_hash TEXT NOT NULL,
    file_size INTEGER,
    last_indexed_at INTEGER NOT NULL,
    chunk_count INTEGER NOT NULL,
    PRIMARY KEY (path, wing)
);
```

Import logic:
1. Hash each `.md` file (SHA-256 of content)
2. Check `sources` table for existing entry with same path+wing
3. If hash matches → skip
4. If hash differs → delete old chunks (`DELETE FROM drawers WHERE source = ? AND wing = ?`), re-import, update manifest
5. If file no longer exists on disk → delete chunks, remove from manifest
6. New files → import normally, add to manifest

## Acceptance criteria

- [ ] `sources` table created via schema migration (respects existing DBs)
- [ ] Unchanged files are skipped with no embedding calls (verify via timing or log)
- [ ] Changed files are detected and re-imported (edit a .md file, re-run import, verify new content in search results)
- [ ] Deleted files have their chunks removed on next import run
- [ ] `recall import --force` still works (clears manifest + chunks for the wing, reimports all)
- [ ] Scheduled ingestion script (`Invoke-RecallIngestAll.ps1`) works without `--force` — hash-gate handles staleness
- [ ] `recall status` reports correct chunk counts after change-detection import

## Out of scope

- Session ingest change detection (ticket 54)
- Chunk-level embedding cache (ticket 55)

## Resolution (2026-07-26)

Sources table (schema v4) + hash-gate import: SHA-256 content hashes skip unchanged, detect changes, clean deletions. --force clears manifest+chunks. All AC verified via test cycle.
