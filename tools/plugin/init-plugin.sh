#!/usr/bin/env bash
# init-plugin.sh — Bootstrap a tool repo for skill ownership
#
# Usage: bash tools/plugin/init-plugin.sh <tool-repo-path>
# Interactive: prompts for tool name, version, binary info.
# Generates: skills/, plugin.json, SKILL_MANIFEST.yaml, tools/deploy-skills.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO="${1:-.}"
REPO="$(cd "$REPO" && pwd)"

echo "Initializing skill plugin in: $REPO"
echo ""

# --- Detect tool name ---
TOOL_NAME=""
if [[ -f "$REPO/Cargo.toml" ]]; then
  TOOL_NAME=$(grep '^name' "$REPO/Cargo.toml" | head -1 | sed 's/.*= *"//' | sed 's/".*//')
elif [[ -f "$REPO/pyproject.toml" ]]; then
  TOOL_NAME=$(grep '^name' "$REPO/pyproject.toml" | head -1 | sed 's/.*= *"//' | sed 's/".*//')
elif [[ -f "$REPO/package.json" ]]; then
  TOOL_NAME=$(grep '"name"' "$REPO/package.json" | head -1 | sed 's/.*: *"//' | sed 's/".*//')
fi
TOOL_NAME="${TOOL_NAME:-$(basename "$REPO")}"
read -rp "Tool name [$TOOL_NAME]: " input
TOOL_NAME="${input:-$TOOL_NAME}"

# --- Detect version ---
TOOL_VERSION=""
if [[ -f "$REPO/Cargo.toml" ]]; then
  TOOL_VERSION=$(grep '^version' "$REPO/Cargo.toml" | head -1 | sed 's/.*= *"//' | sed 's/".*//')
elif [[ -f "$REPO/pyproject.toml" ]]; then
  TOOL_VERSION=$(grep '^version' "$REPO/pyproject.toml" | head -1 | sed 's/.*= *"//' | sed 's/".*//')
fi
TOOL_VERSION="${TOOL_VERSION:-0.1.0}"
read -rp "Version [$TOOL_VERSION]: " input
TOOL_VERSION="${input:-$TOOL_VERSION}"

# --- Binary info ---
read -rp "Binary name on PATH (empty if no binary): " BINARY_NAME
VERSION_CMD=""
if [[ -n "$BINARY_NAME" ]]; then
  VERSION_CMD="$BINARY_NAME --version"
  read -rp "Version command [$VERSION_CMD]: " input
  VERSION_CMD="${input:-$VERSION_CMD}"
fi

# --- Description ---
read -rp "One-line description: " DESCRIPTION

# --- Skills to create ---
echo ""
echo "Skills to create (comma-separated slugs, e.g. '$TOOL_NAME' or '$TOOL_NAME,other-skill'):"
read -rp "Skills [$TOOL_NAME]: " SKILLS_INPUT
SKILLS_INPUT="${SKILLS_INPUT:-$TOOL_NAME}"
IFS=',' read -ra SKILL_SLUGS <<< "$SKILLS_INPUT"

echo ""
echo "Generating..."

# --- Create skills/ ---
for slug in "${SKILL_SLUGS[@]}"; do
  slug=$(echo "$slug" | xargs)  # trim whitespace
  mkdir -p "$REPO/skills/$slug/references"
  if [[ ! -f "$REPO/skills/$slug/SKILL.md" ]]; then
    cat > "$REPO/skills/$slug/SKILL.md" <<EOF
---
name: $slug
description: "$DESCRIPTION"
metadata:
  type: reference
  invocation: both
  practice: null
---

# ${slug}

TODO: Document usage, commands, and workflows.
EOF
    echo "  ✅ skills/$slug/SKILL.md (template)"
  else
    echo "  ⏭️  skills/$slug/SKILL.md (already exists)"
  fi
done

# --- plugin.json ---
if [[ ! -f "$REPO/plugin.json" ]]; then
  KEYWORDS=$(printf '"%s"' "$TOOL_NAME")
  cat > "$REPO/plugin.json" <<EOF
{
  "\$schema": "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json",
  "name": "$TOOL_NAME",
  "version": "$TOOL_VERSION",
  "description": "$DESCRIPTION",
  "license": "MIT",
  "keywords": [$KEYWORDS]
}
EOF
  echo "  ✅ plugin.json"
else
  echo "  ⏭️  plugin.json (already exists)"
fi

# --- SKILL_MANIFEST.yaml ---
if [[ ! -f "$REPO/SKILL_MANIFEST.yaml" ]]; then
  {
    echo "name: $TOOL_NAME"
    echo "version: \"$TOOL_VERSION\""
    echo "description: \"$DESCRIPTION\""
    echo ""
    echo "compatibility:"
    echo "  crew_research: \"~> 0.9\""
    echo ""
    if [[ -n "$BINARY_NAME" ]]; then
      echo "binary:"
      echo "  name: $BINARY_NAME"
      echo "  version_cmd: \"$VERSION_CMD\""
      echo "  min_version: \"$TOOL_VERSION\""
    else
      echo "binary: null"
    fi
    echo ""
    echo "skills:"
    for slug in "${SKILL_SLUGS[@]}"; do
      slug=$(echo "$slug" | xargs)
      echo "  - name: $slug"
      echo "    path: skills/$slug"
    done
    echo ""
    echo "deploy:"
    echo "  method: symlink"
    echo "  auto: true"
    echo "  script: tools/deploy-skills.sh"
  } > "$REPO/SKILL_MANIFEST.yaml"
  echo "  ✅ SKILL_MANIFEST.yaml"
else
  echo "  ⏭️  SKILL_MANIFEST.yaml (already exists)"
fi

# --- tools/deploy-skills.sh ---
DEPLOY_SCRIPT="$REPO/tools/deploy-skills.sh"
if [[ ! -f "$DEPLOY_SCRIPT" ]]; then
  mkdir -p "$REPO/tools"
  cat > "$DEPLOY_SCRIPT" <<'DEPLOY_EOF'
#!/usr/bin/env bash
# deploy-skills.sh — Deploy skills to AI tool discovery locations
#
# Usage:
#   deploy-skills.sh                    # kiro, global
#   deploy-skills.sh --tool claude      # claude code, global
#   deploy-skills.sh --tool codex       # codex CLI, global
#   deploy-skills.sh --project <path>   # kiro, project-level
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_SRC="$REPO_DIR/skills"
TOOL="kiro"
TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tool) TOOL="$2"; shift 2 ;;
    --project) TARGET="$(cd "$2" && pwd)"; shift 2 ;;
    *) echo "Usage: deploy-skills.sh [--tool kiro|claude|codex] [--project <path>]" >&2; exit 2 ;;
  esac
done

# Resolve destination
case "$TOOL" in
  kiro)
    DEST="${TARGET:+$TARGET/.kiro/skills}"
    DEST="${DEST:-$HOME/.kiro/skills}" ;;
  claude)
    DEST="${TARGET:+$TARGET/.claude/skills}"
    DEST="${DEST:-$HOME/.claude/skills}" ;;
  codex)
    DEST="${TARGET:+$TARGET/.agents/skills}"
    DEST="${DEST:-$HOME/.agents/skills}" ;;
  *) echo "Unknown tool: $TOOL" >&2; exit 2 ;;
esac

echo "Deploying skills → $TOOL ($DEST)"
mkdir -p "$DEST"

for skill_dir in "$SKILLS_SRC"/*/; do
  [[ -d "$skill_dir" ]] || continue
  name=$(basename "$skill_dir")
  [[ -f "$skill_dir/SKILL.md" ]] || continue

  rm -rf "$DEST/$name"
  if [[ "$TOOL" == "kiro" && -z "$TARGET" ]]; then
    ln -s "$SKILLS_SRC/$name" "$DEST/$name"
    echo "  ✓ $name (symlink)"
  else
    cp -r "$skill_dir" "$DEST/$name"
    echo "  ✓ $name (copy)"
  fi
done

echo "Done."
DEPLOY_EOF
  chmod +x "$DEPLOY_SCRIPT"
  echo "  ✅ tools/deploy-skills.sh"
else
  echo "  ⏭️  tools/deploy-skills.sh (already exists)"
fi

echo ""
echo "Done. Next steps:"
echo "  1. Edit skills/*/SKILL.md with actual content"
echo "  2. Run: bash $(dirname "$0")/validate-plugin.sh $REPO"
echo "  3. Deploy: bash $REPO/tools/deploy-skills.sh"
