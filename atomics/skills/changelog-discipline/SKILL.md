---
name: changelog-discipline
description: "Quality rules for changelog entries. Use when writing, validating, or reviewing changelog content to ensure entries communicate user-facing value."
metadata:
  type: reference
  invocation: both
  practice: null
---

# Changelog Discipline

## The Rule

Entries serve the reader, not the writer. Every entry answers one question: **"why should I care?"**

## Three Tests (apply before committing any entry)

1. **Reader test:** Would someone who's never seen the code understand this?
2. **Impact test:** Does it state what's different for the user, not how the code changed?
3. **Scan test:** Can a reader skim 20 entries and find what affects them in seconds?

If any test fails, rewrite.

## Include or Exclude

| Change type | Include? | Category |
|-------------|:--------:|----------|
| New feature | Yes | Added |
| Bug fix (user-visible) | Yes | Fixed |
| Performance improvement (noticeable) | Yes | Changed |
| Breaking change | Yes | Changed or Removed |
| Deprecation | Yes | Deprecated |
| Security fix | Yes | Security |
| Docs, CI, tests, refactoring, formatting | **No** | — |
| Dependency bumps (no behavior change) | **No** | — |

**Edge cases that ARE included:** Refactors with observable side effects (faster, different errors). New docs for previously undocumented features. Dev dependency changes that alter build output.

## Scale Depth to Impact

- **Trivial fix** → one line: `Fixed tooltip flickering on hover`
- **Feature** → 1-2 sentences: what changed + why it matters
- **Breaking change** → paragraph with before/after code + migration path

## Match Your Audience

| Project type | Language to use | Example |
|-------------|-----------------|---------|
| Library/SDK | API surface (function names, types) | "Add `parse()` option to skip validation" |
| CLI tool | Commands, flags, output | "New `--dry-run` flag shows what would change" |
| Application | Features, screens, workflows | "Export reports as PDF from the dashboard" |
| Framework | Extension points, config, hooks | "Middleware can now return early" |

## Never Include in Entry Text

- Internal filenames or class names (`generate.py`, `FooHandler`)
- Architecture patterns (`strategy pattern`, `event sourcing`)
- Internal identifiers (ADR numbers, config file paths)
- Implementation verbs (`refactored`, `migrated X to Y` — unless user action required)
- Jargon self-check: if it names a pattern, abstraction, or internal component, rewrite to describe the observable outcome

## Breaking Changes

- Separate section or bold `**Breaking:**` prefix — readers must not miss these
- Before/after code example when behavior changes
- Migration path is mandatory: what does the reader need to do?
- Deprecation entries must include timeline ("removed in v4.0")

## Good vs Bad

| ✅ Good | ❌ Bad |
|---------|--------|
| Projects can now inherit base configs with `extends:` | Added resolve_extends function to generate.py |
| Fixed crash when project has no theme configured | Fixed bug in line 47 of generate.py |
| Always-on context reduced by ~90 lines per session | Steering companion files deploy to skills tree (ADR 0009) |
| Deploys no longer delete skills from other sources | Prune logic respects per-tool manifest ownership |
| Background jobs run 3x faster (no action needed) | Migrated from Sidekiq to Oban |
| CJK text renders correctly on Windows | Use explicit platform fonts instead of system-ui |

## Jargon Self-Check

After drafting all entries, re-read asking: "does this use internal terms?" If it names an internal component, pattern, or file — rewrite to describe what the user observes instead.

## References

For extended examples, anti-patterns gallery, audience guide, and depth scaling patterns, see [references/patterns.md](references/patterns.md).
