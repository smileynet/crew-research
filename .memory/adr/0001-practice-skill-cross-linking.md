---
type: decision
title: "ADR 0001: Practice-Skill Cross-Linking Convention"
---

# ADR 0001: Practice-Skill Cross-Linking Convention

**Status:** Accepted
**Date:** 2026-05-18

## Context

Practices (human research docs) and skills (agent-loadable modules) serve different audiences but often describe the same concept. Without an enforced relationship, they drift apart — a practice gets updated but the derived skill doesn't, or a skill exists with no traceable rationale.

## Decision

Practices live in `docs/practices/{slug}.md`. Skills live in `atomics/skills/{slug}/SKILL.md`. The relationship is tracked via:

1. **Naming convention** — same slug implies same concept
2. **Frontmatter cross-links** — explicit and machine-readable:

Practice frontmatter:
```yaml
---
name: writing-style
skills: [writing-style]  # derived skills (optional, list)
---
```

Skill frontmatter:
```yaml
---
name: writing-style
description: ...
practice: writing-style  # source practice (optional, string)
---
```

## Enforcement

| Method | What it catches | When it runs |
|--------|----------------|--------------|
| **Lint script** | Broken cross-links (practice references nonexistent skill or vice versa) | CI / pre-commit |
| **Orphan detection** | Skills with `practice:` pointing to missing practice; practices with `skills:` pointing to missing skill | CI |
| **Staleness check** | Practice modified more recently than its derived skill (potential drift) | Advisory warning, not blocking |
| **Authoring skill** | When creating a new skill, prompt asks "Is there a backing practice?" and auto-populates frontmatter | Agent-assisted authoring |

## Implementation

A `tools/lint/check-crosslinks.sh` script that:
1. Parses frontmatter from all `docs/practices/*.md` and `atomics/skills/*/SKILL.md`
2. Validates that every `skills:` reference resolves to an existing skill directory
3. Validates that every `practice:` reference resolves to an existing practice file
4. Warns (non-blocking) when a practice's mtime is newer than its linked skill's mtime

## Why

- Hard to reverse: once people start authoring without links, backfilling is expensive
- Surprising without context: a future contributor won't know practices and skills are related without explicit links
- Real trade-off: co-location (option B) was simpler but mixed audiences; this approach requires maintenance but preserves separation
