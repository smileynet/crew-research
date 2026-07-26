---
id: "59"
title: "Recall ingestion: multi-root project discovery"
status: open
blocked_by: []
env: either
spec: "recall-import-fix"
---

# Recall ingestion: multi-root project discovery

## What to build

Support multiple project roots in `Invoke-RecallIngestAll.ps1` and `ingest-all.sh` so projects on all drives/locations are discovered and imported.

## Context

- **Observed (2026-07-26):** 26 projects on `D:\code` have `.memory/` dirs but are never imported. The ingestion script only scans `$env:USERPROFILE\code`. Sessions from those projects ARE ingested (wing derived from session cwd), but they lack the curated `.memory/` knowledge.
- **Current:** `-ProjectsRoot` accepts a single path. The scheduled task passes no override (uses default `~/code`).
- **On Unix:** `ingest-all.sh` uses `$RECALL_PROJECTS_ROOT` env var (single path).

## Options (implement one)

**A. Comma-separated roots parameter:**
```powershell
[string[]]$ProjectsRoot = @((Join-Path $env:USERPROFILE "code"), "D:\code")
```
Scan all roots, deduplicate by project name (first occurrence wins).

**B. Auto-discovery from multiple known locations:**
Scan `$env:USERPROFILE\code` + all `X:\code` directories on available drives.

**C. Config-driven (env var):**
```
RECALL_PROJECTS_ROOTS=C:\Users\uosmi\code;D:\code
```

Option A is simplest — change the parameter type from `[string]` to `[string[]]` and loop.

## Acceptance criteria

- [ ] `Invoke-RecallIngestAll.ps1` scans multiple roots (parameter accepts array)
- [ ] `ingest-all.sh` supports multiple roots via `RECALL_PROJECTS_ROOT` (colon-separated, like PATH)
- [ ] Scheduled task passes both roots (or the script auto-discovers D:\code)
- [ ] Projects with identical names on different roots don't collide (first-found wins, or prefix with root)
- [ ] After a full run, all projects with `.memory/` across all roots have import wings
- [ ] Profile hook fallback also discovers multiple roots

## Out of scope

- Watching for new roots appearing (manual re-register if a new drive is added)
- Per-project import overrides (e.g., skip specific projects)
