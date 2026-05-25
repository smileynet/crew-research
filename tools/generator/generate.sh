#!/bin/bash
# tools/generator/generate.sh — Compose modules into tool-specific deployments
# Usage: ./generate.sh [validate|generate] [--tool kiro-cli|claude-code|all] [--output ./deploy]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
ATOMICS_DIR="$ROOT_DIR/atomics"
COMPOSITIONS_DIR="$ROOT_DIR/compositions"
ADAPTERS_DIR="$ROOT_DIR/tools/proofs/adapters"

COMMAND="${1:-validate}"
shift || true

TOOL="all"
OUTPUT="$ROOT_DIR/deploy"
PROJECT=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --tool) TOOL="$2"; shift 2 ;;
    --output) OUTPUT="$2"; shift 2 ;;
    --project) PROJECT="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

# Load project overlay if specified
PROJECT_CONFIG=""
PROJECT_CREWS=""
if [[ -n "$PROJECT" ]]; then
  PROJECT_CONFIG="$PROJECT/.crew-config.yaml"
  if [[ -f "$PROJECT_CONFIG" ]]; then
    PROJECT_CREWS=$(yq '.crews[]?' "$PROJECT_CONFIG" 2>/dev/null | tr '\n' ' ')
    echo "Project: $(yq '.project' "$PROJECT_CONFIG") ($(echo $PROJECT_CREWS | wc -w) crews)"
  else
    echo "Warning: --project specified but no .crew-config.yaml found" >&2
  fi
fi

# --- Validation ---

validate() {
  local errors=0

  echo "Validating compositions..."

  # Check all YAML is well-formed
  for f in "$COMPOSITIONS_DIR"/**/*.yaml; do
    [[ -f "$f" ]] || continue
    if ! yq '.' "$f" > /dev/null 2>&1; then
      echo "  ❌ Invalid YAML: $f"; errors=$((errors + 1))
    fi
  done

  # Check skill references
  for f in "$COMPOSITIONS_DIR"/agent-archetypes/*.yaml "$COMPOSITIONS_DIR"/crew-patterns/*.yaml; do
    [[ -f "$f" ]] || continue
    local skills=$(yq '.skills[]? // .["shared-skills"][]?' "$f" 2>/dev/null)
    for s in $skills; do
      if [[ ! -d "$ATOMICS_DIR/skills/$s" ]]; then
        echo "  ❌ Skill not found: $s (in $(basename "$f"))"; errors=$((errors + 1))
      fi
    done
  done

  # Check agent references in crew patterns
  for f in "$COMPOSITIONS_DIR"/crew-patterns/*.yaml; do
    [[ -f "$f" ]] || continue
    local agents=$(yq '.agents.lead, .agents.workers[]?' "$f" 2>/dev/null)
    for a in $agents; do
      if [[ ! -f "$COMPOSITIONS_DIR/agent-archetypes/$a.yaml" ]]; then
        echo "  ❌ Agent archetype not found: $a (in $(basename "$f"))"; errors=$((errors + 1))
      fi
    done
  done

  if [[ $errors -eq 0 ]]; then
    echo "  ✅ All references resolve ($( ls "$COMPOSITIONS_DIR"/**/*.yaml 2>/dev/null | wc -l) files)"
  fi
  return $errors
}

# --- Generation ---

# Get extra skills for an archetype from project config
get_extra_skills() {
  local archetype_name="$1"
  if [[ -n "$PROJECT_CONFIG" && -f "$PROJECT_CONFIG" ]]; then
    yq ".extend.$archetype_name.skills[]?" "$PROJECT_CONFIG" 2>/dev/null
  fi
}

# Get param value for a skill from project config
get_param() {
  local skill_name="$1" param_name="$2"
  if [[ -n "$PROJECT_CONFIG" && -f "$PROJECT_CONFIG" ]]; then
    yq ".params.\"$skill_name\".$param_name // \"\"" "$PROJECT_CONFIG" 2>/dev/null
  fi
}

generate_agent_kiro() {
  local archetype_file="$1" output_dir="$2"
  local name=$(yq '.name' "$archetype_file")
  local desc=$(yq '.description' "$archetype_file")
  local prompt=$(yq '.prompt' "$archetype_file")
  local tools=$(yq -o=json '.tools' "$archetype_file")

  # Build resources array: skills as skill:// URIs
  local resources="[]"
  local skills=$(yq '.skills[]?' "$archetype_file" 2>/dev/null)
  # Add extra skills from project overlay
  local extra_skills=$(get_extra_skills "$name")
  local all_skills="$skills $extra_skills"

  for s in $all_skills; do
    [[ -z "$s" ]] && continue
    resources=$(echo "$resources" | yq -o=json ". + [\"skill://.kiro/skills/$s/SKILL.md\"]")
  done

  # Add eager-context as file:// URIs
  local eager=$(yq '.["eager-context"][]?' "$archetype_file" 2>/dev/null)
  for e in $eager; do
    resources=$(echo "$resources" | yq -o=json ". + [\"file://.kiro/steering/universal/$e.md\"]")
  done

  # Add project-level eager-context
  if [[ -n "$PROJECT_CONFIG" && -f "$PROJECT_CONFIG" ]]; then
    for e in $(yq '.["eager-context"][]?' "$PROJECT_CONFIG" 2>/dev/null); do
      resources=$(echo "$resources" | yq -o=json ". + [\"file://.kiro/steering/universal/$e.md\"]")
    done
  fi

  mkdir -p "$output_dir/.kiro/agents"
  cat > "$output_dir/.kiro/agents/$name.json" << EOF
{
  "name": "$name",
  "description": "$desc",
  "tools": $tools,
  "allowedTools": $tools,
  "resources": $resources,
  "prompt": $(echo "$prompt" | jq -Rs .)
}
EOF
}

generate_agent_claude() {
  local archetype_file="$1" output_dir="$2"
  local name=$(yq '.name' "$archetype_file")
  local desc=$(yq '.description' "$archetype_file")
  local prompt=$(yq '.prompt' "$archetype_file")
  local tools=$(yq -r '.tools | join(", ")' "$archetype_file")

  # Build skills list (base + overlay extras)
  local skills_field=""
  local skills=$(yq '.skills[]?' "$archetype_file" 2>/dev/null)
  local extra_skills=$(get_extra_skills "$name")
  local all_skills="$skills $extra_skills"
  all_skills=$(echo "$all_skills" | tr ' ' '\n' | grep -v '^$' | sort -u)
  if [[ -n "$all_skills" ]]; then
    skills_field="skills:"
    for s in $all_skills; do
      skills_field="$skills_field
  - $s"
    done
  fi

  mkdir -p "$output_dir/.claude/agents"
  cat > "$output_dir/.claude/agents/$name.md" << EOF
---
name: $name
description: $desc
tools: $tools
${skills_field}
---

$prompt
EOF
}

deploy_skills() {
  local tool="$1" output_dir="$2"

  # Collect all referenced skills from archetypes + crews
  local all_skills=$(for f in "$COMPOSITIONS_DIR"/agent-archetypes/*.yaml "$COMPOSITIONS_DIR"/crew-patterns/*.yaml; do
    [[ -f "$f" ]] || continue
    yq '.skills[]? // .["shared-skills"][]?' "$f" 2>/dev/null
  done | sort -u)

  # Also include all user-only skills (prompts available to all users)
  for f in "$ATOMICS_DIR"/skills/*/SKILL.md; do
    [[ -f "$f" ]] || continue
    local inv=$(awk '/^---$/{n++; next} n==1{print} n==2{exit}' "$f" | yq '.metadata.invocation // "both"' 2>/dev/null)
    if [[ "$inv" == "user-only" ]]; then
      local sname=$(basename "$(dirname "$f")")
      all_skills="$all_skills $sname"
    fi
  done
  all_skills=$(echo "$all_skills" | tr ' ' '\n' | sort -u | grep -v '^$')

  for s in $all_skills; do
    local src="$ATOMICS_DIR/skills/$s/SKILL.md"
    [[ -f "$src" ]] || continue

    local dest=""
    if [[ "$tool" == "kiro-cli" ]]; then
      mkdir -p "$output_dir/.kiro/skills/$s"
      dest="$output_dir/.kiro/skills/$s/SKILL.md"
      cp "$src" "$dest"
    elif [[ "$tool" == "claude-code" ]]; then
      mkdir -p "$output_dir/.claude/skills/$s"
      dest="$output_dir/.claude/skills/$s/SKILL.md"
      cp "$src" "$dest"
    fi

    # Param substitution: replace {{params.X}} with values from project config or skill defaults
    if [[ -n "$dest" && -f "$dest" ]]; then
      # Extract frontmatter (between first pair of --- lines)
      local frontmatter=$(awk '/^---$/{n++; next} n==1{print} n==2{exit}' "$src")
      local param_names=$(echo "$frontmatter" | yq '.metadata.params | keys | .[]?' 2>/dev/null)
      for param in $param_names; do
        local value=""
        if [[ -n "$PROJECT_CONFIG" && -f "$PROJECT_CONFIG" ]]; then
          value=$(yq ".params.\"$s\".\"$param\" // \"\"" "$PROJECT_CONFIG" 2>/dev/null)
        fi
        if [[ -z "$value" ]]; then
          value=$(echo "$frontmatter" | yq ".metadata.params.\"$param\"" 2>/dev/null)
        fi
        if [[ -n "$value" && "$value" != "null" ]]; then
          sed -i "s|{{params.$param}}|$value|g" "$dest"
        fi
      done
    fi

    # Handle invocation: user-only skills go to prompts (kiro) or get extra frontmatter (claude)
    local invocation=$(yq '.metadata.invocation // "both"' "$src" 2>/dev/null)
    if [[ "$invocation" == "user-only" && "$tool" == "kiro-cli" ]]; then
      mkdir -p "$output_dir/.kiro/prompts"
      cp "$dest" "$output_dir/.kiro/prompts/$s.md"
    fi
  done
}

generate_tool() {
  local tool="$1"
  local tool_output="$OUTPUT/$tool"
  rm -rf "$tool_output"
  mkdir -p "$tool_output"

  echo "  Generating for $tool → $tool_output/"

  # Determine which archetypes to include
  local archetypes_to_generate=""
  if [[ -n "$PROJECT_CONFIG" && -f "$PROJECT_CONFIG" ]]; then
    # Only include archetypes referenced by selected crews
    for crew in $(yq '.crews[]?' "$PROJECT_CONFIG" 2>/dev/null); do
      local crew_file="$COMPOSITIONS_DIR/crew-patterns/$crew.yaml"
      [[ -f "$crew_file" ]] || continue
      archetypes_to_generate="$archetypes_to_generate $(yq '.agents.lead, .agents.workers[]?' "$crew_file" 2>/dev/null)"
    done
    archetypes_to_generate=$(echo "$archetypes_to_generate" | tr ' ' '\n' | sort -u | grep -v '^$')
  fi

  # Generate agent configs
  for f in "$COMPOSITIONS_DIR"/agent-archetypes/*.yaml; do
    [[ -f "$f" ]] || continue
    local aname=$(yq '.name' "$f")
    # Filter if project config specifies crews
    if [[ -n "$archetypes_to_generate" ]]; then
      echo "$archetypes_to_generate" | grep -qx "$aname" || continue
    fi
    if [[ "$tool" == "kiro-cli" ]]; then
      generate_agent_kiro "$f" "$tool_output"
    elif [[ "$tool" == "claude-code" ]]; then
      generate_agent_claude "$f" "$tool_output"
    fi
  done

  # Deploy skills
  deploy_skills "$tool" "$tool_output"

  # Deploy eager-context
  local eager_dir="$ATOMICS_DIR/eager-context"
  if [[ -d "$eager_dir" ]]; then
    for f in "$eager_dir"/*.md; do
      [[ -f "$f" ]] || continue
      local ename=$(basename "$f" .md)
      if [[ "$tool" == "kiro-cli" ]]; then
        mkdir -p "$tool_output/.kiro/steering/universal"
        cp "$f" "$tool_output/.kiro/steering/universal/$ename.md"
      elif [[ "$tool" == "claude-code" ]]; then
        # Append to CLAUDE.md
        echo "" >> "$tool_output/CLAUDE.md"
        cat "$f" >> "$tool_output/CLAUDE.md"
      fi
    done
  fi

  # Count outputs
  local agent_count=$(find "$tool_output" -name "*.json" -o -name "*.md" -path "*/agents/*" | wc -l)
  local skill_count=$(find "$tool_output" -path "*/skills/*/SKILL.md" | wc -l)
  echo "    Agents: $agent_count | Skills: $skill_count"
}

# --- Main ---

case "$COMMAND" in
  validate)
    validate
    ;;
  generate)
    validate || { echo "Validation failed. Fix errors before generating." >&2; exit 1; }
    echo ""
    echo "Generating deployments..."
    if [[ "$TOOL" == "all" ]]; then
      generate_tool "kiro-cli"
      generate_tool "claude-code"
    else
      generate_tool "$TOOL"
    fi
    echo ""
    echo "Done. Output: $OUTPUT/"
    ;;
  *)
    echo "Usage: $0 [validate|generate] [--tool kiro-cli|claude-code|all] [--output ./deploy]" >&2
    exit 1
    ;;
esac
