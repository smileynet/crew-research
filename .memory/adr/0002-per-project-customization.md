# ADR 0002: Per-Project Module Customization (Params + Extends)

**Status:** Accepted
**Date:** 2026-05-20

## Context

Shared modules need project-specific customization (different build commands, additional sections, stricter workflows). No single mechanism handles both simple value injection and structural changes well.

## Decision

Two-layer customization:

1. **Params** for value injection (80% of cases): skills declare `params:` in frontmatter with defaults. Projects provide values in `.crew-config.yaml`. Generator substitutes at build time.

2. **Extends** for structural changes (20% of cases): project creates a local skill that shadows the shared one. Local skill wins completely in resolution order.

Resolution: local skill > shared skill + project params > shared skill with defaults.

## Why

- Params alone can't handle structural changes (new sections, replaced content)
- Extends alone causes drift when upstream changes
- The hybrid covers all 4 tested use cases while keeping the common case (params) simple
- Both mechanisms work without the generator (params = manual substitution, extends = local file shadows shared)

## Consequences

- Skill authors should declare `params:` for anything project-specific (commands, paths, thresholds)
- Generator must support param substitution from `.crew-config.yaml`
- Generator should warn when an `extends:` target has changed upstream
- Skill format spec needs `params:` field added to frontmatter
