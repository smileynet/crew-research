#!/usr/bin/env bash
set -euo pipefail

# release.sh — Cut a tagged release for crew-research
#
# Usage: mise run release -- <version> [--dry-run]
# Example: mise run release -- 0.3.0
#          mise run release -- 0.3.0 --dry-run
#
# Gates:
#   - Working tree clean
#   - Version is valid semver and > last tag
#   - mise run validate passes
#   - CHANGELOG.md has [Unreleased] entries
#
# Actions:
#   1. Move [Unreleased] entries → [version] section in CHANGELOG.md
#   2. Commit: "release: v<version>"
#   3. Tag: v<version>
#   4. Push commit + tag
#   5. Create GitHub release with extracted changelog notes

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CHANGELOG="$REPO_ROOT/CHANGELOG.md"

# --- Parse args ---

VERSION=""
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    -*) echo "Unknown flag: $arg" >&2; exit 1 ;;
    *) VERSION="$arg" ;;
  esac
done

if [[ -z "$VERSION" ]]; then
  echo "Usage: mise run release -- <version> [--dry-run]" >&2
  echo "Example: mise run release -- 0.3.0" >&2
  exit 1
fi

# Strip leading 'v' if provided
VERSION="${VERSION#v}"

# --- Validate semver format ---

if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "❌ Invalid semver: $VERSION (expected X.Y.Z)" >&2
  exit 1
fi

# --- Check version > last tag ---

LAST_TAG=$(git -C "$REPO_ROOT" tag -l 'v*' --sort=-v:refname | head -1)
if [[ -n "$LAST_TAG" ]]; then
  LAST_VERSION="${LAST_TAG#v}"
  # Compare versions using sort -V
  HIGHER=$(printf '%s\n%s\n' "$LAST_VERSION" "$VERSION" | sort -V | tail -1)
  if [[ "$HIGHER" == "$LAST_VERSION" ]]; then
    echo "❌ Version $VERSION is not greater than current $LAST_TAG" >&2
    exit 1
  fi
fi

# --- Gate: working tree clean ---

if [[ -n "$(git -C "$REPO_ROOT" status --porcelain -- ':!.scratch')" ]]; then
  echo "❌ Working tree not clean (ignoring .scratch/):" >&2
  git -C "$REPO_ROOT" status --short -- ':!.scratch' >&2
  exit 1
fi

# --- Gate: CHANGELOG.md has [Unreleased] content ---

if [[ ! -f "$CHANGELOG" ]]; then
  echo "❌ CHANGELOG.md not found at $CHANGELOG" >&2
  exit 1
fi

# Extract content between [Unreleased] and the next ## heading
UNRELEASED_CONTENT=$(sed -n '/^## \[Unreleased\]/,/^## \[/{/^## \[/!p}' "$CHANGELOG" | grep -v '^$' || true)

if [[ -z "$UNRELEASED_CONTENT" ]]; then
  echo "❌ No entries under [Unreleased] in CHANGELOG.md" >&2
  exit 1
fi

# --- Gate: mise run validate ---

echo "Running validation..."
if ! mise run validate > /dev/null 2>&1; then
  echo "❌ mise run validate failed" >&2
  mise run validate >&2
  exit 1
fi
echo "✅ Validation passed"

# --- Prepare release ---

TODAY=$(date +%Y-%m-%d)
TAG="v$VERSION"

echo ""
echo "Release: $TAG ($TODAY)"
echo "Previous: ${LAST_TAG:-none}"
echo ""
echo "Changelog entries:"
echo "$UNRELEASED_CONTENT" | head -20
if [[ $(echo "$UNRELEASED_CONTENT" | wc -l) -gt 20 ]]; then
  echo "  ... ($(echo "$UNRELEASED_CONTENT" | wc -l) lines total)"
fi
echo ""

if [[ "$DRY_RUN" == true ]]; then
  echo "🏁 DRY RUN — would:"
  echo "  1. Move [Unreleased] → [$VERSION] - $TODAY in CHANGELOG.md"
  echo "  2. git commit -m 'release: $TAG'"
  echo "  3. git tag $TAG"
  echo "  4. git push origin main --tags"
  echo "  5. gh release create $TAG --title '$TAG' --notes-file <extracted>"
  exit 0
fi

# --- Execute release ---

# 1. Move [Unreleased] → [version] in CHANGELOG.md
sed -i "s/^## \[Unreleased\]/## [Unreleased]\n\n## [$VERSION] - $TODAY/" "$CHANGELOG"

# Remove duplicate blank lines that may result
sed -i '/^$/N;/^\n$/d' "$CHANGELOG"

# 2. Commit
git -C "$REPO_ROOT" add "$CHANGELOG"
git -C "$REPO_ROOT" commit -m "release: $TAG"

# 3. Tag
git -C "$REPO_ROOT" tag -a "$TAG" -m "Release $TAG"

# 4. Push
git -C "$REPO_ROOT" push origin main --tags

# 5. Create GitHub release
# Extract the version's changelog section for release notes
NOTES_FILE=$(mktemp)
sed -n "/^## \[$VERSION\]/,/^## \[/{/^## \[$VERSION\]/d;/^## \[/d;p}" "$CHANGELOG" > "$NOTES_FILE"

gh release create "$TAG" \
  --title "$TAG" \
  --notes-file "$NOTES_FILE" \
  --repo "$(git -C "$REPO_ROOT" remote get-url origin | sed 's/\.git$//')"

rm -f "$NOTES_FILE"

echo ""
echo "✅ Released $TAG"
echo "   View: gh release view $TAG"
