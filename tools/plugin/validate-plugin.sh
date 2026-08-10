#!/usr/bin/env bash
# validate-plugin.sh — Validate a tool repo's Agent Plugins + SKILL_MANIFEST compliance
#
# Usage: bash tools/plugin/validate-plugin.sh <tool-repo-path>
# Exit: 0 = pass, 1 = validation failures, 2 = missing prerequisites
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCHEMA="$SCRIPT_DIR/schemas/skill-manifest.schema.yaml"
REPO="${1:-.}"
REPO="$(cd "$REPO" && pwd)"

ERRORS=()
WARNINGS=()

err()  { ERRORS+=("$1"); }
warn() { WARNINGS+=("$1"); }

# --- Prerequisites ---
if ! command -v yq &>/dev/null; then
  echo "ERROR: yq required but not found" >&2; exit 2
fi

# --- SKILL_MANIFEST.yaml ---
MANIFEST="$REPO/SKILL_MANIFEST.yaml"
if [[ ! -f "$MANIFEST" ]]; then
  err "SKILL_MANIFEST.yaml not found at repo root"
else
  # Required fields
  for field in name version; do
    val=$(yq ".$field // \"\"" "$MANIFEST")
    [[ -n "$val" && "$val" != "null" ]] || err "SKILL_MANIFEST.yaml: missing required field '$field'"
  done

  # Name format
  name=$(yq '.name // ""' "$MANIFEST")
  if [[ -n "$name" && "$name" != "null" ]]; then
    if ! [[ "$name" =~ ^[a-z][a-z0-9-]*$ ]]; then
      err "SKILL_MANIFEST.yaml: name '$name' must be lowercase alphanumeric + hyphens, start with letter"
    fi
  fi

  # Version format
  version=$(yq '.version // ""' "$MANIFEST")
  if [[ -n "$version" && "$version" != "null" ]]; then
    if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
      err "SKILL_MANIFEST.yaml: version '$version' must be SemVer (x.y.z)"
    fi
  fi

  # Skills array
  skill_count=$(yq '.skills | length' "$MANIFEST" 2>/dev/null || echo 0)
  if [[ "$skill_count" -eq 0 ]]; then
    err "SKILL_MANIFEST.yaml: 'skills' array is empty or missing"
  fi

  # Deploy section
  method=$(yq '.deploy.method // ""' "$MANIFEST")
  if [[ -n "$method" && "$method" != "null" ]]; then
    if [[ "$method" != "symlink" && "$method" != "copy" ]]; then
      err "SKILL_MANIFEST.yaml: deploy.method must be 'symlink' or 'copy', got '$method'"
    fi
  fi

  script=$(yq '.deploy.script // ""' "$MANIFEST")
  if [[ -n "$script" && "$script" != "null" ]]; then
    if [[ ! -f "$REPO/$script" ]]; then
      warn "SKILL_MANIFEST.yaml: deploy.script '$script' does not exist yet"
    fi
  fi

  # Binary check (if declared)
  binary_name=$(yq '.binary.name // ""' "$MANIFEST")
  if [[ -n "$binary_name" && "$binary_name" != "null" ]]; then
    version_cmd=$(yq '.binary.version_cmd // ""' "$MANIFEST")
    min_version=$(yq '.binary.min_version // ""' "$MANIFEST")
    [[ -n "$version_cmd" ]] || err "SKILL_MANIFEST.yaml: binary.version_cmd required when binary declared"
    [[ -n "$min_version" ]] || err "SKILL_MANIFEST.yaml: binary.min_version required when binary declared"
  fi
fi

# --- plugin.json (Agent Plugins 1.0) ---
PLUGIN_JSON="$REPO/plugin.json"
if [[ ! -f "$PLUGIN_JSON" ]]; then
  warn "plugin.json not found (optional but recommended for Agent Plugins ecosystem discovery)"
else
  # Check required fields
  if ! command -v jq &>/dev/null; then
    warn "jq not available — skipping plugin.json validation"
  else
    schema_field=$(jq -r '."$schema" // ""' "$PLUGIN_JSON")
    if [[ "$schema_field" != *"agent-plugins.org"* ]]; then
      err "plugin.json: \$schema must reference agent-plugins.org schema"
    fi

    pj_name=$(jq -r '.name // ""' "$PLUGIN_JSON")
    if [[ -z "$pj_name" ]]; then
      err "plugin.json: 'name' field required"
    elif ! [[ "$pj_name" =~ ^[a-z][a-z0-9.-]*$ ]]; then
      err "plugin.json: name '$pj_name' must be lowercase alphanumeric + hyphens + periods"
    fi
  fi
fi

# --- Skills directory ---
SKILLS_DIR="$REPO/skills"
if [[ ! -d "$SKILLS_DIR" ]]; then
  # Check non-standard locations
  if [[ -d "$REPO/.spellbook/skills" ]]; then
    warn "Skills at .spellbook/skills/ (non-standard — Agent Plugins expects skills/ at root)"
    SKILLS_DIR="$REPO/.spellbook/skills"
  else
    err "skills/ directory not found at repo root"
  fi
fi

if [[ -d "$SKILLS_DIR" ]]; then
  skill_dirs_found=0
  for skill_dir in "$SKILLS_DIR"/*/; do
    [[ -d "$skill_dir" ]] || continue
    slug=$(basename "$skill_dir")
    skill_dirs_found=$((skill_dirs_found + 1))

    # Naming rules
    if ! [[ "$slug" =~ ^[a-z][a-z0-9-]*$ ]]; then
      err "skills/$slug: directory name must be lowercase alphanumeric + hyphens"
    fi
    if [[ "$slug" == *--* ]]; then
      err "skills/$slug: consecutive hyphens not allowed"
    fi

    # SKILL.md exists
    if [[ ! -f "$skill_dir/SKILL.md" ]]; then
      err "skills/$slug: SKILL.md not found"
      continue
    fi

    # Frontmatter check (name + description required)
    if head -1 "$skill_dir/SKILL.md" | grep -q "^---"; then
      fm_name=$(sed -n '/^---$/,/^---$/p' "$skill_dir/SKILL.md" | grep "^name:" | head -1 | sed 's/^name: *//' | tr -d '"')
      fm_desc=$(sed -n '/^---$/,/^---$/p' "$skill_dir/SKILL.md" | grep "^description:" | head -1)
      [[ -n "$fm_name" ]] || err "skills/$slug/SKILL.md: frontmatter missing 'name' field"
      [[ -n "$fm_desc" ]] || err "skills/$slug/SKILL.md: frontmatter missing 'description' field"
    else
      err "skills/$slug/SKILL.md: no YAML frontmatter (must start with ---)"
    fi

    # Path containment (references don't escape skill root)
    if [[ -d "$skill_dir/references" ]]; then
      while IFS= read -r ref_file; do
        real_path=$(realpath "$ref_file" 2>/dev/null || true)
        if [[ -n "$real_path" && "$real_path" != "$REPO"* ]]; then
          err "skills/$slug: reference escapes repo root: $ref_file → $real_path"
        fi
      done < <(find "$skill_dir/references" -type l 2>/dev/null)
    fi
  done

  if [[ $skill_dirs_found -eq 0 ]]; then
    err "skills/ directory exists but contains no skill subdirectories"
  fi
fi

# --- Report ---
echo ""
echo "Plugin Validation: $(basename "$REPO")"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ ${#ERRORS[@]} -eq 0 && ${#WARNINGS[@]} -eq 0 ]]; then
  echo "  ✅ All checks passed"
  echo ""
  exit 0
fi

if [[ ${#ERRORS[@]} -gt 0 ]]; then
  echo "  Errors (${#ERRORS[@]}):"
  for e in "${ERRORS[@]}"; do
    echo "    ❌ $e"
  done
fi

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
  echo "  Warnings (${#WARNINGS[@]}):"
  for w in "${WARNINGS[@]}"; do
    echo "    ⚠️  $w"
  done
fi

echo ""
if [[ ${#ERRORS[@]} -gt 0 ]]; then
  exit 1
else
  exit 0
fi
