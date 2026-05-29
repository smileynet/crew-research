#!/bin/bash
# tools/generator/init.sh — Deploy crew-research skills globally or scaffold a project
# Usage:
#   ./init.sh --global --tier <basic|full>              # Deploy to ~/.kiro/
#   ./init.sh --project <path> [--tier <basic|full>]    # Scaffold workspace only
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TIERS_DIR="$ROOT_DIR/compositions/tiers"
SKILLS_DIR="$ROOT_DIR/atomics/skills"

PROJECT=""
GLOBAL=false
TIER="basic"
TOOL="kiro-cli"
LANGUAGE=""
BUILD_CMD=""
TEST_CMD=""
LINT_CMD=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --global) GLOBAL=true; shift ;;
    --project) PROJECT="$2"; shift 2 ;;
    --tier) TIER="$2"; shift 2 ;;
    --tool) TOOL="$2"; shift 2 ;;
    --language) LANGUAGE="$2"; shift 2 ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done

# Validate
TIER_FILE="$TIERS_DIR/$TIER.yaml"
[[ -f "$TIER_FILE" ]] || { echo "Error: unknown tier '$TIER'" >&2; exit 1; }

if [[ "$GLOBAL" == true ]]; then
  # ═══════════════════════════════════════════════════════════════
  # GLOBAL DEPLOY — steering, skills, prompts to ~/.kiro/
  # ═══════════════════════════════════════════════════════════════
  DEST="$HOME/.kiro"
  echo "Deploying crew-research ($TIER tier) to $DEST"
  echo ""

  # Read tier
  STEERING=($(yq -r '.steering[]' "$TIER_FILE"))
  SKILLS=($(yq -r '.skills[]' "$TIER_FILE"))
  PROMPTS=($(yq -r '.prompts[]' "$TIER_FILE"))

  # Deploy steering
  mkdir -p "$DEST/steering"
  for skill in "${STEERING[@]}"; do
    src="$SKILLS_DIR/$skill/SKILL.md"
    if [[ -f "$src" ]]; then
      awk 'BEGIN{s=0} /^---$/{s++;next} s>=2{print}' "$src" > "$DEST/steering/$skill.md"
    fi
  done
  echo "  ✅ Steering: ${#STEERING[@]} files → ~/.kiro/steering/"

  # Deploy skills
  mkdir -p "$DEST/skills"
  for skill in "${SKILLS[@]}"; do
    src_dir="$SKILLS_DIR/$skill"
    if [[ -d "$src_dir" ]]; then
      dest="$DEST/skills/$skill"
      mkdir -p "$dest"
      cp "$src_dir/SKILL.md" "$dest/"
      [[ -d "$src_dir/references" ]] && cp -r "$src_dir/references" "$dest/" 2>/dev/null || true
    fi
  done
  echo "  ✅ Skills: ${#SKILLS[@]} → ~/.kiro/skills/"

  # Deploy prompts (flatten description to single line)
  mkdir -p "$DEST/prompts"
  for prompt in "${PROMPTS[@]}"; do
    dest="$DEST/prompts/$prompt.md"
    src="$SKILLS_DIR/$prompt/SKILL.md"
    alt_src="$ROOT_DIR/.kiro/prompts/$prompt.md"
    if [[ -f "$src" ]]; then
      frontmatter=$(awk '/^---$/{c++;next} c==1{print}' "$src")
      name_val=$(echo "$frontmatter" | yq -r '.name')
      desc_val=$(echo "$frontmatter" | yq -r '.description' | tr '\n' ' ' | sed 's/  */ /g;s/ *$//')
      {
        echo "---"
        echo "name: $name_val"
        echo "description: \"$desc_val\""
        echo "---"
        awk 'BEGIN{s=0} /^---$/{s++;next} s>=2{print}' "$src"
      } > "$dest"
    elif [[ -f "$alt_src" ]]; then
      cp "$alt_src" "$dest"
    fi
  done
  echo "  ✅ Prompts: ${#PROMPTS[@]} → ~/.kiro/prompts/"

  echo ""
  echo "Done. Skills/prompts available in all projects."
  echo "Run: ./init.sh --project <path> to scaffold a specific project."

elif [[ -n "$PROJECT" ]]; then
  # ═══════════════════════════════════════════════════════════════
  # PROJECT SCAFFOLD — workspace structure only
  # ═══════════════════════════════════════════════════════════════
  PROJECT=$(cd "$PROJECT" 2>/dev/null && pwd || (mkdir -p "$PROJECT" && cd "$PROJECT" && pwd))
  echo "Scaffolding project: $PROJECT"
  echo ""

  # Detect language and commands
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

  # Create workspace structure
  mkdir -p "$PROJECT/.scratch" "$PROJECT/.memory/adr" "$PROJECT/docs" "$PROJECT/resources"

  # .gitignore
  if [[ -f "$PROJECT/.gitignore" ]]; then
    grep -qx '.scratch/' "$PROJECT/.gitignore" 2>/dev/null || echo '.scratch/' >> "$PROJECT/.gitignore"
    grep -qx 'resources/' "$PROJECT/.gitignore" 2>/dev/null || echo 'resources/' >> "$PROJECT/.gitignore"
  else
    printf '.scratch/\nresources/\n' > "$PROJECT/.gitignore"
  fi
  echo "  ✅ .gitignore"

  # CONTEXT.md
  if [[ ! -f "$PROJECT/.memory/CONTEXT.md" ]]; then
    printf '# Context\n\n<!-- Project glossary. **Term**: Definition. _Avoid_: synonym. -->\n' > "$PROJECT/.memory/CONTEXT.md"
    echo "  ✅ .memory/CONTEXT.md"
  fi

  # AGENTS.md
  if [[ ! -f "$PROJECT/AGENTS.md" ]]; then
    PROJECT_NAME=$(basename "$PROJECT")
    cat > "$PROJECT/AGENTS.md" <<EOF
# AGENTS.md

## Project
$PROJECT_NAME

## Workspace
- \`.scratch/\` — Ephemeral working notes (gitignored)
- \`.memory/\` — Durable artifacts (glossary, ADRs)
- \`docs/\` — User-facing documents
- \`resources/\` — Third-party repos for reference (gitignored)

## Commands
\`\`\`bash
${BUILD_CMD:+$BUILD_CMD  # build
}${TEST_CMD:+$TEST_CMD  # test
}${LINT_CMD:+$LINT_CMD  # lint
}\`\`\`

## Prompts
- \`@grill-with-docs\` — Stress-test a plan before building
- \`@handoff\` / \`@read-handoff\` — Session continuity
- \`@plan-prereqs\` — Identify pre-work before building
- \`@workspace-cleanup\` — Periodic housekeeping
- \`@cheatsheet\` — Quick reference

## References

Third-party repos for analysis. Gitignored — clone to restore:
\`\`\`bash
# git clone <url> resources/<name>   # what it's used for
\`\`\`
EOF
    echo "  ✅ AGENTS.md"
  fi

  # .crew-config.yaml
  if [[ ! -f "$PROJECT/.crew-config.yaml" ]]; then
    PROJECT_NAME=$(basename "$PROJECT")
    cat > "$PROJECT/.crew-config.yaml" <<EOF
project: $PROJECT_NAME
language: ${LANGUAGE:-unknown}

verification:
  build: "${BUILD_CMD}"
  test: "${TEST_CMD}"
  lint: "${LINT_CMD}"
EOF
    echo "  ✅ .crew-config.yaml"
  fi

  echo ""
  echo "Done. Project workspace scaffolded."
  echo "Skills/prompts come from ~/.kiro/ (global). Add project-specific"
  echo "steering to .kiro/steering/ or prompts to .kiro/prompts/ as needed."

else
  echo "Usage:"
  echo "  $0 --global --tier <basic|full>           # Deploy to ~/.kiro/"
  echo "  $0 --project <path> [--tier <basic|full>] # Scaffold workspace"
  exit 1
fi
