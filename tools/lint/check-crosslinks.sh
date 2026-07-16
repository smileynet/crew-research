#!/bin/bash
# tools/lint/check-crosslinks.sh — Validate skill structure integrity
# Checks (updated 2026-07-16, replacing dead docs/practices cross-link check):
#   1. Every atomics/skills/*/SKILL.md has YAML frontmatter with name + description
#   2. frontmatter name matches directory slug
#   3. Every skill is in >=1 tier OR listed as project-level (warn only)
#   4. references/ files are linked from SKILL.md body (orphan warning)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILLS_DIR="$ROOT_DIR/atomics/skills"
TIERS_DIR="$ROOT_DIR/compositions/tiers"

errors=0
warnings=0

# Collect all skills referenced by tiers (skills + steering + extensions)
tier_skills=$(yq -r '.skills[], .steering[], .extensions[]?.skills[]?, .extensions[]?.steering[]?' "$TIERS_DIR"/*.yaml 2>/dev/null | sort -u)

# Skills consumed by compositions (archetypes/crew-patterns) count as deployed too
comp_skills=$(yq -r '.skills[]?, .["shared-skills"][]?' "$ROOT_DIR"/compositions/agent-archetypes/*.yaml "$ROOT_DIR"/compositions/crew-patterns/*.yaml 2>/dev/null | sort -u)

echo "Linting skills..."

for dir in "$SKILLS_DIR"/*/; do
  slug=$(basename "$dir")
  skill_md="$dir/SKILL.md"

  if [[ ! -f "$skill_md" ]]; then
    echo "  ❌ $slug: no SKILL.md"
    errors=$((errors + 1))
    continue
  fi

  # 1. Frontmatter exists (file starts with ---)
  if [[ "$(head -1 "$skill_md")" != "---" ]]; then
    echo "  ❌ $slug: missing YAML frontmatter"
    errors=$((errors + 1))
    continue
  fi

  fm=$(awk 'BEGIN{s=0} /^---$/{s++; if(s==2) exit; next} s==1{print}' "$skill_md")

  # 2. Required fields
  fm_name=$(echo "$fm" | yq -r '.name // ""' 2>/dev/null)
  fm_desc=$(echo "$fm" | yq -r '.description // ""' 2>/dev/null)
  if [[ -z "$fm_name" ]]; then
    echo "  ❌ $slug: frontmatter missing 'name'"
    errors=$((errors + 1))
  elif [[ "$fm_name" != "$slug" ]]; then
    echo "  ❌ $slug: frontmatter name '$fm_name' != directory slug"
    errors=$((errors + 1))
  fi
  if [[ -z "$fm_desc" || "$fm_desc" == "null" ]]; then
    echo "  ❌ $slug: frontmatter missing 'description'"
    errors=$((errors + 1))
  fi

  # 3. Tier/composition membership (warn only — project-level skills are legitimate)
  if ! grep -qx "$slug" <<< "$tier_skills" && ! grep -qx "$slug" <<< "$comp_skills"; then
    echo "  ⚠️  $slug: in no tier or composition (project-level skill? document it)"
    warnings=$((warnings + 1))
  fi

  # 4. Orphaned references
  if [[ -d "$dir/references" ]]; then
    for ref in "$dir/references"/*; do
      [[ -f "$ref" ]] || continue
      ref_name=$(basename "$ref")
      if ! grep -q "$ref_name" "$skill_md"; then
        echo "  ⚠️  $slug: references/$ref_name not linked from SKILL.md body"
        warnings=$((warnings + 1))
      fi
    done
  fi
done

echo ""
echo "Lint: $errors error(s), $warnings warning(s)"
[[ $errors -eq 0 ]] || exit 1
