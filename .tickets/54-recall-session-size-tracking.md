---
id: "54"
title: "Session size tracking + active-file skip for recall ingest"
status: done
blocked_by: ["53"]
env: either
spec: "recall-import-fix"
---

# Session size tracking + active-file skip for recall ingest

## What to build

Track session file sizes in the `sources` table so growing sessions are re-ingested, and skip files with very recent mtimes (active sessions that haven't finished yet).

## Context

- **Current behavior:** `is_file_ingested` is a binary exists-check. Once ANY chunk from a session exists, the file is permanently skipped. If `recall ingest` runs mid-session (4h scheduled task fires during a long implementation session), only messages written so far are captured. Later messages are permanently lost.
- **Evidence from prior art:** MemPalace had the identical bug — the community created `mempalace-refresh` specifically to address growing session logs.
- **Two fixes needed:**
  1. **Size tracking:** Store `file_size` when ingesting. On next run, if current file size > stored size → delete old chunks, re-ingest the full file.
  2. **Active-file skip:** If file mtime is < 5 minutes ago, defer to next run (session likely still active — ingesting now would create stale partial chunks).

## Design

Reuse the `sources` table from ticket 53 for sessions too:
```sql
-- Entry for an ingested session:
INSERT INTO sources (path, wing, content_hash, file_size, last_indexed_at, chunk_count)
VALUES ('ingest:session-uuid.jsonl', wing, '', file_size, now, N);
```

Ingest logic change:
1. For each session file, check `sources` table
2. If not present → ingest normally, record in manifest
3. If present AND current `file_size > stored file_size` → delete old chunks, re-ingest, update manifest
4. If present AND sizes match → skip (current behavior)
5. If `mtime < now - 5 minutes` → skip (active session, defer)

## Acceptance criteria

- [ ] A session ingested mid-progress is re-ingested on the next run after the file grows
- [ ] An active session (mtime < 5m ago) is skipped entirely (not partially ingested)
- [ ] A completed session (size unchanged between runs) is still skipped efficiently
- [ ] Session chunks don't accumulate (old chunks deleted before re-ingest)
- [ ] Large sessions (220+ chunks) don't duplicate on re-ingest

## Out of scope

- Incremental append-only ingestion (only ingest NEW messages since last run) — this is a possible optimization but full re-ingest of changed sessions is simpler and correct
- Chunk-level embedding cache (ticket 55)

## Resolution (2026-07-27)

Size tracking via sources table + active-file skip (5m mtime threshold). Growing sessions re-ingested, active sessions deferred, unchanged skipped. All AC verified.
