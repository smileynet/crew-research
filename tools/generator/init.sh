#!/bin/bash
# tools/generator/init.sh — Deploy crew-research skills globally or scaffold a project
# Usage:
#   ./init.sh --global --tier <basic|full> [--tool kiro-cli] [--tool codex] [--tool agy]
#   ./init.sh --project <path> [--tier <basic|full>]
# If --tool is omitted, reads CREW_TOOLS env var or defaults to kiro-cli.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TIERS_DIR="$ROOT_DIR/compositions/tiers"
SKILLS_DIR="$ROOT_DIR/atomics/skills"

PROJECT=""
GLOBAL=false
TIER="basic"
TOOLS=()
LANGUAGE=""
BUILD_CMD=""
TEST_CMD=""
LINT_CMD=""
PLUGIN=""
REMOVE_PLUGIN=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --global) GLOBAL=true; shift ;;
    --project) PROJECT="$2"; shift 2 ;;
    --tier) TIER="$2"; shift 2 ;;
    --tool) TOOLS+=("$2"); shift 2 ;;
    --language) LANGUAGE="$2"; shift 2 ;;
    --plugin) PLUGIN="$2"; shift 2 ;;
    --remove-plugin) REMOVE_PLUGIN="$2"; shift 2 ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done

# Resolve tools: explicit --tool flags > CREW_TOOLS env > default kiro-cli
if [[ ${#TOOLS[@]} -eq 0 ]]; then
  if [[ -n "${CREW_TOOLS:-}" ]]; then
    read -ra TOOLS <<< "$CREW_TOOLS"
  else
    TOOLS=("kiro-cli")
  fi
fi

# Resolve tier from env if not overridden on CLI (default still basic)
[[ "$TIER" == "basic" && -n "${CREW_TIER:-}" ]] && TIER="$CREW_TIER"

# ═══════════════════════════════════════════════════════════════
# PLUGIN INSTALL / REMOVE
# ═══════════════════════════════════════════════════════════════

PLUGINS_DIR="$ROOT_DIR/compositions/plugins"
PLUGINS_STATE="$HOME/.crew-research/plugins.json"

if [[ -n "$PLUGIN" || -n "$REMOVE_PLUGIN" ]]; then
  mkdir -p "$HOME/.crew-research"

  if [[ -n "$PLUGIN" ]]; then
    PLUGIN_FILE="$PLUGINS_DIR/$PLUGIN.yaml"
    [[ -f "$PLUGIN_FILE" ]] || { echo "Error: plugin '$PLUGIN' not found at $PLUGIN_FILE" >&2; exit 1; }

    # Check prerequisites
    while IFS= read -r cmd_check; do
      [[ -z "$cmd_check" ]] && continue
      if ! eval "$cmd_check" &>/dev/null; then
        hint=$(yq -r '.prerequisites.commands[] | select(.check == "'"$cmd_check"'") | .install_hint' "$PLUGIN_FILE")
        echo "Prerequisite failed: $cmd_check"
        echo "  Install: $hint"
        exit 1
      fi
    done < <(yq -r '.prerequisites.commands[].check' "$PLUGIN_FILE" 2>/dev/null | grep -v '^null$')

    echo "Installing plugin: $PLUGIN"

    # Deploy steering
    for item in $(yq -r '.deploys.steering[]' "$PLUGIN_FILE" 2>/dev/null | grep -v '^null$'); do
      src="$SKILLS_DIR/$item/SKILL.md"
      if [[ -f "$src" ]]; then
        content=$(awk 'BEGIN{s=0} /^---$/{s++;next} s>=2{print}' "$src")
        for tool in "${TOOLS[@]}"; do
          case "$tool" in
            kiro-cli|crush)
              dest="$HOME/.kiro/steering/$item.md"
              mkdir -p "$(dirname "$dest")"
              printf '%s\n' "$content" > "$dest"
              echo "  steering: $item -> $dest"
              ;;
            codex)
              # Append to global AGENTS.md
              agentsmd="${CODEX_HOME:-$HOME/.codex}/AGENTS.md"
              printf '\n# %s\n\n%s\n' "$item" "$content" >> "$agentsmd"
              echo "  steering: $item -> $agentsmd (appended)"
              ;;
            agy)
              # Append to global AGENTS.md
              agentsmd="$HOME/.gemini/AGENTS.md"
              printf '\n# %s\n\n%s\n' "$item" "$content" >> "$agentsmd"
              echo "  steering: $item -> $agentsmd (appended)"
              ;;
          esac
        done
      fi
    done

    # Deploy skills
    for item in $(yq -r '.deploys.skills[]' "$PLUGIN_FILE" 2>/dev/null | grep -v '^null$'); do
      src_dir="$SKILLS_DIR/$item"
      if [[ -d "$src_dir" ]]; then
        for tool in "${TOOLS[@]}"; do
          case "$tool" in
            kiro-cli|crush)
              dest="$HOME/.kiro/skills/$item"
              mkdir -p "$dest"
              cp "$src_dir/SKILL.md" "$dest/SKILL.md"
              if [[ -d "$src_dir/references" ]]; then
                mkdir -p "$dest/references"
                cp "$src_dir/references/"* "$dest/references/" 2>/dev/null
              fi
              echo "  skill: $item -> $dest"
              ;;
            codex)
              dest="$HOME/.agents/skills/$item"
              mkdir -p "$dest"
              cp "$src_dir/SKILL.md" "$dest/SKILL.md"
              if [[ -d "$src_dir/references" ]]; then
                mkdir -p "$dest/references"
                cp "$src_dir/references/"* "$dest/references/" 2>/dev/null
              fi
              echo "  skill: $item -> $dest"
              ;;
            agy)
              dest="$HOME/.gemini/antigravity-cli/skills/$item"
              mkdir -p "$dest"
              cp "$src_dir/SKILL.md" "$dest/SKILL.md"
              if [[ -d "$src_dir/references" ]]; then
                mkdir -p "$dest/references"
                cp "$src_dir/references/"* "$dest/references/" 2>/dev/null
              fi
              echo "  skill: $item -> $dest"
              ;;
          esac
        done
      fi
    done

    # Update state
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)
    mkdir -p "$HOME/.crew-research"
    PYCMD=$(command -v python3 || command -v python)
    tools_json=$(printf '%s\n' "${TOOLS[@]}" | $PYCMD -c "import sys,json; print(json.dumps(sys.stdin.read().split()))")
    if [[ -f "$PLUGINS_STATE" ]]; then
      $PYCMD -c "
import json
state = json.load(open('$PLUGINS_STATE'))
state.setdefault('installed', {})['$PLUGIN'] = {'version': '$(yq -r '.version' "$PLUGIN_FILE")', 'installed_at': '$timestamp', 'tools': $tools_json}
json.dump(state, open('$PLUGINS_STATE', 'w'), indent=2)
"
    else
      $PYCMD -c "
import json
state = {'installed': {'$PLUGIN': {'version': '$(yq -r '.version' "$PLUGIN_FILE")', 'installed_at': '$timestamp', 'tools': $tools_json}}}
json.dump(state, open('$PLUGINS_STATE', 'w'), indent=2)
"
    fi
    echo ""
    echo "Plugin '$PLUGIN' installed."

    # Auto-import .memory/ for recall plugin if it exists
    if [[ "$PLUGIN" == "recall" ]] && command -v recall &>/dev/null; then
      local mem_dir=""
      if [[ -n "$PROJECT_DIR" && -d "$PROJECT_DIR/.memory" ]]; then
        mem_dir="$PROJECT_DIR/.memory"
        local wing_name=$(basename "$PROJECT_DIR" | tr '-' '_')
      elif [[ -d ".memory" ]]; then
        mem_dir=".memory"
        local wing_name=$(basename "$(pwd)" | tr '-' '_')
      fi
      if [[ -n "$mem_dir" ]]; then
        echo "  Auto-importing $mem_dir..."
        recall import "$mem_dir" --wing "$wing_name" 2>&1 | grep -E "Done:|chunks"
      fi
    fi

    exit 0
  fi

  if [[ -n "$REMOVE_PLUGIN" ]]; then
    PLUGIN_FILE="$PLUGINS_DIR/$REMOVE_PLUGIN.yaml"
    [[ -f "$PLUGIN_FILE" ]] || { echo "Error: plugin '$REMOVE_PLUGIN' not found" >&2; exit 1; }

    echo "Removing plugin: $REMOVE_PLUGIN"

    # Remove steering
    for item in $(yq -r '.deploys.steering[]' "$PLUGIN_FILE" 2>/dev/null | grep -v '^null$'); do
      for tool in "${TOOLS[@]}"; do
        case "$tool" in
          kiro-cli|crush) rm -f "$HOME/.kiro/steering/$item.md"; echo "  removed: steering/$item.md" ;;
        esac
      done
    done

    # Remove skills
    for item in $(yq -r '.deploys.skills[]' "$PLUGIN_FILE" 2>/dev/null | grep -v '^null$'); do
      for tool in "${TOOLS[@]}"; do
        case "$tool" in
          kiro-cli|crush) rm -rf "$HOME/.kiro/skills/$item"; echo "  removed: skills/$item/" ;;
        esac
      done
    done

    # Update state
    if [[ -f "$PLUGINS_STATE" ]]; then
      PYCMD=$(command -v python3 || command -v python)
      $PYCMD -c "
import json
state = json.load(open('$PLUGINS_STATE'))
state.get('installed', {}).pop('$REMOVE_PLUGIN', None)
json.dump(state, open('$PLUGINS_STATE', 'w'), indent=2)
"
    fi
    echo ""
    echo "Plugin '$REMOVE_PLUGIN' removed."
    exit 0
  fi
fi

# Validate
TIER_FILE="$TIERS_DIR/$TIER.yaml"
[[ -f "$TIER_FILE" ]] || { echo "Error: unknown tier '$TIER'" >&2; exit 1; }

if [[ "$GLOBAL" == true ]]; then
  # ═══════════════════════════════════════════════════════════════
  # GLOBAL DEPLOY — deploy to each tool's native paths
  # ═══════════════════════════════════════════════════════════════

  # Read tier
  STEERING=($(yq -r '.steering[]' "$TIER_FILE"))
  SKILLS=($(yq -r '.skills[]' "$TIER_FILE"))

  # Helper: deploy a file only if content differs (resolves params)
  deploy_file() {
    local src="$1" dest="$2"
    local real_dest="$dest"
    [[ -L "$dest" ]] && real_dest="$(readlink -f "$dest")"
    mkdir -p "$(dirname "$real_dest")"
    local content
    content=$(sed \
      -e 's|{{params.ephemeral_path}}|.scratch|g' \
      -e 's|{{params.handoff_file}}|HANDOFF.md|g' \
      -e 's|{{params.glossary_path}}|.memory/CONTEXT.md|g' \
      -e 's|{{params.durable_path}}|.memory|g' \
      -e 's|{{params.scripts_path}}|tools|g' \
      -e 's|{{params.mise_file}}|mise.toml|g' \
      -e 's|{{params.output_path}}|.scratch/research|g' "$src")
    if [[ -f "$real_dest" ]] && printf '%s\n' "$content" | diff -q - "$real_dest" &>/dev/null; then
      unchanged=$((unchanged + 1))
    else
      printf '%s\n' "$content" > "$real_dest"
      updated=$((updated + 1))
    fi
  }

  # Helper: deploy generated content only if it differs
  deploy_content() {
    local content="$1" dest="$2"
    local real_dest="$dest"
    [[ -L "$dest" ]] && real_dest="$(readlink -f "$dest")"
    mkdir -p "$(dirname "$real_dest")"
    content=$(echo "$content" | sed \
      -e 's|{{params.ephemeral_path}}|.scratch|g' \
      -e 's|{{params.handoff_file}}|HANDOFF.md|g' \
      -e 's|{{params.glossary_path}}|.memory/CONTEXT.md|g' \
      -e 's|{{params.durable_path}}|.memory|g' \
      -e 's|{{params.scripts_path}}|tools|g' \
      -e 's|{{params.mise_file}}|mise.toml|g' \
      -e 's|{{params.output_path}}|.scratch/research|g')
    if [[ -f "$real_dest" ]] && printf '%s\n' "$content" | diff -q - "$real_dest" &>/dev/null; then
      unchanged=$((unchanged + 1))
    else
      printf '%s\n' "$content" > "$real_dest"
      updated=$((updated + 1))
    fi
  }

  # ─── Tool-specific deploy functions ───────────────────────────

  deploy_kiro_cli() {
    local DEST="$HOME/.kiro"
    echo "Deploying crew-research ($TIER tier) → kiro-cli ($DEST)"
    echo ""

    updated=0; removed=0; unchanged=0
    declare -A DESIRED_FILES

    # --- Deploy steering ---
    mkdir -p "$DEST/steering"
    for skill in "${STEERING[@]}"; do
      src="$SKILLS_DIR/$skill/SKILL.md"
      if [[ -f "$src" ]]; then
        # Skip if skill is scoped to tools that don't include this one
        local skill_tool=$(yq -r '.metadata.tool // ""' "$src" 2>/dev/null)
        local skill_tools=$(yq -r '.metadata.tools // [] | join(",")' "$src" 2>/dev/null)
        if [[ -n "$skill_tool" && "$skill_tool" != "kiro-cli" ]]; then
          continue
        fi
        if [[ -n "$skill_tools" && ! "$skill_tools" =~ "kiro-cli" ]]; then
          continue
        fi
        dest="$DEST/steering/$skill.md"
        content=$(awk 'BEGIN{s=0} /^---$/{s++;next} s>=2{print}' "$src")
        deploy_content "$content" "$dest"
        DESIRED_FILES["$dest"]=1
      fi
      # Deploy steering references (progressive-load companions)
      if [[ -d "$SKILLS_DIR/$skill/references" ]]; then
        mkdir -p "$DEST/steering/references"
        for ref in "$SKILLS_DIR/$skill/references/"*; do
          [[ -f "$ref" ]] || continue
          deploy_file "$ref" "$DEST/steering/references/$(basename "$ref")"
          DESIRED_FILES["$DEST/steering/references/$(basename "$ref")"]=1
        done
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
    for f in "$DEST/steering/"*.md; do
      [[ -f "$f" ]] || continue
      [[ -L "$f" ]] && { echo "  kept (symlink): $(basename "$f")"; continue; }
      if [[ -z "${DESIRED_FILES[$f]:-}" ]]; then
        rm "$f"
        removed=$((removed + 1))
        echo "  pruned: $(basename "$f")"
      fi
    done

    for d in "$DEST/skills/"*/; do
      [[ -d "$d" ]] || continue
      [[ -L "${d%/}" ]] && { echo "  kept (symlink): skills/$(basename "$d")/"; continue; }
      skill_name=$(basename "$d")
      if ! printf '%s\n' "${SKILLS[@]}" | grep -qx "$skill_name"; then
        rm -rf "$d"
        removed=$((removed + 1))
        echo "  pruned: skills/$skill_name/"
      fi
    done

    if [[ -d "$DEST/prompts" ]]; then
      rm -rf "$DEST/prompts"
      echo "  pruned: prompts/ (migrated to skills)"
    fi

    # --- Deploy permissions.yaml (v3 forward-compatible) ---
    local perms_src="$ROOT_DIR/atomics/eager-context/permissions.yaml"
    if [[ -f "$perms_src" ]]; then
      deploy_file "$perms_src" "$DEST/permissions.yaml"
    fi

    echo ""
    echo "  Steering: ${#STEERING[@]} | Skills: ${#SKILLS[@]}"
    echo "  $updated updated, $removed pruned, $unchanged unchanged"
    echo ""
  }

  # ─── Generic AGENTS.md-based tool deploy ───────────────────────
  # Tools that use skills/ dir + single AGENTS.md for steering share this.
  # Args: $1=tool_label $2=skills_dest $3=agents_md_dest
  deploy_agents_md_tool() {
    local tool_label="$1" skills_dest="$2" agents_md_dest="$3"
    echo "Deploying crew-research ($TIER tier) → $tool_label ($skills_dest + $agents_md_dest)"
    echo ""

    updated=0; removed=0; unchanged=0
    declare -A DESIRED_SKILLS

    # --- Deploy skills ---
    mkdir -p "$skills_dest"
    for skill in "${SKILLS[@]}"; do
      src_dir="$SKILLS_DIR/$skill"
      if [[ -d "$src_dir" ]]; then
        dest="$skills_dest/$skill"
        mkdir -p "$dest"
        deploy_file "$src_dir/SKILL.md" "$dest/SKILL.md"
        DESIRED_SKILLS["$skill"]=1
        if [[ -d "$src_dir/references" ]]; then
          mkdir -p "$dest/references"
          for ref in "$src_dir/references/"*; do
            [[ -f "$ref" ]] || continue
            deploy_file "$ref" "$dest/references/$(basename "$ref")"
          done
        fi
      fi
    done

    # --- Render steering into AGENTS.md ---
    mkdir -p "$(dirname "$agents_md_dest")"
    local agents_content="# crew-research steering ($TIER tier)"
    agents_content+=$'\n'"# Auto-generated by crew-research init.sh — do not edit manually"
    agents_content+=$'\n'
    for skill in "${STEERING[@]}"; do
      src="$SKILLS_DIR/$skill/SKILL.md"
      if [[ -f "$src" ]]; then
        # Skip if skill is scoped to tools that don't include this one
        local skill_tool skill_tools
        skill_tool=$(yq -r '.metadata.tool // ""' "$src" 2>/dev/null)
        skill_tools=$(yq -r '.metadata.tools // [] | join(",")' "$src" 2>/dev/null)
        if [[ -n "$skill_tool" && "$skill_tool" != "$tool_label" ]]; then
          continue
        fi
        if [[ -n "$skill_tools" && ! "$skill_tools" =~ "$tool_label" ]]; then
          continue
        fi
        local body
        body=$(awk 'BEGIN{s=0} /^---$/{s++;next} s>=2{print}' "$src")
        body=$(echo "$body" | sed \
          -e 's|{{params.ephemeral_path}}|.scratch|g' \
          -e 's|{{params.handoff_file}}|HANDOFF.md|g' \
          -e 's|{{params.glossary_path}}|.memory/CONTEXT.md|g' \
          -e 's|{{params.durable_path}}|.memory|g' \
          -e 's|{{params.scripts_path}}|tools|g' \
          -e 's|{{params.mise_file}}|mise.toml|g' \
          -e 's|{{params.output_path}}|.scratch/research|g')
        agents_content+=$'\n'"$body"$'\n'
      fi
    done
    if [[ -f "$agents_md_dest" ]] && printf '%s\n' "$agents_content" | diff -q - "$agents_md_dest" &>/dev/null; then
      unchanged=$((unchanged + 1))
    else
      printf '%s\n' "$agents_content" > "$agents_md_dest"
      updated=$((updated + 1))
    fi

    # --- Prune stale skill dirs ---
    for d in "$skills_dest/"*/; do
      [[ -d "$d" ]] || continue
      [[ -L "${d%/}" ]] && continue
      skill_name=$(basename "$d")
      if [[ -z "${DESIRED_SKILLS[$skill_name]:-}" ]]; then
        rm -rf "$d"
        removed=$((removed + 1))
        echo "  pruned: skills/$skill_name/"
      fi
    done

    echo ""
    echo "  Skills: ${#SKILLS[@]} | Steering → $(basename "$agents_md_dest") (${#STEERING[@]} sections)"
    echo "  $updated updated, $removed pruned, $unchanged unchanged"
    echo ""
  }

  deploy_codex() {
    deploy_agents_md_tool "codex" \
      "$HOME/.agents/skills" \
      "${CODEX_HOME:-$HOME/.codex}/AGENTS.md"
  }

  deploy_agy() {
    # Per Google DevRel (June 2026):
    #   Antigravity 2.0 desktop: global = ~/.agents/skills/
    #   Antigravity CLI:          global = ~/.gemini/antigravity-cli/skills/
    #   Both read ~/.gemini/AGENTS.md for steering
    # Deploy skills to both locations; steering to AGENTS.md
    deploy_agents_md_tool "agy" \
      "$HOME/.agents/skills" \
      "$HOME/.gemini/AGENTS.md"
    # Also deploy to CLI-specific path
    local cli_dest="$HOME/.gemini/antigravity-cli/skills"
    mkdir -p "$cli_dest"
    for skill in "${SKILLS[@]}"; do
      src_dir="$SKILLS_DIR/$skill"
      if [[ -d "$src_dir" ]]; then
        dest="$cli_dest/$skill"
        mkdir -p "$dest"
        deploy_file "$src_dir/SKILL.md" "$dest/SKILL.md"
        if [[ -d "$src_dir/references" ]]; then
          mkdir -p "$dest/references"
          for ref in "$src_dir/references/"*; do
            [[ -f "$ref" ]] || continue
            deploy_file "$ref" "$dest/references/$(basename "$ref")"
          done
        fi
      fi
    done
  }

  # ─── Deploy to each requested tool ───────────────────────────

  for tool in "${TOOLS[@]}"; do
    case "$tool" in
      kiro-cli) deploy_kiro_cli ;;
      crush)    deploy_kiro_cli ;;
      codex)    deploy_codex ;;
      agy)      deploy_agy ;;
      *)        echo "Error: unknown tool '$tool'" >&2; exit 1 ;;
    esac
  done

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
- **Remove unwanted rules**: delete specific files from \`.kiro/steering/\`

## References

Third-party repos for analysis. Gitignored — clone to restore:
\`\`\`bash
# git clone <url> references/<name>   # what it's used for
\`\`\`
EOF
    echo "  ✅ AGENTS.md"
  fi

  echo ""
  echo "Done. Project workspace scaffolded."
  echo "Skills come from ~/.kiro/ (global). Add project-specific"
  echo "steering to .kiro/steering/ or skills to .kiro/skills/ as needed."

else
  echo "Usage:"
  echo "  $0 --global [--tier <basic|full>] [--tool <kiro-cli|codex|agy>...]"
  echo "  $0 --project <path> [--tier <basic|full>]"
  echo ""
  echo "If --tool is omitted, reads CREW_TOOLS env (from .mise.local.toml) or defaults to kiro-cli."
  exit 1
fi
