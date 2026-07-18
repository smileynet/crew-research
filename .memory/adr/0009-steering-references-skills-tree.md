---
type: adr
title: "0009: Steering references deploy to the skills tree"
---

# 0009: Steering References Deploy to the Skills Tree

Date: 2026-07-18
Status: accepted

## Context

kiro-cli eager-loads every `.md` under `~/.kiro/steering/` recursively — including `steering/references/`. Steering companion files intended for progressive loading (project-checks.md 46 lines, tool-limitations.md 44 lines) were observed loaded in live session context on every turn (batch5 cross-cutting finding #1). The ADR-0002 pointer pattern was defeated by directory placement: crew-research's own `tool-installation.md` (213 lines, `inclusion: manual`, 2-line pointer) loaded eagerly because the detail file sat under `steering/references/`. Measured managed always-on cost: 90 lines/turn globally + 213 in crew-research sessions, growing with every new steering reference.

Separately, AGENTS.md tools (codex, agy) rendered steering bodies whose `[references/...]` links pointed at files that were never deployed — dangling links, silent context loss.

## Decision

Non-eager references deploy as skill companion files — adjacent to SKILL.md in the tool's skills tree, which is by purpose the non-eager zone. No new directory convention.

1. **Steering bodies deploy eagerly; their `references/` deploy to `skills/{steering-name}/references/`** in each tool's skills tree (kiro: `~/.kiro/skills/`, codex: `~/.agents/skills/`, agy: `~/.gemini/antigravity-cli/skills/`). Steering-only skills get a references-only dir (no SKILL.md) — inert to skill discovery, readable on demand.
2. **Deployed steering bodies get relative links rewritten to absolute paths** into that location, for kiro steering files and AGENTS.md renders alike. AGENTS.md references the deployed companions explicitly, so non-kiro harnesses keep the context and stay compatible.
3. **References-only dirs are recorded in the skills manifest** (`.crew-skills`) so the existing manifest-based prune manages their lifecycle (symlink-safe, unmanaged-safe).
4. **The OS gate on steering refs is dropped** (windows.md/unix.md) — it existed only to limit eager cost; lazy files cost nothing.
5. **Migration:** deploys remove the previously-managed filenames from `steering/references/` by exact name (`project-checks.md`, `tool-limitations.md`, `windows.md`, `unix.md`). Everything else in that dir is user-owned and untouched; the dir's documented purpose becomes "user-owned eager references."
6. **Orphan detail files with no owning steering skill become proper skills** (applied: crew-research's `tool-installation.md` → project-level `.kiro/skills/tool-installation/`).

## Alternatives Rejected

- **Inline-trim references into steering bodies at deploy time** — creates a second maintained variant per reference, guts lookup tables, and doesn't stop always-on growth.
- **New top-level `~/.kiro/references/` dir** — works mechanically but invents a directory convention with its own prune/ownership rules when the skills tree already provides exactly this with existing machinery.
- **Accept eager loading with an explicit line budget** — concedes the three-tier loading design; the demotion pressure that forced ticket 04 recurs every time a reference grows.

## Consequences

- Managed always-on cost drops ~90 lines/turn globally (measured before: project-checks 46 + tool-limitations 44); ~213 more in crew-research sessions.
- On-demand reading now depends on the agent following the rewritten link at the moment of need — measurable via session-skill-usage reports; links sit inside the section that needs them.
- Deployed steering content embeds machine-specific absolute paths (deploy artifacts, not source).
- codex/agy `[references/...]` links resolve for the first time.
