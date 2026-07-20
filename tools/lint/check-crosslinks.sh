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
tier_skills=$(yq -r '.skills[], .steering[], .extensions[]?.skills[]?, .extensions[]?.steering[]?' "$TIERS_DIR"/*.yaml 2>/dev/null | grep -v '^---$' | grep -v '^null$' | sort -u)

# Skills consumed by compositions (archetypes/crew-patterns) count as deployed too,
# and compositions/project-level.yaml documents per-project installables
comp_skills=$(yq -r '.skills[]?, .["shared-skills"][]?' "$ROOT_DIR"/compositions/agent-archetypes/*.yaml "$ROOT_DIR"/compositions/crew-patterns/*.yaml "$ROOT_DIR"/compositions/project-level.yaml 2>/dev/null | sort -u)

# Deprecated names (compositions/deprecated.yaml) must stay dead: not in
# atomics/skills/, not referenced by any tier or composition (resurrecting a
# retired name breaks the deploy prune's assumption that the name is stale)
if [[ -f "$ROOT_DIR/compositions/deprecated.yaml" ]]; then
  while IFS= read -r dep; do
    [[ -n "$dep" ]] || continue
    if [[ -d "$SKILLS_DIR/$dep" ]]; then
      echo "  ❌ deprecated name resurrected: atomics/skills/$dep/ exists but $dep is in compositions/deprecated.yaml"
      errors=$((errors + 1))
    fi
    if grep -qx "$dep" <<< "$tier_skills" || grep -qx "$dep" <<< "$comp_skills"; then
      echo "  ❌ deprecated name referenced: $dep appears in a tier/composition but is in compositions/deprecated.yaml"
      errors=$((errors + 1))
    fi
  done < <(yq -r '.skills[].name' "$ROOT_DIR/compositions/deprecated.yaml" 2>/dev/null)
fi

echo "Linting skills..."

# 0. Every tier steering/skill entry must resolve to atomics/skills/{slug}/SKILL.md
#    (catches the eager-context misplacement bug — 2 occurrences: research-dispatch-mandate, frontier-work)
for entry in $tier_skills; do
  if [[ ! -f "$SKILLS_DIR/$entry/SKILL.md" ]]; then
    echo "  ❌ tier references '$entry' but atomics/skills/$entry/SKILL.md does not exist (misplaced in eager-context/?)"
    errors=$((errors + 1))
  fi
done

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

# 5. Shell scripts must be executable (non-exec scripts invoked directly
# silently no-op behind '|| true' — the inspect-session.sh incident class).
# Uses git ls-files to read stored mode (filesystem perms are unreliable on
# Windows where core.filemode=false — all files appear 644 on disk).
while IFS= read -r script; do
  rel_path="${script#$ROOT_DIR/}"
  mode=$(git -C "$ROOT_DIR" ls-files -s "$rel_path" 2>/dev/null | awk '{print $1}')
  if [[ -z "$mode" ]]; then
    echo "  ❌ not tracked: $script (git add with executable bit)"
    errors=$((errors + 1))
  elif [[ "$mode" != "100755" ]]; then
    echo "  ❌ not executable (git mode $mode): $script (git update-index --chmod=+x and commit)"
    errors=$((errors + 1))
  fi
done < <(find "$ROOT_DIR/tools" -name "*.sh" 2>/dev/null)

echo ""
echo "Lint: $errors error(s), $warnings warning(s)"
[[ $errors -eq 0 ]] || exit 1
