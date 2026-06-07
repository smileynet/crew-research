# ADR 0003: Skills-Only Deployment (No Prompts Directory)

## Context

kiro-cli 2.5.0 shows descriptions for skills in the `/` picker but only shows
"Prompt from X (prompt)" for files in `.kiro/prompts/`. Testing confirmed
`metadata.invocation: user-only` is ignored — all skills are both auto-activatable
and user-invocable regardless of the field.

## Decision

Deploy all content (including user-invocable workflows) as skills only.
Stop deploying to `~/.kiro/prompts/`. The init script prunes prompts/ on deploy.

## Why

- Skills show descriptions in picker (better UX)
- No functional difference in invocation (both use `/name` and `@name`)
- Eliminates duplicate deployment (was deploying same content to both locations)
- Simplifies init.sh (one deployment path instead of two)

## Consequences

- User-invocable workflows may auto-activate if description matches task context
- Mitigated by specific descriptions (e.g., "Use when ending a work session")
- Projects with local `.kiro/prompts/` should migrate to `.kiro/skills/`
- doctor.sh warns when local prompts/ shadows global skills

## Why We Kept `metadata.invocation`

The field has no effect in kiro-cli today, but maps to real behavior in Claude Code:
- `user-only` → `disable-model-invocation: true` (agent can't auto-load)
- `agent-only` → `user-invocable: false` (hidden from user menu)
- `both` → default (no extra frontmatter)

We apply it consistently across all 55 skills for forward compatibility. If we
add Claude Code deployment support, the generator reads this field and emits
the correct tool-native frontmatter without touching skill content.
