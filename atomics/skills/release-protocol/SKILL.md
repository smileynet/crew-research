---
name: release-protocol
description: "Cut tagged releases safely with SemVer, changelog roll, and validation gates. Use when releasing, bumping version, tagging, shipping, or deciding what version to use. Trigger: release, tag, version bump, ship, publish, cut a release, what version."
metadata:
  type: protocol
  invocation: both
  practice: null
---

# Release Protocol

## When to Release

Release when `[Unreleased]` in CHANGELOG.md has meaningful **user-facing** changes AND project validation passes. Don't release for internal-only changes (CI config, test infra, doc typos, scratch files).

## SemVer Decision

| Change type | Bump |
|-------------|------|
| Remove/rename public API, command, or deployment path | Major |
| New feature, capability, or supported platform | Minor |
| Bug fix, doc improvement, performance improvement | Patch |

**Edge cases:** Breaking a documented behavior = Major even if "nobody uses it." Adding a feature with a required config change = Minor (note migration in changelog).

## Process

1. **Check readiness** — changelog has entries, tests/validation pass, working tree clean
2. **Dry-run** — preview what would change (if tooling supports it)
3. **Cut** — roll changelog from `[Unreleased]` → `[X.Y.Z] - YYYY-MM-DD`, commit, tag
4. **Push** — push commit + tag together
5. **Verify** — confirm release artifact exists (GH release, package registry, etc.)

## Gates (hard blocks — do not skip)

- Working tree must be clean
- Version must be valid SemVer and greater than current latest tag
- `[Unreleased]` must have at least one entry
- Project validation must pass (build, test, lint — whatever the project defines)

If any gate fails, abort with no changes made.

## Manual Release (when no script exists)

```bash
# 1. Edit CHANGELOG.md: [Unreleased] → [X.Y.Z] - YYYY-MM-DD, add new empty [Unreleased]
# 2. Commit
git add CHANGELOG.md
git commit -m "release: vX.Y.Z"
# 3. Tag
git tag -a vX.Y.Z -m "Release vX.Y.Z"
# 4. Push
git push origin main --tags
# 5. Create release (if using GitHub)
gh release create vX.Y.Z --title "vX.Y.Z" --notes-file <(sed -n '/## \[X.Y.Z\]/,/## \[/p' CHANGELOG.md | head -n -1)
```

## Rollback Policy

Fix forward with a patch release. Never delete a pushed tag. If a fix takes time, add a "Known Issues" note to the release.

## Changelog Entry Quality

Defer to `changelog-discipline` skill for entry writing rules. Key test: would the entry still be true if you replaced the underlying technology?

## What NOT to Release

- Internal tooling changes with no user-visible effect
- Test additions without behavior changes
- Incomplete features (partially working = don't ship)
- Changes only affecting the development workflow
