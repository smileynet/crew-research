---
type: decision
title: "ADR 0001: Use SQLite for local storage"
---

# ADR 0001: Use SQLite for local storage

## Status

Accepted

## Context

We need persistent local storage for the recall tool. The decision was between SQLite, LevelDB, and flat JSON files. SQLite provides FTS5 for full-text search and WAL mode for concurrent access.

## Decision

Use SQLite with FTS5 virtual tables for hybrid BM25 + vector search.

## Consequences

- Single-file database, portable
- No external server dependencies
- FTS5 handles tokenization and ranking
