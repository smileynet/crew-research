---
name: changelog-discipline
description: "Quality rules for changelog entries. Use when writing, validating, or reviewing changelog content to ensure entries communicate user-facing value."
metadata:
  type: reference
  invocation: both
  practice: null
---

# Changelog Discipline

## Entry Quality Rules

1. **Technology-replacement test:** If you replaced the underlying technology, would the entry still be true? If yes, it describes value.
2. **Can't-name-a-file test:** If you can't write the entry without naming a file or class, it's not user-facing.
3. **Impact over mechanism:** State what changed for the user, not how the code does it.
4. **One entry per logical change:** Group related commits into a single entry.
5. **Active voice, specific words:** "Users can now X" not "X functionality was added."

## Decision Test

| Commit type | Changelog? | Category |
|-------------|:----------:|----------|
| feat | Yes | Added |
| fix | Yes | Fixed |
| perf | Yes | Changed |
| BREAKING CHANGE | Yes | Changed/Removed |
| docs, chore, test, ci, refactor | No | — |

## Good vs Bad

| ✅ Good | ❌ Bad |
|---------|--------|
| Projects can now inherit base crews with `extends:` | Added resolve_extends function to generate.py |
| Fixed crash when project has no theme configured | Fixed bug in line 47 of generate.py |

## Breaking Change Requirements

- Entry under "Changed" or "Removed"
- Migration path mandatory: "use X instead"
- Deprecation entries must include timeline
