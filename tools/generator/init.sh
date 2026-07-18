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

# Detect deploy HOME: when running in WSL, tools on Windows read from the
# Windows user home (/mnt/c/Users/$USER), not the WSL home (/home/$USER).
DEPLOY_HOME="$HOME"
if [[ -n "${WSL_DISTRO_NAME:-}" || -f /proc/sys/fs/binfmt_misc/WSLInterop ]]; then
  WIN_USER="${WIN_USERNAME:-$USER}"
  if [[ -d "/mnt/c/Users/$WIN_USER" ]]; then
    DEPLOY_HOME="/mnt/c/Users/$WIN_USER"
  fi
fi

PROJECT=""
GLOBAL=false
TIER="basic"
TOOLS=()
BUILD_CMD=""
TEST_CMD=""
LINT_CMD=""
SKIP_EXTENSIONS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    --global) GLOBAL=true; shift ;;
    --project) PROJECT="$2"; shift 2 ;;
    --tier) TIER="$2"; shift 2 ;;
    --tool) TOOLS+=("$2"); shift 2 ;;
    --skip-extension) SKIP_EXTENSIONS+=("$2"); shift 2 ;;
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

  # Process extensions — deploy if prerequisite is met
  EXTENSIONS_COUNT=$(yq -r '.extensions | length // 0' "$TIER_FILE")
  EXTENSIONS_ACTIVE=()
  EXTENSIONS_SKIPPED=()
  if [[ "$EXTENSIONS_COUNT" -gt 0 ]]; then
    for i in $(seq 0 $((EXTENSIONS_COUNT - 1))); do
      ext_name=$(yq -r ".extensions[$i].name" "$TIER_FILE")
      ext_cmd=$(yq -r ".extensions[$i].prerequisite.command" "$TIER_FILE")
      ext_hint=$(yq -r ".extensions[$i].prerequisite.install_hint" "$TIER_FILE")

      # Check if user explicitly skipped this extension
      if printf '%s\n' "${SKIP_EXTENSIONS[@]}" 2>/dev/null | grep -qx "$ext_name" 2>/dev/null; then
        EXTENSIONS_SKIPPED+=("$ext_name (user skipped)")
        continue
      fi

      # Test prerequisite
      if eval "$ext_cmd" &>/dev/null; then
        EXTENSIONS_ACTIVE+=("$ext_name")
        # Append extension steering and skills to main arrays
        for item in $(yq -r ".extensions[$i].steering[]" "$TIER_FILE" 2>/dev/null | grep -v '^null$'); do
          STEERING+=("$item")
        done
        for item in $(yq -r ".extensions[$i].skills[]" "$TIER_FILE" 2>/dev/null | grep -v '^null$'); do
          SKILLS+=("$item")
        done
      else
        EXTENSIONS_SKIPPED+=("$ext_name ($ext_hint)")
      fi
    done
  fi

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
      -e 's|{{params.crosslink_lint}}|tools/lint/check-crosslinks.sh|g' \
      -e 's|{{params.output_path}}|.scratch/research|g' "$src")
    if [[ -f "$real_dest" ]] && printf '%s\n' "$content" | diff -q - "$real_dest" &>/dev/null; then
      unchanged=$((unchanged + 1))
    else
      printf '%s\n' "$content" > "$real_dest"
      updated=$((updated + 1))
    fi
  }

  # Helper: deploy generated content only if it differs
  # Extract a field from SKILL.md frontmatter (handles markdown body safely)
  skill_fm_field() {
    local file="$1" field="$2"
    awk 'BEGIN{s=0} /^---$/{s++; if(s==2) exit; next} s==1{print}' "$file" | yq -r "$field" 2>/dev/null
  }

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
      -e 's|{{params.crosslink_lint}}|tools/lint/check-crosslinks.sh|g' \
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
    local DEST="$DEPLOY_HOME/.kiro"
    echo "Deploying crew-research ($TIER tier) → kiro-cli ($DEST)"
    echo ""

    updated=0; removed=0; unchanged=0
    declare -A DESIRED_FILES
    local STEERING_REF_SKILLS=()

    # --- Deploy steering ---
    mkdir -p "$DEST/steering"
    for skill in "${STEERING[@]}"; do
      src="$SKILLS_DIR/$skill/SKILL.md"
      if [[ -f "$src" ]]; then
        # Skip if skill is scoped to tools that don't include this one
        local skill_tool=$(skill_fm_field "$src" '.metadata.tool // ""')
        local skill_tools=$(skill_fm_field "$src" '.metadata.tools // [] | join(",")')
        if [[ -n "$skill_tool" && "$skill_tool" != "kiro-cli" ]]; then
          continue
        fi
        if [[ -n "$skill_tools" && ! "$skill_tools" =~ "kiro-cli" ]]; then
          continue
        fi
        dest="$DEST/steering/$skill.md"
        content=$(awk 'BEGIN{s=0} /^---$/{s++;next} s>=2{print}' "$src")
        # ADR 0009: steering companion refs live in the skills tree (non-eager);
        # rewrite relative links in the deployed body to their absolute location
        if [[ -d "$SKILLS_DIR/$skill/references" ]]; then
          content=$(echo "$content" | sed "s|](references/|]($DEST/skills/$skill/references/|g; s|\`references/|\`$DEST/skills/$skill/references/|g")
        fi
        deploy_content "$content" "$dest"
        DESIRED_FILES["$dest"]=1
      fi
      # Deploy steering references into the skills tree (ADR 0009 — progressive load)
      if [[ -d "$SKILLS_DIR/$skill/references" ]]; then
        mkdir -p "$DEST/skills/$skill/references"
        for ref in "$SKILLS_DIR/$skill/references/"*; do
          [[ -f "$ref" ]] || continue
          deploy_file "$ref" "$DEST/skills/$skill/references/$(basename "$ref")"
        done
        STEERING_REF_SKILLS+=("$skill")
      fi
    done

    # Migration (ADR 0009): remove previously-managed refs from the eager dir.
    # Exact names only — everything else in steering/references/ is user-owned.
    for old in project-checks.md tool-limitations.md windows.md unix.md; do
      old_path="$DEST/steering/references/$old"
      if [[ -f "$old_path" && ! -L "$old_path" ]]; then
        rm "$old_path"
        removed=$((removed + 1))
        echo "  pruned: steering/references/$old (moved to skills tree — ADR 0009)"
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

    # Skills: manifest-based prune (ticket 20). Only remove dirs WE deployed
    # (recorded in .crew-skills); unmanaged dirs are warned, never deleted.
    # Incident 2026-07-18: tier-based prune deleted 13 archwright-* skills
    # deployed by another project.
    local manifest="$DEST/.crew-skills"
    local prev_managed=""
    [[ -f "$manifest" ]] && prev_managed=$(cat "$manifest")
    # Retired skill names (compositions/deprecated.yaml) — pruned even when the
    # manifest predates them (pre-manifest machines carry stale copies).
    local deprecated_skills=""
    [[ -f "$ROOT_DIR/compositions/deprecated.yaml" ]] && \
      deprecated_skills=$(yq -r '.skills[].name' "$ROOT_DIR/compositions/deprecated.yaml" 2>/dev/null)
    for d in "$DEST/skills/"*/; do
      [[ -d "$d" ]] || continue
      [[ -L "${d%/}" ]] && { echo "  kept (symlink): skills/$(basename "$d")/"; continue; }
      skill_name=$(basename "$d")
      if printf '%s\n' "${SKILLS[@]}" "${STEERING_REF_SKILLS[@]+"${STEERING_REF_SKILLS[@]}"}" | grep -qx "$skill_name" 2>/dev/null; then
        continue  # in current tier (skill or steering-ref dir) — managed and desired
      fi
      if grep -qx "$skill_name" <<< "$deprecated_skills" 2>/dev/null; then
        replaced=$(yq -r ".skills[] | select(.name == \"$skill_name\") | .replaced_by" "$ROOT_DIR/compositions/deprecated.yaml" 2>/dev/null)
        rm -rf "$d"
        removed=$((removed + 1))
        echo "  pruned: skills/$skill_name/ (deprecated — replaced by: ${replaced:-n/a})"
      elif grep -qx "$skill_name" <<< "$prev_managed" 2>/dev/null; then
        rm -rf "$d"
        removed=$((removed + 1))
        echo "  pruned: skills/$skill_name/ (left the tier)"
      else
        echo "  ⚠️  unmanaged (kept): skills/$skill_name/ — not deployed by crew-research; symlink it to make this explicit"
      fi
    done
    printf '%s\n' "${SKILLS[@]}" "${STEERING_REF_SKILLS[@]+"${STEERING_REF_SKILLS[@]}"}" > "$manifest"

    if [[ -d "$DEST/prompts" ]]; then
      rm -rf "$DEST/prompts"
      echo "  pruned: prompts/ (migrated to skills)"
    fi

    # --- Record deployed tier (doctor.sh reads this for reconciliation) ---
    echo "$TIER" > "$DEST/.crew-tier"

    # --- Deploy permissions.yaml (v3 forward-compatible) ---
    local perms_src="$ROOT_DIR/atomics/eager-context/permissions.yaml"
    if [[ -f "$perms_src" ]]; then
      deploy_file "$perms_src" "$DEST/permissions.yaml"
    fi

    echo ""
    echo "  Steering: ${#STEERING[@]} | Skills: ${#SKILLS[@]}"
    if [[ ${#EXTENSIONS_ACTIVE[@]} -gt 0 ]]; then
      echo "  Extensions: ${EXTENSIONS_ACTIVE[*]}"
    fi
    if [[ ${#EXTENSIONS_SKIPPED[@]} -gt 0 ]]; then
      for skip in "${EXTENSIONS_SKIPPED[@]}"; do
        echo "  ⚠️  Extension skipped: $skip"
      done
    fi
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

    # --- Deploy skills (tier + extensions already merged) ---
    mkdir -p "$skills_dest"

    for skill in "${SKILLS[@]}"; do
      src_dir="$SKILLS_DIR/$skill"
      if [[ -d "$src_dir" ]]; then
        # Skip skills scoped to other tools (metadata.tool / metadata.tools)
        local sk_tool sk_tools
        sk_tool=$(skill_fm_field "$src_dir/SKILL.md" '.metadata.tool // ""')
        sk_tools=$(skill_fm_field "$src_dir/SKILL.md" '.metadata.tools // [] | join(",")')
        [[ -n "$sk_tool" && "$sk_tool" != "$tool_label" ]] && continue
        [[ -n "$sk_tools" && ! "$sk_tools" =~ "$tool_label" ]] && continue
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

    # Collect all steering (tier + extensions already merged)
    local all_steering=("${STEERING[@]}")

    for skill in "${all_steering[@]}"; do
      src="$SKILLS_DIR/$skill/SKILL.md"
      if [[ -f "$src" ]]; then
        # Skip if skill is scoped to tools that don't include this one
        local skill_tool skill_tools
        skill_tool=$(skill_fm_field "$src" '.metadata.tool // ""')
        skill_tools=$(skill_fm_field "$src" '.metadata.tools // [] | join(",")')
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
      -e 's|{{params.crosslink_lint}}|tools/lint/check-crosslinks.sh|g' \
          -e 's|{{params.output_path}}|.scratch/research|g')
        # ADR 0009: deploy steering companion refs to this tool's skills tree
        # and point the rendered links at them (keeps context reachable off-kiro)
        if [[ -d "$SKILLS_DIR/$skill/references" ]]; then
          mkdir -p "$skills_dest/$skill/references"
          local sref
          for sref in "$SKILLS_DIR/$skill/references/"*; do
            [[ -f "$sref" ]] || continue
            deploy_file "$sref" "$skills_dest/$skill/references/$(basename "$sref")"
          done
          DESIRED_SKILLS["$skill"]=1
          body=$(echo "$body" | sed "s|](references/|]($skills_dest/$skill/references/|g; s|\`references/|\`$skills_dest/$skill/references/|g")
        fi
        agents_content+=$'\n'"$body"$'\n'
      fi
    done
    if [[ -f "$agents_md_dest" ]] && printf '%s\n' "$agents_content" | diff -q - "$agents_md_dest" &>/dev/null; then
      unchanged=$((unchanged + 1))
    else
      printf '%s\n' "$agents_content" > "$agents_md_dest"
      updated=$((updated + 1))
    fi

    # --- Prune stale skill dirs (per-tool manifest — codex and agy can share
    # a skills dest with different tool-scoped sets; only prune dirs THIS tool
    # deployed, mirroring the kiro .crew-skills pattern) ---
    local am_manifest="$skills_dest/.crew-skills-$tool_label"
    local am_prev=""
    [[ -f "$am_manifest" ]] && am_prev=$(cat "$am_manifest")
    for d in "$skills_dest/"*/; do
      [[ -d "$d" ]] || continue
      [[ -L "${d%/}" ]] && continue
      skill_name=$(basename "$d")
      if [[ -n "${DESIRED_SKILLS[$skill_name]:-}" ]]; then
        continue
      fi
      if grep -qx "$skill_name" <<< "$am_prev" 2>/dev/null; then
        rm -rf "$d"
        removed=$((removed + 1))
        echo "  pruned: skills/$skill_name/"
      fi
      # not in our manifest → another tool's or unmanaged; keep
    done
    printf '%s\n' "${!DESIRED_SKILLS[@]}" | sort > "$am_manifest"

    echo ""
    echo "  Skills: ${#SKILLS[@]} | Steering → $(basename "$agents_md_dest") (${#STEERING[@]} sections)"
    echo "  $updated updated, $removed pruned, $unchanged unchanged"
    echo ""
  }

  deploy_codex() {
    deploy_agents_md_tool "codex" \
      "$DEPLOY_HOME/.agents/skills" \
      "${CODEX_HOME:-$DEPLOY_HOME/.codex}/AGENTS.md"
  }

  deploy_agy() {
    # Per Google DevRel (June 2026):
    #   Antigravity 2.0 desktop: global = ~/.agents/skills/
    #   Antigravity CLI:          global = ~/.gemini/antigravity-cli/skills/
    #   Both read ~/.gemini/AGENTS.md for steering
    # Deploy skills to both locations; steering to AGENTS.md
    deploy_agents_md_tool "agy" \
      "$DEPLOY_HOME/.agents/skills" \
      "$DEPLOY_HOME/.gemini/AGENTS.md"
    # Also deploy to CLI-specific path
    local cli_dest="$DEPLOY_HOME/.gemini/antigravity-cli/skills"
    mkdir -p "$cli_dest"
    for skill in "${SKILLS[@]}"; do
      src_dir="$SKILLS_DIR/$skill"
      if [[ -d "$src_dir" ]]; then
        # Skip skills scoped to other tools (metadata.tool / metadata.tools)
        local cli_tool cli_tools
        cli_tool=$(skill_fm_field "$src_dir/SKILL.md" '.metadata.tool // ""')
        cli_tools=$(skill_fm_field "$src_dir/SKILL.md" '.metadata.tools // [] | join(",")')
        [[ -n "$cli_tool" && "$cli_tool" != "agy" ]] && continue
        [[ -n "$cli_tools" && ! "$cli_tools" =~ "agy" ]] && continue
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
  elif [[ -f "$PROJECT/package.json" ]]; then
    BUILD_CMD="npm run build"; TEST_CMD="npm test"; LINT_CMD="npm run lint"
    [[ -f "$PROJECT/pnpm-lock.yaml" ]] && { BUILD_CMD="pnpm build"; TEST_CMD="pnpm test"; LINT_CMD="pnpm lint"; }
  elif [[ -f "$PROJECT/pyproject.toml" ]] || [[ -f "$PROJECT/setup.py" ]]; then
    BUILD_CMD=""; TEST_CMD="pytest"; LINT_CMD="ruff check ."
  elif [[ -f "$PROJECT/go.mod" ]]; then
    BUILD_CMD="go build ./..."; TEST_CMD="go test ./..."; LINT_CMD="golangci-lint run"
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
