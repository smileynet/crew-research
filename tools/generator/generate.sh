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

while [[ $# -gt 0 ]]; do
  case $1 in
    --tool) TOOL="$2"; shift 2 ;;
    --output) OUTPUT="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

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

generate_agent_kiro() {
  local archetype_file="$1" output_dir="$2"
  local name=$(yq '.name' "$archetype_file")
  local desc=$(yq '.description' "$archetype_file")
  local prompt=$(yq '.prompt' "$archetype_file")
  local tools=$(yq -o=json '.tools' "$archetype_file")

  # Build resources array: skills as skill:// URIs
  local resources="[]"
  local skills=$(yq '.skills[]?' "$archetype_file" 2>/dev/null)
  for s in $skills; do
    resources=$(echo "$resources" | yq -o=json ". + [\"skill://.kiro/skills/$s/SKILL.md\"]")
  done

  # Add eager-context as file:// URIs
  local eager=$(yq '.["eager-context"][]?' "$archetype_file" 2>/dev/null)
  for e in $eager; do
    resources=$(echo "$resources" | yq -o=json ". + [\"file://.kiro/steering/universal/$e.md\"]")
  done

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

  # Build skills list
  local skills_field=""
  local skills=$(yq '.skills[]?' "$archetype_file" 2>/dev/null)
  if [[ -n "$skills" ]]; then
    skills_field="skills:"
    for s in $skills; do
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

  # Collect all referenced skills
  local all_skills=$(for f in "$COMPOSITIONS_DIR"/agent-archetypes/*.yaml "$COMPOSITIONS_DIR"/crew-patterns/*.yaml; do
    [[ -f "$f" ]] || continue
    yq '.skills[]? // .["shared-skills"][]?' "$f" 2>/dev/null
  done | sort -u)

  for s in $all_skills; do
    local src="$ATOMICS_DIR/skills/$s/SKILL.md"
    [[ -f "$src" ]] || continue

    if [[ "$tool" == "kiro-cli" ]]; then
      mkdir -p "$output_dir/.kiro/skills/$s"
      cp "$src" "$output_dir/.kiro/skills/$s/SKILL.md"
    elif [[ "$tool" == "claude-code" ]]; then
      mkdir -p "$output_dir/.claude/skills/$s"
      cp "$src" "$output_dir/.claude/skills/$s/SKILL.md"
    fi

    # Handle invocation: user-only skills go to prompts (kiro) or get extra frontmatter (claude)
    local invocation=$(yq '.metadata.invocation // "both"' "$src" 2>/dev/null)
    if [[ "$invocation" == "user-only" && "$tool" == "kiro-cli" ]]; then
      mkdir -p "$output_dir/.kiro/prompts"
      cp "$src" "$output_dir/.kiro/prompts/$s.md"
    fi
  done
}

generate_tool() {
  local tool="$1"
  local tool_output="$OUTPUT/$tool"
  rm -rf "$tool_output"
  mkdir -p "$tool_output"

  echo "  Generating for $tool → $tool_output/"

  # Generate agent configs
  for f in "$COMPOSITIONS_DIR"/agent-archetypes/*.yaml; do
    [[ -f "$f" ]] || continue
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
