---
type: specification
title: "Practice-Skill Cross-Linking Specification"
---

# Practice-Skill Cross-Linking Specification

## Overview

Practices (human research docs) and skills (agent-loadable modules) are separate artifacts serving different audiences. Cross-links maintain their relationship without co-location.

## Locations

- Practices: `docs/practices/{slug}.md`
- Skills: `atomics/skills/{slug}/SKILL.md`

## Linking Convention

### Practice → Skill (frontmatter)

```yaml
---
title: Writing Style
skills: [writing-style, writing-style-review]
---
```

### Skill → Practice (frontmatter)

```yaml
---
name: writing-style
practice: writing-style
---
```

## Rules

- Same slug implies same concept (naming convention)
- Links are optional: not all practices produce skills; not all skills need a backing practice
- A practice may produce multiple skills (one-to-many)
- A skill references at most one practice (many-to-one)

## Enforcement

| Method | What it catches | When |
|--------|----------------|------|
| Lint script (`tools/lint/check-crosslinks.sh`) | Broken references (practice points to nonexistent skill or vice versa) | CI / pre-commit |
| Orphan detection | Dangling `practice:` or `skills:` references | CI |
| Staleness warning | Practice mtime newer than linked skill mtime | Advisory (non-blocking) |
| Authoring prompt | When creating a skill, ask "Is there a backing practice?" | Agent-assisted |

## Lint Script Behavior

1. Parse frontmatter from all `docs/practices/*.md`
2. Parse frontmatter from all `atomics/skills/*/SKILL.md`
3. For each `skills:` entry in a practice: verify `atomics/skills/{slug}/` exists
4. For each `practice:` entry in a skill: verify `docs/practices/{slug}.md` exists
5. Warn (non-blocking) when practice mtime > skill mtime for linked pairs

## Practice Format

```yaml
---
title: {Title}
skills: [{slug}, ...]    # optional
---

# {Title}

## Overview
[What this practice covers and why it matters]

## Principles
[Research-backed guidance with rationale]

## Anti-Patterns
[What to avoid and why]

## Examples
[Concrete illustrations]

## Sources
[Citations and references]
```

Practices have no line limit. They are comprehensive research documents for humans.
