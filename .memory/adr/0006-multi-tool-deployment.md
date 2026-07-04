---
type: decision
title: "ADR 0006: Multi-Tool Deployment Architecture"
---

# ADR 0006: Multi-Tool Deployment Architecture

**Status:** Accepted  
**Date:** 2026-06-14  
**Deciders:** smileynet

## Context

crew-research currently deploys exclusively to kiro-cli (`~/.kiro/`). Users working with OpenAI Codex (CLI, IDE extension, or app) need the same skills available in `~/.agents/skills/` and steering rendered into `~/.codex/AGENTS.md`.

The problem is reproducibility across machines: global skills exist only in local `~/.<tool>/` paths. When setting up a second machine, there's no way to replicate the deployment without manual symlink management.

## Decision

### 1. Single source, multi-target rendering

`init.sh` deploys to each tool's native discovery paths from the same source (`atomics/skills/`). No symlinks between tool directories — each gets its own copy rendered into idiomatic format.

### 2. Tool-specific deployment logic

| Artifact | kiro-cli target | Codex target |
|----------|----------------|--------------|
| Skills | `~/.kiro/skills/{slug}/SKILL.md` (+ references/) | `~/.agents/skills/{slug}/SKILL.md` (+ references/) |
| Steering | `~/.kiro/steering/{slug}.md` (separate files, body only) | `~/.codex/AGENTS.md` (all steering concatenated) |
| Project skills | `.kiro/skills/` | `.agents/skills/` |
| Project context | `AGENTS.md` (already shared) | `AGENTS.md` (already shared) |

Skills use identical SKILL.md format — no transformation needed, just path difference.

Steering differs: kiro-cli reads individual files from a directory; Codex reads a single `~/.codex/AGENTS.md` file. The Codex target concatenates all tier steering into one file with section headers.

### 3. Machine-local config via `.mise.local.toml`

Each machine declares which tools and tier to deploy via `.mise.local.toml` (gitignored). An `.example` file is committed. The init script reads `CREW_TOOLS` to determine targets.

```toml
[env]
CREW_TOOLS = "kiro-cli codex"
CREW_TIER = "basic"
CREW_DEPLOY = "global"
```

### 4. New machine setup

```bash
git clone crew-research
cp .mise.local.toml.example .mise.local.toml
# Edit CREW_TOOLS for this machine
mise run init -- --global
```

The `--tool` flag still works for one-off deploys; `.mise.local.toml` provides the default when `--tool` is omitted.

## Alternatives Considered

### Symlinks between tool directories

`~/.codex/skills/ → ~/.kiro/skills/*` — rejected because:
- Steering formats differ (directory vs single file)
- Couples tool evolution; can't adapt one without affecting the other
- Symlink management is OS-dependent (Windows vs Unix)

### Single unified path with tool config pointing to it

Make all tools read from `~/.agents/skills/` — rejected because:
- kiro-cli can't be configured to read from `~/.agents/`
- Would require upstream tool changes

## Consequences

- Adding a new tool = writing a target deploy function (path layout + any format rendering)
- Skills remain tool-agnostic at source; rendering is per-target
- Each machine is self-describing (`.mise.local.toml` declares what's deployed)
- No manual symlinks to maintain
- Pruning logic runs per-tool (stale files in `~/.agents/skills/` get cleaned like `~/.kiro/skills/`)
