#!/bin/bash
# tools/generator/init.sh — Initialize a project with crew-research workspace conventions
# Usage: ./init.sh --project <path> --crews <crew1,crew2> --tool <kiro-cli|claude-code> [--language <lang>]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

PROJECT=""
CREWS=""
TOOL="kiro-cli"
LANGUAGE=""
BUILD_CMD=""
TEST_CMD=""
LINT_CMD=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --project) PROJECT="$2"; shift 2 ;;
    --crews) CREWS="$2"; shift 2 ;;
    --tool) TOOL="$2"; shift 2 ;;
    --language) LANGUAGE="$2"; shift 2 ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done

[[ -n "$PROJECT" ]] || { echo "Usage: $0 --project <path> --crews <crew1,crew2> --tool <tool>" >&2; exit 1; }
[[ -n "$CREWS" ]] || { echo "Error: --crews required (e.g., development,bugfix)" >&2; exit 1; }

PROJECT=$(cd "$PROJECT" 2>/dev/null && pwd || echo "$PROJECT")
mkdir -p "$PROJECT"

echo "Initializing crew workspace: $PROJECT"
echo "Crews: $CREWS | Tool: $TOOL"
echo ""

# 1. Create directory structure
echo "Creating workspace structure..."
mkdir -p "$PROJECT/.scratch"
mkdir -p "$PROJECT/.memory/adr"
mkdir -p "$PROJECT/resources"
mkdir -p "$PROJECT/docs"

# 2. Create .gitignore entries
if [[ -f "$PROJECT/.gitignore" ]]; then
  grep -qx '.scratch/' "$PROJECT/.gitignore" 2>/dev/null || echo '.scratch/' >> "$PROJECT/.gitignore"
  grep -qx 'resources/' "$PROJECT/.gitignore" 2>/dev/null || echo 'resources/' >> "$PROJECT/.gitignore"
else
  cat > "$PROJECT/.gitignore" << 'EOF'
.scratch/
resources/
EOF
fi
echo "  ✅ .gitignore updated"

# 3. Create CONTEXT.md glossary template
if [[ ! -f "$PROJECT/.memory/CONTEXT.md" ]]; then
  cat > "$PROJECT/.memory/CONTEXT.md" << 'EOF'
# Context

<!-- Project glossary. Define terms as they are resolved. -->
<!-- Format: **Term**: Definition. _Avoid_: what not to call it. -->
EOF
  echo "  ✅ .memory/CONTEXT.md created"
else
  echo "  ⏭️  .memory/CONTEXT.md already exists"
fi

# 4. Create resources/ rehydration instructions
if [[ ! -f "$PROJECT/.memory/resources.md" ]]; then
  cat > "$PROJECT/.memory/resources.md" << 'EOF'
# Resources (Rehydration)

Third-party repos, tools, and code used for reference and analysis.
The `resources/` directory is gitignored — use these instructions to restore.

## Repos
<!-- Add entries as resources are added:
- `resources/repo-name` — `git clone <url>` — what it's used for
-->
EOF
  echo "  ✅ .memory/resources.md created"
else
  echo "  ⏭️  .memory/resources.md already exists"
fi

# 5. Detect verification commands
if [[ -f "$PROJECT/Cargo.toml" ]]; then
  BUILD_CMD="cargo check"; TEST_CMD="cargo test"; LINT_CMD="cargo clippy -- -D warnings"
  [[ -z "$LANGUAGE" ]] && LANGUAGE="rust"
elif [[ -f "$PROJECT/package.json" ]]; then
  BUILD_CMD="npm run build"
  TEST_CMD="npm test"
  LINT_CMD="npm run lint"
  [[ -z "$LANGUAGE" ]] && LANGUAGE="typescript"
  [[ -f "$PROJECT/pnpm-lock.yaml" ]] && { BUILD_CMD="pnpm build"; TEST_CMD="pnpm test"; LINT_CMD="pnpm lint"; }
elif [[ -f "$PROJECT/pyproject.toml" ]] || [[ -f "$PROJECT/setup.py" ]]; then
  BUILD_CMD=""; TEST_CMD="pytest"; LINT_CMD="ruff check ."
  [[ -z "$LANGUAGE" ]] && LANGUAGE="python"
elif [[ -f "$PROJECT/go.mod" ]]; then
  BUILD_CMD="go build ./..."; TEST_CMD="go test ./..."; LINT_CMD="golangci-lint run"
  [[ -z "$LANGUAGE" ]] && LANGUAGE="go"
fi

# 6. Create AGENTS.md (agent-facing entry point)
if [[ ! -f "$PROJECT/AGENTS.md" ]]; then
  PROJECT_NAME=$(basename "$PROJECT")
  CMDS=""
  [[ -n "$BUILD_CMD" ]] && CMDS="${CMDS}${BUILD_CMD}  # build
"
  [[ -n "$TEST_CMD" ]] && CMDS="${CMDS}${TEST_CMD}  # test
"
  [[ -n "$LINT_CMD" ]] && CMDS="${CMDS}${LINT_CMD}  # lint
"
  cat > "$PROJECT/AGENTS.md" <<AGENTSEOF
# AGENTS.md

## Project
$PROJECT_NAME

## Workspace

- \`.scratch/\` — Ephemeral artifacts (handoffs, scratch notes). Gitignored.
- \`.memory/\` — Durable artifacts (glossary, ADRs, resource rehydration)
- \`docs/\` — User-facing documents (placed here only when deliberately requested)
- \`resources/\` — Third-party repos/tools for reference (gitignored; see .memory/resources.md to rehydrate)

## Documentation Map

| Need | Look in |
|------|---------|
| Term definitions | \`.memory/CONTEXT.md\` |
| Architecture decisions | \`.memory/adr/\` |
| Resource rehydration | \`.memory/resources.md\` |
| User-facing docs | \`docs/\` |
| Agent skills | \`.kiro/skills/\` |
| Agent steering | \`.kiro/steering/\` |

## Commands

\`\`\`bash
${CMDS}\`\`\`

## Conventions

- Documents default to \`.scratch/\` (ephemeral) or \`.memory/\` (durable)
- Only place documents in \`docs/\` when explicitly requested for user-facing publication
- All shared artifacts require frontmatter: \`created_at\`, \`base_commit\`
AGENTSEOF
  echo "  ✅ AGENTS.md created"
else
  echo "  ⏭️  AGENTS.md already exists"
fi

# 7. Create .crew-config.yaml
if [[ ! -f "$PROJECT/.crew-config.yaml" ]]; then
  PROJECT_NAME=$(basename "$PROJECT")
  CREWS_YAML=$(echo "$CREWS" | tr ',' '\n' | sed 's/^/  - /')
  cat > "$PROJECT/.crew-config.yaml" << EOF
project: $PROJECT_NAME
language: ${LANGUAGE:-unknown}

crews:
$CREWS_YAML

verification:
  build: "${BUILD_CMD}"
  test: "${TEST_CMD}"
  lint: "${LINT_CMD}"

params:
  verification-protocol:
    build_command: "${BUILD_CMD}"
    test_command: "${TEST_CMD}"
    lint_command: "${LINT_CMD}"
EOF
  echo "  ✅ .crew-config.yaml created"
else
  echo "  ⏭️  .crew-config.yaml already exists"
fi

# 6. Generate deployment
echo ""
echo "Generating $TOOL deployment..."
"$SCRIPT_DIR/generate.sh" generate --project "$PROJECT" --tool "$TOOL" --output "$PROJECT"
# Move from nested tool dir to project root
if [[ -d "$PROJECT/$TOOL" ]]; then
  cp -r "$PROJECT/$TOOL/." "$PROJECT/"
  rm -rf "$PROJECT/$TOOL"
fi

# 7. Summary
echo ""
echo "=== Initialization Complete ==="
echo ""
echo "Created:"
[[ -d "$PROJECT/.scratch" ]] && echo "  .scratch/              (ephemeral workspace)"
[[ -f "$PROJECT/.memory/CONTEXT.md" ]] && echo "  .memory/CONTEXT.md     (project glossary)"
[[ -f "$PROJECT/.crew-config.yaml" ]] && echo "  .crew-config.yaml      (crew configuration)"
if [[ "$TOOL" == "kiro-cli" ]]; then
  agent_count=$(ls "$PROJECT/.kiro/agents/"*.json 2>/dev/null | wc -l)
  skill_count=$(find "$PROJECT/.kiro/skills" -name "SKILL.md" 2>/dev/null | wc -l)
  echo "  .kiro/agents/          ($agent_count agents)"
  echo "  .kiro/skills/          ($skill_count skills)"
  [[ -d "$PROJECT/.kiro/steering" ]] && echo "  .kiro/steering/        (eager-context)"
  [[ -d "$PROJECT/.kiro/prompts" ]] && echo "  .kiro/prompts/         (user-invoked prompts)"
elif [[ "$TOOL" == "claude-code" ]]; then
  agent_count=$(ls "$PROJECT/.claude/agents/"*.md 2>/dev/null | wc -l)
  skill_count=$(find "$PROJECT/.claude/skills" -name "SKILL.md" 2>/dev/null | wc -l)
  echo "  .claude/agents/        ($agent_count agents)"
  echo "  .claude/skills/        ($skill_count skills)"
fi
echo ""
echo "Next steps:"
echo "  1. Review .crew-config.yaml — adjust verification commands if needed"
echo "  2. Add project terms to .memory/CONTEXT.md as they emerge"
echo "  3. Start working: kiro-cli chat --agent lead"
