#!/bin/bash
# tools/generator/catalog.sh — List available skills with descriptions
# Usage: ./catalog.sh [--tier basic|full] [--category plan|build|verify|...]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILLS_DIR="$ROOT_DIR/atomics/skills"
TIERS_DIR="$ROOT_DIR/compositions/tiers"

TIER="${1:-}"
[[ "$TIER" == "--tier" ]] && TIER="${2:-}"

echo "Available Skills"
echo "================"
echo ""

for dir in "$SKILLS_DIR"/*/; do
  [[ -f "$dir/SKILL.md" ]] || continue
  name=$(basename "$dir")
  # Extract description (handles both single-line and multi-line YAML)
  desc=$(awk '/^description:/{gsub(/^description: *"?|"$/,""); if(/^>/) {getline; gsub(/^ +/,"")}; print; exit}' "$dir/SKILL.md" | head -c 70)

  # Check tier membership
  tag=""
  if yq -r '.steering[]' "$TIERS_DIR/basic.yaml" 2>/dev/null | grep -qx "$name"; then
    tag="[basic/steering]"
  elif yq -r '.skills[]' "$TIERS_DIR/basic.yaml" 2>/dev/null | grep -qx "$name"; then
    tag="[basic]"
  elif yq -r '.prompts[]' "$TIERS_DIR/basic.yaml" 2>/dev/null | grep -qx "$name"; then
    tag="[basic/prompt]"
  fi

  printf "  %-28s %-16s %s\n" "$name" "$tag" "$desc"
done

echo ""
echo "---"
echo "Basic tier: $(yq -r '.skills | length' "$TIERS_DIR/basic.yaml") skills + $(yq -r '.steering | length' "$TIERS_DIR/basic.yaml") steering + $(yq -r '.prompts | length' "$TIERS_DIR/basic.yaml") prompts"
echo "Full tier:  $(yq -r '.skills | length' "$TIERS_DIR/full.yaml") skills + $(yq -r '.steering | length' "$TIERS_DIR/full.yaml") steering + $(yq -r '.prompts | length' "$TIERS_DIR/full.yaml") prompts + $(yq -r '.agents | length' "$TIERS_DIR/full.yaml") agents"
