---
name: skill-authoring
description: "Write and improve agent-loadable skills. Use when creating a new skill, improving an existing skill's activation, restructuring a skill that's too broad, writing skill frontmatter, or diagnosing why a skill doesn't trigger. Trigger: new skill, write a skill, skill format, skill template, activation trigger, skill description, SKILL.md."
metadata:
  type: reference
  invocation: both
  practice: null
---

# Skill Authoring

## Format

```yaml
---
name: slug-name
description: "Trigger-rich description. Use when [situations]. Trigger: keyword1, keyword2."
metadata:
  type: protocol | reference | process | reasoning-mode | decision
  invocation: both | user-only | agent-only
  practice: slug-or-null
---
```

Body: Markdown, <100 lines total (including frontmatter).

## Rules

1. **One concern per skill** — if it covers two topics, split it
2. **Description IS the trigger** — kiro-cli matches tasks against this field. Generic = never activates
3. **Process, not knowledge dump** — tell the agent what to DO, not everything to KNOW
4. **Under 100 lines** — forces focus; put depth in `references/` companion files
5. **Progressive loading** — SKILL.md is the entry point; link `references/*.md` for detail

## Writing a Good Description

The description must contain:
- What it does (one clause)
- "Use when" clause with specific situations
- Trigger keywords (words users actually say)

Bad: `"Helps with code quality"` — matches everything, activates on nothing.

Good: `"Code review standards and checklist. Use when reviewing code, PRs, or implementations for correctness, security, and quality."` — clear situations, specific terms.

## Anti-Patterns

| Problem | Symptom | Fix |
|---------|---------|-----|
| Too broad | Covers 5+ topics | Split into focused skills |
| Knowledge dump | Lists facts, no actions | Rewrite as steps/process |
| Generic trigger | Activates on everything or nothing | Add "Use when" + keywords |
| Over 100 lines | Hard to maintain, wastes context | Extract to references/ |
| No frontmatter | Won't be discovered | Add complete YAML header |

## Companion Files

Place in `references/` within the skill directory:
- Examples, lookup tables, extended patterns
- Loaded only when agent needs more depth
- Keep each companion file focused (one topic)

## Testing Activation

After writing, verify the skill would activate by checking:
- Does the description contain words a user would say when they need this?
- Is it distinct from other skills' descriptions? (no overlap)
- Would you find it by searching for the problem it solves?

## Critique Checklist

When reviewing an existing skill:
1. Single concern? (one thing done well)
2. Description has "Use when" + trigger keywords?
3. Body is process/steps, not reference material?
4. Under 100 lines?
5. Scope declared? (what it does NOT cover)
