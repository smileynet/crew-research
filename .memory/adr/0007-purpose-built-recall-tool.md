---
type: decision
title: "ADR 0007: Purpose-Built Recall Tool Over MemPalace"
---

# ADR 0007: Purpose-Built Recall Tool Over MemPalace

**Status:** Accepted
**Date:** 2026-06-20
**Deciders:** smileynet

## Context

Agents need cross-session memory recall. MemPalace (3.4.1) provides this but carries 48 files / 1.1MB Python, 80 pip dependencies (200MB install), ChromaDB with known operational issues (lock files, flush windows, breaking migrations), and we use only 15% of its functionality.

## Decision

Build `recall` — a purpose-built CLI tool (673 lines) using SQLite exact-cosine + FTS5 hybrid search with bge-base-en-v1.5 (int8 ONNX, 105MB). Deployed as a crew-research plugin with explicit install/uninstall.

Key choices:
- SQLite over ChromaDB: single file, no server, no migration tooling needed at <50K vectors
- bge-base-en-v1.5 int8 over alternatives: 80% recall@3, 15 chunks/s ingest, 128ms queries — won empirical spike against 7 models
- CLI + skill over MCP: ~200 tokens instruction overhead vs 10-50K for MCP schemas; works with any tool that has shell access
- Global DB (`~/.recall/`) with wing-tagging over per-project DBs: source data (sessions) is global; cross-project search is valuable

## Consequences

- We own maintenance of ~700 lines instead of tracking upstream MemPalace
- No ChromaDB dependency (no grpcio, kubernetes, opentelemetry)
- Install is 105MB model + 15MB wheels instead of 200MB+
- Future: can add features (hooks, consolidation) without upstream constraints
