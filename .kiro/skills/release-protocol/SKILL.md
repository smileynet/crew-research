---
name: release-protocol
description: "Cut tagged releases for crew-research. Use when releasing, bumping version, tagging, shipping, or writing changelog entries. Trigger: release, tag, version bump, ship, publish, cut a release, changelog."
metadata:
  type: protocol
  invocation: user-only
---

# Release Protocol

## When to Release

Release when CHANGELOG.md `[Unreleased]` has meaningful user-facing changes AND `mise run validate` passes. Don't release for internal-only changes (eval tweaks, test infra, scratch files).

## SemVer Decision

| Change type | Bump |
|-------------|------|
| Remove/rename a skill, command, or deployment path | Major |
| New skill, extension, tool target, or workflow | Minor |
| Bug fix, doc improvement, eval calibration | Patch |

## Process

1. Ensure `[Unreleased]` in CHANGELOG.md has entries (write them if not)
2. Dry-run: `mise run release -- <version> --dry-run`
3. Cut: `mise run release -- <version>`
4. Verify: `gh release view v<version>`

## Writing Changelog Entries

Follow changelog-discipline:
- **Technology-replacement test:** would the entry still be true if you swapped internals?
- **Impact over mechanism:** state what changed for the user, not how the code does it
- **One entry per logical change** — group related commits
- Categories: Added / Changed / Fixed / Removed

## Gates (enforced by release.sh)

- Working tree must be clean (excluding `.scratch/`)
- Version must be valid semver and > current latest tag
- `[Unreleased]` must have at least one entry
- `mise run validate` must pass

## Manual Release (if script unavailable)

1. Edit CHANGELOG.md: move `[Unreleased]` content → `[X.Y.Z] - YYYY-MM-DD`
2. `git add CHANGELOG.md && git commit -m "release: vX.Y.Z"`
3. `git tag -a vX.Y.Z -m "Release vX.Y.Z"`
4. `git push origin main --tags`
5. `gh release create vX.Y.Z --title "vX.Y.Z" --notes-file <extracted>`

## Rollback

Fix forward with a patch release. Never delete a pushed tag.
