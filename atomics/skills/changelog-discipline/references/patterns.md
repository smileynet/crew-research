# Changelog Patterns & Anti-Patterns

Extended reference for the changelog-discipline skill. Examples sourced from popular open-source projects.

## Great Entry Examples

### Symptom-first bug fix (Astro)

```
Fixes `astro build` throwing `TypeError: Missing parameter` for dynamic routes
when `build.format: 'preserve'` and `trailingSlash: 'always'` are used together.
```

Why it works: States what the user sees (the error), the trigger conditions, and resolves it — all without naming internal functions.

### What + why in one line (Tailwind CSS)

```
Use explicit platform fonts instead of `system-ui` so CJK text respects the
page's `lang` attribute on Windows (#20318)
```

Why it works: States the change AND the user-visible reason in one sentence. The PR link gives details to the curious.

### Before/after migration (Rails)

```
`ActiveRecord::Relation#update` no longer escapes the relation when given ids.
Passing ids used to delegate to the model class:

    post.comments.update!(comment_id, body: "...")
    # could update any comment

Records are now looked up through the relation, so an id outside it raises
`ActiveRecord::RecordNotFound`.
```

Why it works: Shows the old (dangerous) behavior with code, explains the new (safe) behavior, and makes the breaking change obvious.

### Scope-prefix terse entry (Vite)

```
fix(css): don't pass empty targets to lightningcss (#23295)
```

Why it works: Scope tells you the subsystem, description is the behavior change, link gives details. Maximum information density for scanners.

### Domain-scoped features (Elixir)

```
* [String] Add `String.to_existing_atom/2` and `String.to_unsafe_atom/1`
* [Kernel] Warn on binary patterns with segments that are not byte-aligned
```

Why it works: Module prefix means you instantly know if it affects your code.

### Terse flat list (Deno)

```
- feat(add): `--unscoped` flag to alias packages by their unscoped name (#36319)
- fix(ext/node): sort fs.readdir entries to match Node.js (#36341)
```

Why it works: Consistent prefix convention, one line each — extremely scannable.

---

## Anti-Patterns Gallery

### Too vague (says nothing actionable)

```
❌ - Improvements to the export module
❌ - Various bug fixes
❌ - Performance optimizations
❌ - Updated dependencies
```

Fix: Name the observable behavior change.

```
✅ - CSV exports with emoji now open correctly in Excel on Windows
✅ - Dashboard loads 4x faster (avg render time: 4.2s → 1.1s)
```

### Too technical (implementation language)

```
❌ - Fixed race condition in async handler
❌ - Resolved null pointer exception on settings page
❌ - Refactored export module to use strategy pattern
❌ - Migrated background jobs from Sidekiq to Oban
```

Fix: Translate to observable symptoms.

```
✅ - Fixed: Spinner no longer freezes when switching projects quickly
✅ - Fixed: Settings page no longer crashes on first load
✅ - Background jobs now run faster and use less memory (no action needed)
```

### Too many (volume overwhelm)

```
❌ - Update eslint from 8.x to 9.x
❌ - Fix typo in README
❌ - Update jest from 29.6 to 29.7
❌ - Rename internal variable
❌ - Add .gitignore entry
... (40 more entries)
```

Fix: Exclude maintenance that doesn't affect distributed software. Keep only what a consumer would notice.

### Internal refactors masquerading as features

```
❌ - Refactor authentication module
❌ - Extract helper function for date parsing
❌ - Clean up unused imports
❌ - Rename internal class FooHandler to BarProcessor
```

Fix: Omit entirely unless there's an observable side effect.

### Naming files and internal components

```
❌ - Added resolve_extends function to generate.py
❌ - Fixed bug in line 47 of generate.py
❌ - Updated compositions/deprecated.yaml to include X
❌ - Steering companion files deploy to skills tree (ADR 0009)
```

Fix: Describe the user outcome, not the file.

```
✅ - Projects can now inherit base configurations with `extends:`
✅ - Fixed crash when project has no theme configured
✅ - Retired skills clean themselves up on redeploy
✅ - Always-on context reduced by ~90 lines per session
```

---

## When to Omit (Extended Guide)

**Always omit:**
- CI/CD pipeline changes (GitHub Actions, deployment scripts)
- Test additions with no behavior change
- Code formatting, linting fixes
- Dev-only dependency updates
- Internal renaming/refactoring (no behavior change)
- Documentation typo fixes
- .gitignore, .editorconfig, dotfile changes
- Comment additions/updates in code

**Include even though they seem internal:**
- Refactoring with observable side effects (faster, less memory, different error messages)
- New docs for previously undocumented features (that's a feature for users)
- Dev dependency updates that change build output (affects consumers)
- Runtime environment changes (new Node version requirement, etc.)

---

## Audience Quick Reference

| Project Type | Your Reader | Use This Language | Example |
|-------------|-------------|-------------------|---------|
| Library/SDK | Developers integrating your code | API surface: function names, types, method signatures | "Add `parse()` option to skip validation" |
| CLI tool | Developers running your commands | Commands, flags, output format | "New `--dry-run` flag shows what would change" |
| Application/SaaS | End users of the product | Features, screens, workflows | "You can now export reports as PDF" |
| Framework | Developers building on your platform | Extension points, config, lifecycle hooks | "Middleware can now return early without calling `next()`" |
| Internal tool | Your team | Observable behavior changes | "Deploys no longer delete skills from other sources" |

---

## Keep a Changelog vs Common Changelog

| Aspect | Keep a Changelog | Common Changelog |
|--------|-----------------|-----------------|
| Categories | 6: Added, Changed, Deprecated, Removed, Fixed, Security | 4: Added, Changed, Removed, Fixed |
| Unreleased section | Required | Explicitly rejected |
| References/links | Optional | Mandatory on every entry |
| Conventional Commits | Compatible | Explicitly called an anti-pattern |
| Attribution | Not specified | Encouraged |
| Audience | "Humans, not machines" | "Software consumers (upgraders)" |

Both agree: entries must be human-readable, curated, and focused on user impact.

---

## Depth Scaling Examples

### One-liner (trivial fix)

```
- Fixed tooltip flickering on hover
```

### 1-2 sentences (standard feature)

```
- Projects can now inherit base configurations with `extends:`. Child projects
  only need to declare what differs from the parent.
```

### Full paragraph (breaking change)

```
- **Breaking:** `deploy --force` no longer skips the confirmation prompt in CI.

  Previously, `--force` bypassed all safety checks including the "are you sure?"
  prompt. Now it only skips the dry-run preview. Use `--yes` to skip confirmation,
  or pipe `yes |` for unattended scripts.

  Migration: Replace `deploy --force` with `deploy --force --yes` in CI scripts.
```
