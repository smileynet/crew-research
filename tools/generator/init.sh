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
  # GLOBAL DEPLOY — steering + skills to ~/.kiro/
  # Diff-based: only updates changed files, prunes removed ones.
  # ═══════════════════════════════════════════════════════════════
  DEST="$HOME/.kiro"
  echo "Deploying crew-research ($TIER tier) to $DEST"
  echo ""

  # Read tier
  STEERING=($(yq -r '.steering[]' "$TIER_FILE"))
  SKILLS=($(yq -r '.skills[]' "$TIER_FILE"))

  # Counters
  updated=0; removed=0; unchanged=0

  # Helper: deploy a file only if content differs (resolves params)
  deploy_file() {
    local src="$1" dest="$2"
    mkdir -p "$(dirname "$dest")"
    local content
    content=$(sed \
      -e 's|{{params.ephemeral_path}}|.scratch|g' \
      -e 's|{{params.handoff_file}}|HANDOFF.md|g' \
      -e 's|{{params.glossary_path}}|.memory/CONTEXT.md|g' \
      -e 's|{{params.durable_path}}|.memory|g' \
      -e 's|{{params.scripts_path}}|tools|g' \
      -e 's|{{params.mise_file}}|mise.toml|g' \
      -e 's|{{params.output_path}}|.scratch/research|g' "$src")
    if [[ -f "$dest" ]] && printf '%s\n' "$content" | diff -q - "$dest" &>/dev/null; then
      unchanged=$((unchanged + 1))
    else
      printf '%s\n' "$content" > "$dest"
      updated=$((updated + 1))
    fi
  }

  # Helper: deploy generated content only if it differs
  deploy_content() {
    local content="$1" dest="$2"
    mkdir -p "$(dirname "$dest")"
    # Resolve params before comparing
    content=$(echo "$content" | sed \
      -e 's|{{params.ephemeral_path}}|.scratch|g' \
      -e 's|{{params.handoff_file}}|HANDOFF.md|g' \
      -e 's|{{params.glossary_path}}|.memory/CONTEXT.md|g' \
      -e 's|{{params.durable_path}}|.memory|g' \
      -e 's|{{params.scripts_path}}|tools|g' \
      -e 's|{{params.mise_file}}|mise.toml|g' \
      -e 's|{{params.output_path}}|.scratch/research|g')
    if [[ -f "$dest" ]] && printf '%s\n' "$content" | diff -q - "$dest" &>/dev/null; then
      unchanged=$((unchanged + 1))
    else
      printf '%s\n' "$content" > "$dest"
      updated=$((updated + 1))
    fi
  }

  # Track desired files for pruning
  declare -A DESIRED_FILES

  # --- Deploy steering ---
  mkdir -p "$DEST/steering"
  for skill in "${STEERING[@]}"; do
    src="$SKILLS_DIR/$skill/SKILL.md"
    if [[ -f "$src" ]]; then
      dest="$DEST/steering/$skill.md"
      content=$(awk 'BEGIN{s=0} /^---$/{s++;next} s>=2{print}' "$src")
      deploy_content "$content" "$dest"
      DESIRED_FILES["$dest"]=1
    fi
  done

  # --- Deploy skills ---
  mkdir -p "$DEST/skills"
  for skill in "${SKILLS[@]}"; do
    src_dir="$SKILLS_DIR/$skill"
    if [[ -d "$src_dir" ]]; then
      dest="$DEST/skills/$skill"
      mkdir -p "$dest"
      deploy_file "$src_dir/SKILL.md" "$dest/SKILL.md"
      DESIRED_FILES["$dest/SKILL.md"]=1
      if [[ -d "$src_dir/references" ]]; then
        for ref in "$src_dir/references/"*; do
          [[ -f "$ref" ]] || continue
          deploy_file "$ref" "$dest/references/$(basename "$ref")"
          DESIRED_FILES["$dest/references/$(basename "$ref")"]=1
        done
      fi
    fi
  done

  # --- Prune stale files ---
  # Steering: remove .md files not in tier
  for f in "$DEST/steering/"*.md; do
    [[ -f "$f" ]] || continue
    if [[ -z "${DESIRED_FILES[$f]:-}" ]]; then
      rm "$f"
      removed=$((removed + 1))
      echo "  pruned: $(basename "$f")"
    fi
  done

  # Skills: remove skill dirs not in tier
  for d in "$DEST/skills/"*/; do
    [[ -d "$d" ]] || continue
    skill_name=$(basename "$d")
    if ! printf '%s\n' "${SKILLS[@]}" | grep -qx "$skill_name"; then
      rm -rf "$d"
      removed=$((removed + 1))
      echo "  pruned: skills/$skill_name/"
    fi
  done

  # Prompts: remove entire directory (skills-only model)
  if [[ -d "$DEST/prompts" ]]; then
    rm -rf "$DEST/prompts"
    echo "  pruned: prompts/ (migrated to skills)"
  fi

  # --- Summary ---
  echo ""
  echo "  Steering: ${#STEERING[@]} | Skills: ${#SKILLS[@]}"
  echo "  $updated updated, $removed pruned, $unchanged unchanged"
  echo ""
  echo "Done. Skills available in all projects."
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
    grep -qx '.references/' "$PROJECT/.gitignore" 2>/dev/null || echo '.references/' >> "$PROJECT/.gitignore"
  else
    printf '.scratch/\n.references/\n' > "$PROJECT/.gitignore"
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
- \`.memory/CONTEXT.md\` — Project glossary (update when terms are resolved)
- \`docs/\` — User-facing documents
- \`.references/\` — Third-party repos for reference (gitignored)

## Commands
\`\`\`bash
${BUILD_CMD:+$BUILD_CMD  # build
}${TEST_CMD:+$TEST_CMD  # test
}${LINT_CMD:+$LINT_CMD  # lint
}\`\`\`

## Skills & Steering

Skills and steering deploy to \`~/.kiro/\` (global) and are active in every project.
Steering loads automatically every turn. Skills activate on-demand when relevant.

User-invocable workflows via \`/name\`:
- \`/grill-with-docs\` — Stress-test a plan before building
- \`/handoff\` / \`/read-handoff\` — Session continuity
- \`/plan-prereqs\` — Identify pre-work before building
- \`/workspace-cleanup\` — Periodic housekeeping
- \`/cheatsheet\` — Quick reference for all skills

## Maintaining This Setup

- **Add project-specific rules**: create \`.kiro/steering/project-rules.md\`
- **Add project-specific skills**: create \`.kiro/skills/{name}/SKILL.md\`
- **Update glossary**: add terms to \`.memory/CONTEXT.md\` as they emerge
- **Customize verification**: edit \`.crew-config.yaml\` with build/test/lint commands
- **Remove unwanted rules**: delete specific files from \`.kiro/steering/\`

## References

Third-party repos for analysis. Gitignored — clone to restore:
\`\`\`bash
# git clone <url> references/<name>   # what it's used for
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
  echo "Skills come from ~/.kiro/ (global). Add project-specific"
  echo "steering to .kiro/steering/ or skills to .kiro/skills/ as needed."

else
  echo "Usage:"
  echo "  $0 --global --tier <basic|full>           # Deploy to ~/.kiro/"
  echo "  $0 --project <path> [--tier <basic|full>] # Scaffold workspace"
  exit 1
fi
