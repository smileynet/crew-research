---
name: assumption-tracking
description: "Surface and challenge assumptions before they become load-bearing. Use when planning, scoping, designing, or making decisions where unvalidated assumptions could cause rework."
metadata:
  type: protocol
  invocation: both
  practice: null
---

# Assumption Tracking

Every plan rests on assumptions. Make them visible before they become load-bearing.

## Process

1. **Surface** — before executing, ask: what must be true for this to work?
2. **Check** — verify against codebase/docs/environment before asking the user
3. **Track** — mark each assumption with status
4. **Report** — include unresolved assumptions in completion

## Rules

- Identify assumptions BEFORE writing implementation code
- One question at a time (don't batch)
- Provide a recommended answer with rationale for each question
- Check the codebase before asking the user — only ask what requires judgment

## Rubber-Stamp Guard

After 3 consecutive acceptances without modification:

**STOP. Say:** "You've accepted 3 in a row without changes. Are these genuinely aligned with your intent, or are we rubber-stamping? I'd rather you push back now than discover a bad assumption later."

Do NOT continue until the user explicitly confirms. This catches autopilot acceptance that leads to rework.

## Status Markers

- ✓ **Confirmed** — validated by evidence
- ⚠ **Assumed** — proceeding on best guess
- ✗ **Invalidated** — proven wrong
- ◌ **Deferred** — acknowledged, not blocking

## Question Categories

| Category | Example | Resolution |
|----------|---------|------------|
| Technical | "The API supports batch operations" | Check docs/spike |
| Scope | "We only need the happy path" | Ask user |
| Environment | "Deploy target has Node 20+" | Check config |
| Dependency | "Auth service will be available" | Check SLA |

## Output Format

```
## Assumptions (N confirmed, N assumed, N invalidated)
- ✓ <assumption> (confirmed: <evidence>)
- ⚠ <assumption> (assumed: <rationale>)
- ✗ <assumption> (invalidated: <what we found>)
```
