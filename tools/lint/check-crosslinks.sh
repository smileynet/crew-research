#!/bin/bash
# tools/lint/check-crosslinks.sh — Verify practice↔skill cross-references
# Usage: ./check-crosslinks.sh [--strict]
# Exit 0: all links valid. Exit 1: broken links found.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
PRACTICES_DIR="$ROOT_DIR/docs/practices"
SKILLS_DIR="$ROOT_DIR/atomics/skills"

STRICT=false
[[ "${1:-}" == "--strict" ]] && STRICT=true

errors=0
warnings=0

echo "Cross-link lint"
echo ""

# 1. Check practice → skill references
echo "Practices → Skills:"
for f in "$PRACTICES_DIR"/*.md; do
  [[ -f "$f" ]] || continue
  # Extract skills: [...] from frontmatter
  skills=$(awk '/^---$/{n++; next} n==1 && /^skills:/{gsub(/^skills: *\[|\].*/, ""); gsub(/,/, " "); print}' "$f")
  for s in $skills; do
    s=$(echo "$s" | tr -d ' ')
    [[ -z "$s" ]] && continue
    if [[ -d "$SKILLS_DIR/$s" ]]; then
      echo "  ✅ $(basename "$f") → $s"
    else
      echo "  ❌ $(basename "$f") → $s (skill not found)"
      errors=$((errors + 1))
    fi
  done
done

echo ""

# 2. Check skill → practice references
echo "Skills → Practices:"
for f in "$SKILLS_DIR"/*/SKILL.md; do
  [[ -f "$f" ]] || continue
  slug=$(basename "$(dirname "$f")")
  practice=$(awk '/^---$/{n++; next} n==1 && /practice:/{sub(/.*practice: */, ""); sub(/ *$/, ""); print}' "$f" | head -1)
  [[ -z "$practice" || "$practice" == "null" ]] && continue
  if [[ -f "$PRACTICES_DIR/$practice.md" ]]; then
    echo "  ✅ $slug → $practice"
  else
    echo "  ❌ $slug → $practice (practice not found)"
    errors=$((errors + 1))
  fi
done

echo ""

# 3. Staleness check (advisory)
echo "Staleness:"
for f in "$SKILLS_DIR"/*/SKILL.md; do
  [[ -f "$f" ]] || continue
  slug=$(basename "$(dirname "$f")")
  practice=$(awk '/^---$/{n++; next} n==1 && /practice:/{sub(/.*practice: */, ""); sub(/ *$/, ""); print}' "$f" | head -1)
  [[ -z "$practice" || "$practice" == "null" ]] && continue
  practice_file="$PRACTICES_DIR/$practice.md"
  [[ -f "$practice_file" ]] || continue
  if [[ "$practice_file" -nt "$f" ]]; then
    echo "  ⚠️  $practice.md is newer than $slug/SKILL.md (skill may be stale)"
    warnings=$((warnings + 1))
  fi
done

echo ""
echo "---"
echo "Errors: $errors | Warnings: $warnings"

if [[ $errors -gt 0 ]]; then
  exit 1
elif [[ "$STRICT" == true && $warnings -gt 0 ]]; then
  exit 1
fi
exit 0
