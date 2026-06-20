# ADR 0002: Per-Project Module Customization

**Status:** Accepted
**Date:** 2026-05-20
**Updated:** 2026-06-13

## Context

Shared modules need project-specific customization (different build commands, additional sections, stricter workflows). No single mechanism handles both simple value injection and structural changes well.

A third case emerged: skills that need project-specific *knowledge* (domain questions, source priorities, cross-reference targets) — structural but not behavioral. Params can't express it; extends causes drift for 80% identical content.

## Decision

Three-layer customization:

1. **Params** for value injection: skills declare `params:` in frontmatter with defaults. Projects provide values via `AGENTS.md` Commands section or steering files. The agent reads these at runtime.

2. **Steering pointer** for knowledge injection: a tiny always-loaded steering file (~50 chars) instructs the agent to read a manual-inclusion detail file when a specific skill activates. Global skill runs unmodified.

3. **Extends** for behavioral changes: project creates a local skill that shadows the shared one. Local skill wins completely in resolution order.

| Mechanism | Use when | Context cost | Drift risk |
|-----------|----------|--------------|------------|
| Params | Simple value substitution | Zero (build-time) | None |
| Steering pointer | Project-specific knowledge injection | ~50 chars always | None |
| Extends (shadow) | Behavioral/process changes | Same as original | High |

Resolution: extends > shared skill + project params > shared skill with defaults. Steering pointers operate alongside (not in the resolution chain) — they inject context, not override behavior.

### Steering pointer mechanism

1. Always-loaded steering file contains: "Before starting [skill], read [detail file]"
2. Detail file uses `inclusion: manual` — zero context cost when inactive
3. When the skill activates, the agent reads the detail file on demand
4. Global skill stays canonical

When NOT to use steering pointers:
- Simple value substitution → params
- Skill runs every turn and needs context immediately → always-loaded steering directly
- Customization changes the skill's process/gates → extends

## Why

- Params alone can't handle structural changes
- Extends alone causes drift when upstream changes
- Steering pointers cover the middle ground (domain knowledge) without forking
- All three mechanisms work without the generator
- Context cost is proportional to usage

## Consequences

- Skill authors should declare `params:` for anything project-specific (commands, paths, thresholds)
- Projects declare build/test/lint commands in the `AGENTS.md` Commands section
- Generator should warn when an `extends:` target has changed upstream
- `adopt-project` and `init-project` should suggest steering pointers when they detect domain context that existing skills could use
- Steering pointers can be scaffolded during init for project-specific knowledge injection
