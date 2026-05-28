#!/bin/bash
# tools/generator/init.sh — Initialize a project with crew-research skills
# Usage: ./init.sh --project <path> --tier <basic|full> --tool <kiro-cli|claude-code>
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TIERS_DIR="$ROOT_DIR/compositions/tiers"
SKILLS_DIR="$ROOT_DIR/atomics/skills"

PROJECT=""
TIER=""
CREWS=""
TOOL="kiro-cli"
LANGUAGE=""
BUILD_CMD=""
TEST_CMD=""
LINT_CMD=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --project) PROJECT="$2"; shift 2 ;;
    --tier) TIER="$2"; shift 2 ;;
    --crews) CREWS="$2"; shift 2 ;;
    --tool) TOOL="$2"; shift 2 ;;
    --language) LANGUAGE="$2"; shift 2 ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done

[[ -n "$PROJECT" ]] || { echo "Usage: $0 --project <path> --tier <basic|full> --tool <tool>" >&2; exit 1; }
[[ -n "$TIER" ]] || { echo "Error: --tier required (basic or full)" >&2; exit 1; }

# Validate tier
if [[ -n "$TIER" ]]; then
  TIER_FILE="$TIERS_DIR/$TIER.yaml"
  [[ -f "$TIER_FILE" ]] || { echo "Error: unknown tier '$TIER'. Available: $(ls "$TIERS_DIR"/*.yaml 2>/dev/null | xargs -I{} basename {} .yaml | tr '\n' ' ')" >&2; exit 1; }
fi

PROJECT=$(cd "$PROJECT" 2>/dev/null && pwd || (mkdir -p "$PROJECT" && cd "$PROJECT" && pwd))

echo "Initializing workspace: $PROJECT"
[[ -n "$TIER" ]] && echo "Tier: $TIER | Tool: $TOOL"
[[ -n "$CREWS" ]] && echo "Crews: $CREWS | Tool: $TOOL"
echo ""

# --- Detect language and commands ---
if [[ -f "$PROJECT/Cargo.toml" ]]; then
  BUILD_CMD="cargo check"; TEST_CMD="cargo test"; LINT_CMD="cargo clippy -- -D warnings"
  [[ -z "$LANGUAGE" ]] && LANGUAGE="rust"
elif [[ -f "$PROJECT/package.json" ]]; then
  BUILD_CMD="npm run build"; TEST_CMD="npm test"; LINT_CMD="npm run lint"
  [[ -z "$LANGUAGE" ]] && LANGUAGE="typescript"
  [[ -f "$PROJECT/pnpm-lock.yaml" ]] && { BUILD_CMD="pnpm build"; TEST_CMD="pnpm test"; LINT_CMD="pnpm lint"; }
elif [[ -f "$PROJECT/pyproject.toml" ]] || [[ -f "$PROJECT/setup.py" ]]; then
  BUILD_CMD=""; TEST_CMD="pytest"; LINT_CMD="ruff check ."
  [[ -z "$LANGUAGE" ]] && LANGUAGE="python"
elif [[ -f "$PROJECT/go.mod" ]]; then
  BUILD_CMD="go build ./..."; TEST_CMD="go test ./..."; LINT_CMD="golangci-lint run"
  [[ -z "$LANGUAGE" ]] && LANGUAGE="go"
fi

# --- Create workspace structure ---
echo "Creating workspace structure..."
mkdir -p "$PROJECT/.scratch" "$PROJECT/.memory/adr" "$PROJECT/docs"

# .gitignore
if [[ -f "$PROJECT/.gitignore" ]]; then
  grep -qx '.scratch/' "$PROJECT/.gitignore" 2>/dev/null || echo '.scratch/' >> "$PROJECT/.gitignore"
else
  echo '.scratch/' > "$PROJECT/.gitignore"
fi
echo "  ✅ .gitignore updated"

# CONTEXT.md
if [[ ! -f "$PROJECT/.memory/CONTEXT.md" ]]; then
  printf '# Context\n\n<!-- Project glossary. **Term**: Definition. _Avoid_: synonym. -->\n' > "$PROJECT/.memory/CONTEXT.md"
  echo "  ✅ .memory/CONTEXT.md created"
fi

# AGENTS.md
if [[ ! -f "$PROJECT/AGENTS.md" ]]; then
  PROJECT_NAME=$(basename "$PROJECT")
  cat > "$PROJECT/AGENTS.md" <<EOF
# AGENTS.md

## Project
$PROJECT_NAME

## Workspace
- \`.scratch/\` — Ephemeral working notes (gitignored). Default location for new documents.
- \`.memory/\` — Durable artifacts. Glossary (\`CONTEXT.md\`), ADRs (\`adr/\`).
- \`docs/\` — User-facing documents (only when deliberately requested for publication)
- \`.kiro/steering/\` — Always-on behavioral rules (loaded every turn)
- \`.kiro/skills/\` — On-demand knowledge (activates when task matches description)
- \`.kiro/prompts/\` — User-invoked workflows (\`@name\`)
- \`.crew-config.yaml\` — Project-specific params (build/test/lint commands)

## Commands
\`\`\`bash
${BUILD_CMD:+$BUILD_CMD  # build
}${TEST_CMD:+$TEST_CMD  # test
}${LINT_CMD:+$LINT_CMD  # lint
}\`\`\`

## Prompts
- \`@grill-with-docs\` — Stress-test a plan before building
- \`@handoff\` / \`@read-handoff\` — Session continuity
- \`@workspace-cleanup\` — Periodic housekeeping

## File Formats

**CONTEXT.md** (glossary):
\`\`\`
**Term**: One-sentence definition.
_Avoid_: what not to call it
\`\`\`

**ADRs** (\`.memory/adr/NNNN-slug.md\`): Only when hard to reverse, surprising without context, AND has real trade-offs. Short: context, decision, why.

## Customizing Skills

- **Adjust params**: Edit \`.crew-config.yaml\` (build/test/lint commands flow into skills)
- **Remove a skill**: Delete its directory from \`.kiro/skills/\`
- **Disable steering**: Delete the file from \`.kiro/steering/\`
- **Add a skill**: Copy a SKILL.md directory into \`.kiro/skills/\`
- **Add project context to a skill**: Create \`.kiro/skills/{name}/references/project-notes.md\`

If a skill isn't activating, check its \`description:\` field — distinctive trigger words help.
EOF
  echo "  ✅ AGENTS.md created"
fi

# --- Deploy tier content ---
if [[ -n "$TIER" ]]; then
  # Create .crew-config.yaml for param overrides
  if [[ ! -f "$PROJECT/.crew-config.yaml" ]]; then
    PROJECT_NAME=$(basename "$PROJECT")
    cat > "$PROJECT/.crew-config.yaml" << EOF
project: $PROJECT_NAME
tier: $TIER
language: ${LANGUAGE:-unknown}

verification:
  build: "${BUILD_CMD}"
  test: "${TEST_CMD}"
  lint: "${LINT_CMD}"

# Override skill params here. Keys match skill frontmatter params.
# Example:
#   workspace-cleanup:
#     scripts_path: "scripts"
#     mise_file: "Makefile"
EOF
  fi

  echo ""
  echo "Deploying tier: $TIER"

  # Read tier file
  STEERING=($(yq -r '.steering[]' "$TIER_FILE" 2>/dev/null))
  SKILLS=($(yq -r '.skills[]' "$TIER_FILE" 2>/dev/null))
  PROMPTS=($(yq -r '.prompts[]' "$TIER_FILE" 2>/dev/null))
  AGENTS=($(yq -r '.agents // [] | .[]' "$TIER_FILE" 2>/dev/null))

  # Deploy steering
  if [[ ${#STEERING[@]} -gt 0 ]]; then
    mkdir -p "$PROJECT/.kiro/steering"
    for skill in "${STEERING[@]}"; do
      src="$SKILLS_DIR/$skill/SKILL.md"
      if [[ -f "$src" ]]; then
        dest="$PROJECT/.kiro/steering/$skill.md"
        # Extract content after frontmatter for steering
        awk 'BEGIN{skip=0} /^---$/{skip++; next} skip>=2{print}' "$src" > "$dest"
        # Substitute verification commands at deploy time
        if [[ "$skill" == "verification-protocol" ]]; then
          sed -i "s|{{params.build_command}}|$BUILD_CMD|g" "$dest"
          sed -i "s|{{params.test_command}}|$TEST_CMD|g" "$dest"
          sed -i "s|{{params.lint_command}}|$LINT_CMD|g" "$dest"
        fi
      fi
    done
    echo "  ✅ Steering: ${#STEERING[@]} files"
  fi

  # Deploy skills
  if [[ ${#SKILLS[@]} -gt 0 ]]; then
    mkdir -p "$PROJECT/.kiro/skills"
    for skill in "${SKILLS[@]}"; do
      src_dir="$SKILLS_DIR/$skill"
      if [[ -d "$src_dir" ]]; then
        dest="$PROJECT/.kiro/skills/$skill"
        mkdir -p "$dest"
        cp "$src_dir/SKILL.md" "$dest/"
        # Copy references if they exist
        [[ -d "$src_dir/references" ]] && cp -r "$src_dir/references" "$dest/"
      fi
    done
    echo "  ✅ Skills: ${#SKILLS[@]} deployed"
  fi

  # Deploy prompts
  if [[ ${#PROMPTS[@]} -gt 0 ]]; then
    mkdir -p "$PROJECT/.kiro/prompts"
    for prompt in "${PROMPTS[@]}"; do
      # Check skill dir first, then .kiro/prompts/ source
      src="$SKILLS_DIR/$prompt/SKILL.md"
      alt_src="$ROOT_DIR/.kiro/prompts/$prompt.md"
      if [[ -f "$src" ]]; then
        cp "$src" "$PROJECT/.kiro/prompts/$prompt.md"
      elif [[ -f "$alt_src" ]]; then
        cp "$alt_src" "$PROJECT/.kiro/prompts/$prompt.md"
      fi
    done
    echo "  ✅ Prompts: ${#PROMPTS[@]} deployed"
  fi

  # Deploy agents
  if [[ ${#AGENTS[@]} -gt 0 ]]; then
    mkdir -p "$PROJECT/.kiro/agents"
    for agent in "${AGENTS[@]}"; do
      src="$ROOT_DIR/compositions/agent-archetypes/$agent.yaml"
      if [[ -f "$src" ]]; then
        # Convert archetype YAML to kiro-cli agent JSON
        yq -o=json '.' "$src" > "$PROJECT/.kiro/agents/$agent.json"
      fi
    done
    echo "  ✅ Agents: ${#AGENTS[@]} deployed"
  fi

fi

# --- Summary ---
echo ""
echo "=== Initialization Complete ==="
echo ""
skill_count=$(find "$PROJECT/.kiro/skills" -name "SKILL.md" 2>/dev/null | wc -l || true)
steering_count=$(find "$PROJECT/.kiro/steering" -name "*.md" 2>/dev/null | wc -l || true)
prompt_count=$(find "$PROJECT/.kiro/prompts" -name "*.md" 2>/dev/null | wc -l || true)
agent_count=$(find "$PROJECT/.kiro/agents" -name "*.json" 2>/dev/null | wc -l || true)

echo "Deployed:"
[[ $steering_count -gt 0 ]] && echo "  .kiro/steering/   ($steering_count steering files)"
[[ $skill_count -gt 0 ]] && echo "  .kiro/skills/     ($skill_count skills)"
[[ $prompt_count -gt 0 ]] && echo "  .kiro/prompts/    ($prompt_count prompts)"
[[ $agent_count -gt 0 ]] && echo "  .kiro/agents/     ($agent_count agents)"
echo ""
echo "Next: kiro-cli chat"
