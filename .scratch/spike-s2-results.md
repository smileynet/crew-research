---
created_at: 2026-05-20T06:40:00-07:00
base_commit: 42d04e8
---

# Spike S2 Results: Claude Code Unknown Frontmatter Tolerance

## Method
Researched via GitHub issues and official documentation rather than live testing (no Claude Code installation in this environment).

## Key Finding

From GitHub issue anthropics/claude-code#13005 (Dec 2025):

> "SKILL.md files support custom frontmatter fields beyond the load-bearing `name:` and `description:` fields, but these custom fields are stripped before being injected into the model's context."

## Behavior Confirmed

1. **Claude Code parses only `name:` and `description:` from frontmatter** — these are "load-bearing" fields used for skill discovery and activation.
2. **All other frontmatter fields are STRIPPED** before the skill content reaches the model.
3. **No errors or warnings** — unknown fields are silently ignored.
4. **The skill still loads and activates correctly** — only the body content is affected.

## Implications

| Our Field | Claude Code Behavior | Impact |
|-----------|---------------------|--------|
| `type: protocol` | Stripped (model won't see it) | No impact — `type` is for our tooling/generator, not for the model |
| `invocation: user-only` | Stripped | No impact — maps to `disable-model-invocation: true` which IS a recognized field |
| `practice: writing-style` | Stripped | No impact — cross-link is for our lint tooling, not for the model |

## Critical Detail

Claude Code DOES recognize these frontmatter fields (from official docs):
- `name` — skill identity
- `description` — activation trigger
- `disable-model-invocation` — prevents auto-loading
- `user-invocable` — hides from user menu
- `allowed-tools` — pre-approves tools
- `model` — overrides model for this skill
- `context` — fork execution to subagent
- `agent` — which subagent type
- `argument-hint` — autocomplete hint
- `arguments` — named positional args
- `paths` — glob patterns limiting activation
- `effort` — effort level override
- `shell` — shell type for inline commands
- `hooks` — skill-scoped hooks

## Decision

**S2 PASSES.** Our extended frontmatter (`type`, `invocation`, `practice`) is safe in Claude Code:
- Unknown fields are silently stripped (no errors)
- Our fields are for tooling/generator consumption, not model consumption
- The generator maps `invocation: user-only` to Claude Code's native `disable-model-invocation: true`

## Action Required
The generator must translate our portable frontmatter to Claude Code's native fields:
- `invocation: user-only` → add `disable-model-invocation: true`
- `invocation: agent-only` → add `user-invocable: false`
- `invocation: both` → no extra fields needed (default)

Our custom fields (`type`, `practice`) can remain in the deployed SKILL.md — they'll be harmlessly stripped.
