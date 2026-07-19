#!/bin/bash
# tools/generator/catalog.sh — List available skills with descriptions
# Usage: ./catalog.sh [--tier basic|full]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILLS_DIR="$ROOT_DIR/atomics/skills"
TIERS_DIR="$ROOT_DIR/compositions/tiers"

TIER=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --tier) TIER="${2:-}"; shift 2 ;;
    *) shift ;;
  esac
done
if [[ -n "$TIER" && ! -f "$TIERS_DIR/$TIER.yaml" ]]; then
  echo "Unknown tier: $TIER (available: $(ls "$TIERS_DIR" | sed 's/.yaml//' | tr '\n' ' '))" >&2
  exit 2
fi

# Precompute membership lists (steering + skills + extension skills per tier)
basic_all=$( { yq -r '.steering[], .skills[]' "$TIERS_DIR/basic.yaml"; yq -r '.extensions[].steering[], .extensions[].skills[]' "$TIERS_DIR/basic.yaml" 2>/dev/null; } 2>/dev/null | grep -v '^null$' || true)
full_all=$( { yq -r '.steering[], .skills[]' "$TIERS_DIR/full.yaml"; yq -r '.extensions[].steering[], .extensions[].skills[]' "$TIERS_DIR/full.yaml" 2>/dev/null; } 2>/dev/null | grep -v '^null$' || true)
ext_all=$(yq -r '.extensions[] | .name as $n | (.steering[], .skills[]) | . + " " + $n' "$TIERS_DIR/full.yaml" 2>/dev/null | grep -v '^null' || true)

echo "Available Skills"
echo "================"
echo ""

for dir in "$SKILLS_DIR"/*/; do
  [[ -f "$dir/SKILL.md" ]] || continue
  name=$(basename "$dir")
  desc=$(awk '/^description:/{gsub(/^description: *"?|"$/,""); if(/^>/) {getline; gsub(/^ +/,"")}; print; exit}' "$dir/SKILL.md" | head -c 70)

  # Membership tags
  tag=""
  in_basic=false; in_full=false
  grep -qx "$name" <<< "$basic_all" && in_basic=true
  grep -qx "$name" <<< "$full_all" && in_full=true
  ext_name=$(awk -v n="$name" '$1==n {print $2; exit}' <<< "$ext_all")

  if [[ -n "$ext_name" ]]; then
    tag="[ext:$ext_name]"
  elif $in_basic; then
    tag="[basic]"
  elif $in_full; then
    tag="[full]"
  else
    tag="[project-level]"
  fi

  # --tier filter: show only that tier's members (extensions included)
  if [[ -n "$TIER" ]]; then
    case "$TIER" in
      basic) $in_basic || [[ -n "$ext_name" ]] || continue ;;
      full)  $in_full  || [[ -n "$ext_name" ]] || continue ;;
    esac
  fi

  printf "  %-28s %-16s %s\n" "$name" "$tag" "$desc"
done

echo ""
echo "---"
for t in basic full; do
  n_steering=$(yq -r '.steering | length' "$TIERS_DIR/$t.yaml")
  n_skills=$(yq -r '.skills | length' "$TIERS_DIR/$t.yaml")
  n_ext=$(yq -r '.extensions | length' "$TIERS_DIR/$t.yaml" 2>/dev/null || echo 0)
  echo "$t tier: $n_skills skills + $n_steering steering + $n_ext extension(s)"
done
echo "[project-level] skills install per-project: mise run add-skill -- <name>"

# Known external tools (separately owned, self-deploying — see compositions/known-tools.yaml)
KNOWN_TOOLS_FILE="$ROOT_DIR/compositions/known-tools.yaml"
if [[ -f "$KNOWN_TOOLS_FILE" ]]; then
  echo ""
  echo "Known Tools (external, self-deploying)"
  echo "======================================"
  kt_count=$(yq -r '.tools | length' "$KNOWN_TOOLS_FILE" 2>/dev/null || echo 0)
  for ((i=0; i<kt_count; i++)); do
    kt_name=$(yq -r ".tools[$i].name" "$KNOWN_TOOLS_FILE")
    kt_desc=$(yq -r ".tools[$i].description" "$KNOWN_TOOLS_FILE")
    kt_glob=$(yq -r ".tools[$i].detect.skill_glob" "$KNOWN_TOOLS_FILE")
    kt_hydrate=$(yq -r ".tools[$i].hydrate" "$KNOWN_TOOLS_FILE")
    status="not hydrated — $kt_hydrate"
    for d in ~/.kiro/skills/$kt_glob; do
      [[ -e "$d" ]] && { status="hydrated"; break; }
    done
    printf "  %-28s [%s]\n    %s\n" "$kt_name" "$status" "$kt_desc"
  done
fi
