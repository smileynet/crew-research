#!/bin/bash
# tools/generator/doctor.sh — Health check for crew-research deployment
# Usage: ./doctor.sh [--project <path>] [--tier basic|full]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TIERS_DIR="$ROOT_DIR/compositions/tiers"
SKILLS_DIR="$ROOT_DIR/atomics/skills"

PROJECT="."
TIER=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --project) PROJECT="${2:-.}"; shift 2 ;;
    --tier) TIER="${2:-}"; shift 2 ;;
    *) PROJECT="$1"; shift ;;
  esac
done
PROJECT=$(cd "$PROJECT" && pwd)

# Detect deploy HOME: when running in WSL, tools on Windows read from the
# Windows user home (/mnt/c/Users/$USER), not the WSL home (/home/$USER).
DEPLOY_HOME="$HOME"
if [[ -n "${WSL_DISTRO_NAME:-}" || -f /proc/sys/fs/binfmt_misc/WSLInterop ]]; then
  WIN_USER="${WIN_USERNAME:-}"
  if [[ -z "$WIN_USER" ]]; then
    WIN_USER=$(cmd.exe /C "echo %USERNAME%" 2>/dev/null | tr -d '\r\n') || true
  fi
  if [[ -z "$WIN_USER" ]]; then
    WIN_USER="$USER"
  fi
  if [[ -d "/mnt/c/Users/$WIN_USER" ]]; then
    DEPLOY_HOME="/mnt/c/Users/$WIN_USER"
  fi
fi

echo "Doctor: $PROJECT"
echo ""

errors=0
warnings=0

# Check tools
check_tool() {
  local name="$1"
  if command -v "$name" &>/dev/null; then
    local ver
    ver=$("$name" --version 2>/dev/null | head -1)
    echo "  ✅ $name ($ver)"
  elif [[ -n "${WSL_DISTRO_NAME:-}" || -f /proc/sys/fs/binfmt_misc/WSLInterop ]]; then
    # WSL: tool may be on the Windows side — try interop
    local win_ver
    win_ver=$(cmd.exe /C "$name --version" 2>/dev/null | tr -d '\r' | head -1) || true
    if [[ -n "$win_ver" ]]; then
      echo "  ✅ $name ($win_ver) [Windows]"
    else
      echo "  ❌ $name not found"
      errors=$((errors + 1))
    fi
  else
    echo "  ❌ $name not found"
    errors=$((errors + 1))
  fi
}

# Extension prerequisite check — tools may be installed on the Windows side
# (uv-installed Python tools, native .exe) and not directly reachable from
# WSL or Git Bash. Fallback chain: direct → WSL interop → MSYS2 PowerShell.
_check_prereq() {
  local cmd="$1"
  # Try directly first (works on Linux/macOS/WSL-native and native Windows shells)
  if eval "$cmd" &>/dev/null 2>&1; then
    return 0
  fi
  # WSL: try via Windows interop (covers uv-installed Python tools on Windows)
  if [[ -n "${WSL_DISTRO_NAME:-}" || -f /proc/sys/fs/binfmt_misc/WSLInterop ]]; then
    if cmd.exe /C "$cmd" &>/dev/null 2>&1; then
      return 0
    fi
    if command -v powershell.exe &>/dev/null; then
      if powershell.exe -NoProfile -NonInteractive -Command "$cmd" &>/dev/null 2>&1; then
        return 0
      fi
    fi
  fi
  # On MSYS2/Git Bash: fallback to PowerShell which resolves uv tools correctly
  case "$(uname -s)" in
    MINGW*|MSYS*)
      if command -v powershell.exe &>/dev/null; then
        powershell.exe -NoProfile -NonInteractive -Command "$cmd" &>/dev/null 2>&1
        return $?
      fi
      ;;
  esac
  return 1
}

echo "Tools:"
check_tool kiro-cli
check_tool yq
check_tool jq
if command -v tkt &>/dev/null; then
  echo "  ✅ tkt ($(command -v tkt))"
else
  echo "  ⚠️  tkt not on PATH — ticket workflows fall back to the manual protocol (install: uv tool install -e ./tools/tkt)"
  warnings=$((warnings + 1))
fi

# Determine deployed tools from CREW_TOOLS env (default: kiro-cli)
read -ra DEPLOYED_TOOLS <<< "${CREW_TOOLS:-kiro-cli}"

# Check global deployment
echo ""
echo "Global ($DEPLOY_HOME/.kiro/):"
steering_count=$(find "$DEPLOY_HOME/.kiro/steering" -name "*.md" 2>/dev/null | wc -l || true)
skill_count=$(find "$DEPLOY_HOME/.kiro/skills" -name "SKILL.md" 2>/dev/null | wc -l || true)

if [[ $skill_count -gt 0 ]]; then
  echo "  ✅ $steering_count steering, $skill_count skills"
else
  echo "  ❌ No global deployment (run: mise run init -- --global --tier basic)"
  errors=$((errors + 1))
fi

# --- Known external tools (compositions/known-tools.yaml) ---
# Separately-owned repos that self-deploy skills (symlink convention). Absence
# is pending-with-reason (hydration hint), never silent and never an error.
KNOWN_TOOLS_FILE="$ROOT_DIR/compositions/known-tools.yaml"
if [[ -f "$KNOWN_TOOLS_FILE" ]]; then
  echo ""
  echo "Known tools:"
  kt_count=$(yq -r '.tools | length' "$KNOWN_TOOLS_FILE" 2>/dev/null || echo 0)
  for ((i=0; i<kt_count; i++)); do
    kt_name=$(yq -r ".tools[$i].name" "$KNOWN_TOOLS_FILE")
    kt_glob=$(yq -r ".tools[$i].detect.skill_glob" "$KNOWN_TOOLS_FILE")
    kt_hydrate=$(yq -r ".tools[$i].hydrate" "$KNOWN_TOOLS_FILE")
    kt_found=0; kt_broken=0
    for d in "$DEPLOY_HOME"/.kiro/skills/$kt_glob; do
      [[ -e "$d" || -L "$d" ]] || continue
      kt_found=$((kt_found + 1))
      # Broken symlink = repo moved/deleted after deploy
      [[ -L "$d" && ! -e "$d" ]] && kt_broken=$((kt_broken + 1))
    done
    if [[ $kt_broken -gt 0 ]]; then
      echo "  ⚠️  $kt_name: $kt_broken broken skill symlink(s) — source repo moved? re-hydrate: $kt_hydrate"
      warnings=$((warnings + 1))
    elif [[ $kt_found -gt 0 ]]; then
      echo "  ✅ $kt_name ($kt_found skills, self-deployed)"
    else
      echo "  ○  $kt_name: not hydrated — $kt_hydrate"
    fi
  done
fi

# --- Tier manifest reconciliation ---
# Which tier? --tier flag > deployment marker > best guess by skill count.
if [[ -z "$TIER" ]]; then
  if [[ -f "$DEPLOY_HOME/.kiro/.crew-tier" ]]; then
    TIER=$(cat "$DEPLOY_HOME/.kiro/.crew-tier")
  else
    basic_n=$(yq -r '.skills | length' "$TIERS_DIR/basic.yaml" 2>/dev/null || echo 0)
    [[ $skill_count -gt $basic_n ]] && TIER="full" || TIER="basic"
  fi
fi

if [[ -f "$TIERS_DIR/$TIER.yaml" ]]; then
  echo ""
  echo "Tier reconciliation ($TIER):"
  missing_steering=()
  missing_skills=()

  # Manifest steering must exist as deployed files (skip skills scoped away from kiro-cli)
  while IFS= read -r s; do
    [[ -z "$s" || "$s" == "null" ]] && continue
    tools_scope=$(yq -r '.metadata.tools // [] | join(",")' <(sed -n '/^---$/,/^---$/p' "$SKILLS_DIR/$s/SKILL.md" 2>/dev/null) 2>/dev/null || echo "")
    [[ -n "$tools_scope" && ! "$tools_scope" =~ kiro-cli ]] && continue
    [[ -f "$DEPLOY_HOME/.kiro/steering/$s.md" ]] || missing_steering+=("$s")
  done < <(yq -r '.steering[]' "$TIERS_DIR/$TIER.yaml" 2>/dev/null)

  while IFS= read -r s; do
    [[ -z "$s" || "$s" == "null" ]] && continue
    [[ -f "$DEPLOY_HOME/.kiro/skills/$s/SKILL.md" ]] || missing_skills+=("$s")
  done < <(yq -r '.skills[]' "$TIERS_DIR/$TIER.yaml" 2>/dev/null)

  # Extensions: if the prerequisite passes, its steering/skills must be deployed
  ext_count=$(yq -r '.extensions | length' "$TIERS_DIR/$TIER.yaml" 2>/dev/null || echo 0)
  for ((i=0; i<ext_count; i++)); do
    ext_name=$(yq -r ".extensions[$i].name" "$TIERS_DIR/$TIER.yaml")
    prereq=$(yq -r ".extensions[$i].prerequisite.command" "$TIERS_DIR/$TIER.yaml")
    if _check_prereq "$prereq"; then
      while IFS= read -r s; do
        [[ -z "$s" || "$s" == "null" ]] && continue
        [[ -f "$DEPLOY_HOME/.kiro/steering/$s.md" ]] || missing_steering+=("$s (ext:$ext_name)")
      done < <(yq -r ".extensions[$i].steering[]" "$TIERS_DIR/$TIER.yaml" 2>/dev/null)
      while IFS= read -r s; do
        [[ -z "$s" || "$s" == "null" ]] && continue
        [[ -f "$DEPLOY_HOME/.kiro/skills/$s/SKILL.md" ]] || missing_skills+=("$s (ext:$ext_name)")
      done < <(yq -r ".extensions[$i].skills[]" "$TIERS_DIR/$TIER.yaml" 2>/dev/null)
    else
      echo "  ⚠️  extension '$ext_name' prerequisite not met ($prereq) — its files not expected"
    fi
  done

  if [[ ${#missing_steering[@]} -eq 0 && ${#missing_skills[@]} -eq 0 ]]; then
    echo "  ✅ all $TIER-tier steering + skills deployed"
  else
    for m in "${missing_steering[@]}"; do echo "  ❌ steering missing: $m"; errors=$((errors + 1)); done
    for m in "${missing_skills[@]}"; do echo "  ❌ skill missing: $m"; errors=$((errors + 1)); done
    echo "     fix: mise run init -- --global --tier $TIER"
  fi

  # Unmanaged drift: regular files in $DEPLOY_HOME/.kiro/steering not owned by the tier.
  # init.sh's prune deletes these on the next deploy — symlinks survive.
  expected_steering=$( { yq -r '.steering[]' "$TIERS_DIR/$TIER.yaml"; yq -r '.extensions[].steering[]' "$TIERS_DIR/$TIER.yaml" 2>/dev/null; } 2>/dev/null | grep -v '^null$')
  for f in "$DEPLOY_HOME"/.kiro/steering/*.md; do
    [[ -f "$f" ]] || continue
    [[ -L "$f" ]] && continue
    base=$(basename "$f" .md)
    if ! grep -qx "$base" <<< "$expected_steering"; then
      echo "  ⚠️  unmanaged steering file: $(basename "$f") — next deploy will PRUNE it; convert to a symlink to survive"
      warnings=$((warnings + 1))
    fi
  done

  # Unmanaged skill dirs: kept by init.sh's manifest-based prune (ticket 20),
  # but surfaced here so their ownership is explicit. Symlinks are the
  # recommended convention for other projects deploying into $DEPLOY_HOME/.kiro/skills.
  if [[ -f "$DEPLOY_HOME/.kiro/.crew-skills" ]]; then
    managed_skills=$(cat "$DEPLOY_HOME/.kiro/.crew-skills")
    deprecated_names=$(yq -r '.skills[].name' "$ROOT_DIR/compositions/deprecated.yaml" 2>/dev/null)
    for d in "$DEPLOY_HOME"/.kiro/skills/*/; do
      [[ -d "$d" ]] || continue
      [[ -L "${d%/}" ]] && continue
      sbase=$(basename "$d")
      if grep -qx "$sbase" <<< "$deprecated_names" 2>/dev/null; then
        echo "  ⚠️  deprecated skill dir: skills/$sbase/ — retired name; next deploy will PRUNE it (see compositions/deprecated.yaml)"
        warnings=$((warnings + 1))
      elif ! grep -qx "$sbase" <<< "$managed_skills"; then
        echo "  ⚠️  unmanaged skill dir: skills/$sbase/ — kept by deploys, but consider a symlink to make ownership explicit"
        warnings=$((warnings + 1))
      fi
    done
  fi
fi

# --- Source frontmatter validation (catches skills shipped without frontmatter) ---
echo ""
echo "Skill frontmatter (source):"
fm_bad=0
for skill_md in "$SKILLS_DIR"/*/SKILL.md; do
  [[ -f "$skill_md" ]] || continue
  if [[ "$(head -1 "$skill_md")" != "---" ]]; then
    echo "  ❌ no frontmatter: ${skill_md#$ROOT_DIR/}"
    fm_bad=$((fm_bad + 1)); errors=$((errors + 1))
    continue
  fi
  fm=$(sed -n '/^---$/,/^---$/p' "$skill_md")
  for field in name description; do
    if ! grep -q "^$field:" <<< "$fm"; then
      echo "  ❌ missing '$field': ${skill_md#$ROOT_DIR/}"
      fm_bad=$((fm_bad + 1)); errors=$((errors + 1))
    fi
  done
done
[[ $fm_bad -eq 0 ]] && echo "  ✅ all source skills have frontmatter (name + description)"

# Check for unresolved params in global
if grep -r '{{params' "$DEPLOY_HOME/.kiro/skills/" 2>/dev/null | grep -q .; then
  echo "  ⚠️  Unresolved {{params}} in global files (re-run global deploy)"
  warnings=$((warnings + 1))
fi

# Check codex deployment (if in CREW_TOOLS)
if printf '%s\n' "${DEPLOYED_TOOLS[@]}" | grep -qx codex; then
  echo ""
  echo "Global (codex):"
  check_tool codex
  codex_skills=$(find "$DEPLOY_HOME/.agents/skills" -name "SKILL.md" 2>/dev/null | wc -l || true)
  codex_agents_md="${CODEX_HOME:-$DEPLOY_HOME/.codex}/AGENTS.md"
  if [[ $codex_skills -gt 0 && -f "$codex_agents_md" ]]; then
    echo "  ✅ $codex_skills skills, AGENTS.md present"
  else
    echo "  ❌ Codex not deployed (run: mise run init -- --global)"
    errors=$((errors + 1))
  fi
fi

# Policy check (ticket 36): on corp machines agy artifacts are violations —
# always checked, regardless of what CREW_TOOLS declares
if [[ "${CREW_ENV:-}" == "corp" ]]; then
  agy_violations=()
  command -v agy &>/dev/null && agy_violations+=("agy binary on PATH ($(command -v agy))")
  [[ -d "$DEPLOY_HOME/.gemini" ]] && agy_violations+=("~/.gemini/ exists")
  [[ -f "$DEPLOY_HOME/.agents/skills/.crew-skills-agy" ]] && agy_violations+=("~/.agents/skills/.crew-skills-agy manifest")
  if [[ ${#agy_violations[@]} -gt 0 ]]; then
    echo ""
    echo "Policy (CREW_ENV=corp):"
    for v in "${agy_violations[@]}"; do
      echo "  ❌ POLICY VIOLATION: $v — agy is forbidden on corp machines (company policy); remove it"
      errors=$((errors + 1))
    done
  fi
fi

# Check agy deployment (if in CREW_TOOLS)
if printf '%s\n' "${DEPLOYED_TOOLS[@]}" | grep -qx agy; then  echo ""
  echo "Global (agy):"
  check_tool agy
  agy_desktop_skills=$(find "$DEPLOY_HOME/.agents/skills" -name "SKILL.md" 2>/dev/null | wc -l || true)
  agy_cli_skills=$(find "$DEPLOY_HOME/.gemini/antigravity-cli/skills" -name "SKILL.md" 2>/dev/null | wc -l || true)
  if [[ $agy_desktop_skills -gt 0 && -f "$DEPLOY_HOME/.gemini/AGENTS.md" ]]; then
    echo "  ✅ $agy_desktop_skills skills (~/.agents/skills), $agy_cli_skills skills (CLI), AGENTS.md present"
  else
    echo "  ❌ agy not fully deployed (run: mise run init -- --global)"
    [[ $agy_desktop_skills -eq 0 ]] && echo "     missing: $DEPLOY_HOME/.agents/skills/"
    [[ ! -f "$DEPLOY_HOME/.gemini/AGENTS.md" ]] && echo "     missing: $DEPLOY_HOME/.gemini/AGENTS.md"
    errors=$((errors + 1))
  fi
fi

# Check crush deployment (if in CREW_TOOLS)
# Note: crush shares ~/.agents/skills with codex; steering at ~/.config/crush/AGENTS.md
if printf '%s\n' "${DEPLOYED_TOOLS[@]}" | grep -qx crush; then
  echo ""
  echo "Global (crush):"
  crush_skills=$(find "$DEPLOY_HOME/.agents/skills" -name "SKILL.md" 2>/dev/null | wc -l || true)
  crush_agents_md="${CRUSH_HOME:-$DEPLOY_HOME/.config/crush}/AGENTS.md"
  if [[ $crush_skills -gt 0 && -f "$crush_agents_md" ]]; then
    echo "  ✅ $crush_skills skills (~/.agents/skills), AGENTS.md present"
  else
    echo "  ❌ crush not fully deployed (run: mise run init -- --global)"
    [[ $crush_skills -eq 0 ]] && echo "     missing: ~/.agents/skills/"
    [[ ! -f "$crush_agents_md" ]] && echo "     missing: $crush_agents_md"
    errors=$((errors + 1))
  fi
fi

# Check project workspace
echo ""
echo "Project:"
for path in .memory/CONTEXT.md .scratch AGENTS.md; do
  if [[ -e "$PROJECT/$path" ]]; then
    echo "  ✅ $path"
  else
    echo "  ⚠️  $path missing (run: mise run init -- --project $PROJECT)"
    warnings=$((warnings + 1))
  fi
done

# Check CONTEXT.md has content
if [[ -f "$PROJECT/.memory/CONTEXT.md" ]]; then
  lines=$(wc -l < "$PROJECT/.memory/CONTEXT.md")
  if [[ $lines -le 3 ]]; then
    echo "  ⚠️  .memory/CONTEXT.md is empty (add project terms)"
    warnings=$((warnings + 1))
  fi
fi

# Check .gitignore
echo ""
echo "Hygiene:"
if [[ -f "$PROJECT/.gitignore" ]] && grep -q '.scratch/' "$PROJECT/.gitignore" 2>/dev/null; then
  echo "  ✅ .scratch/ in .gitignore"
else
  echo "  ⚠️  .scratch/ not in .gitignore"
  warnings=$((warnings + 1))
fi

# Check recall import status + ingest freshness
if command -v recall &>/dev/null; then
  echo ""
  echo "Recall:"
  # Detect Python recall (deprecated) vs Rust recall
  recall_path=$(command -v recall)
  if [[ "$recall_path" == *"uv/tools"* || "$recall_path" == *".local/share/uv"* ]]; then
    echo "  ⚠️  Python recall detected (uv-installed) — deprecated"
    echo "     Migrate: uv tool uninstall recall && cargo install --path ~/code/recall"
    echo "     The Rust binary is fully compatible (same database, same commands)."
    warnings=$((warnings + 1))
  fi
  # On MSYS2/Git Bash, uv-installed Python tools can't resolve their venv —
  # use PowerShell fallback. On WSL, recall lives on the Windows side —
  # use cmd.exe/powershell.exe interop.
  # Note: || true prevents set -e from killing the script on recall failure.
  health_json=$(recall health --json 2>/dev/null) || true
  if [[ -z "$health_json" ]]; then
    if [[ -n "${WSL_DISTRO_NAME:-}" || -f /proc/sys/fs/binfmt_misc/WSLInterop ]]; then
      health_json=$(cmd.exe /C "recall health --json" 2>/dev/null | tr -d '\r') || true
      if [[ -z "$health_json" ]] && command -v powershell.exe &>/dev/null; then
        health_json=$(powershell.exe -NoProfile -NonInteractive -Command "recall health --json" 2>/dev/null | tr -d '\r') || true
      fi
    else
      case "$(uname -s)" in
        MINGW*|MSYS*)
          if command -v powershell.exe &>/dev/null; then
            health_json=$(MSYS_NO_PATHCONV=1 powershell.exe -NoProfile -NonInteractive -Command "recall health --json" 2>/dev/null | tr -d '\r') || true
          fi
          ;;
      esac
    fi
  fi

  if [[ -n "$health_json" ]] && echo "$health_json" | jq empty 2>/dev/null; then
    total_chunks=$(echo "$health_json" | jq -r '.total_chunks')
    import_chunks=$(echo "$health_json" | jq -r '.import_chunks')
    session_chunks=$(echo "$health_json" | jq -r '.session_chunks')
    wing_count=$(echo "$health_json" | jq -r '.wing_count')
    covered=$(echo "$health_json" | jq -r '.covered_projects')
    discoverable=$(echo "$health_json" | jq -r '.discoverable_projects')
    last_ingest_ts=$(echo "$health_json" | jq -r '.last_ingest_ts // empty')
    duplicates=$(echo "$health_json" | jq -r '.duplicates | length')
    missing_list=$(echo "$health_json" | jq -r '.missing_projects[]' 2>/dev/null)

    # Overall health summary
    echo "  ✅ ${total_chunks} chunks (${import_chunks} import, ${session_chunks} session), ${wing_count} wings"

    # Import coverage check
    if [[ "$covered" -eq "$discoverable" && "$discoverable" -gt 0 ]]; then
      echo "  ✅ import coverage: ${covered}/${discoverable} projects"
    elif [[ "$discoverable" -eq 0 ]]; then
      echo "  ⚠️  no discoverable projects found"
      warnings=$((warnings + 1))
    else
      echo "  ⚠️  import coverage gap: ${covered}/${discoverable} projects imported"
      # Show up to 5 missing
      echo "$missing_list" | head -5 | while IFS= read -r m; do
        [[ -n "$m" ]] && echo "     missing: $m"
      done
      missing_n=$(echo "$missing_list" | wc -l)
      [[ $missing_n -gt 5 ]] && echo "     (+$((missing_n - 5)) more)"
      warnings=$((warnings + 1))
    fi

    # Duplicate/split wing detection
    if [[ "$duplicates" -gt 0 ]]; then
      dup_detail=$(echo "$health_json" | jq -r '.duplicates[] | join(", ")')
      echo "  ⚠️  wing duplicates detected (hyphen/underscore split):"
      echo "$dup_detail" | while IFS= read -r d; do echo "     $d"; done
      warnings=$((warnings + 1))
    fi

    # Ingest freshness
    if [[ -n "$last_ingest_ts" ]]; then
      now=$(date +%s)
      age_h=$(( (now - last_ingest_ts) / 3600 ))
      if [[ $age_h -gt 24 ]]; then
        echo "  ⚠️  ingest stale (${age_h}h old — run: recall ingest ~/.kiro/sessions/cli)"
        warnings=$((warnings + 1))
      else
        echo "  ✅ ingest fresh (${age_h}h old)"
      fi
    else
      echo "  ⚠️  recall never ingested (run: recall ingest ~/.kiro/sessions/cli)"
      warnings=$((warnings + 1))
    fi

    # Cron / scheduled task check
    if [[ "$(uname -s)" == "Linux" || "$(uname -s)" == "Darwin" ]]; then
      if ! crontab -l 2>/dev/null | grep -q "recall"; then
        echo "  ⚠️  no cron entry for recall (memory goes stale without scheduled ingestion)"
        warnings=$((warnings + 1))
      fi
    fi

    # Current project wing check
    if [[ -d "$PROJECT/.memory" ]]; then
      wing_name=$(basename "$PROJECT" | tr '-' '_')
      wing_chunks=$(echo "$health_json" | jq -r ".wings.\"$wing_name\" // 0")
      if [[ "$wing_chunks" -gt 0 ]]; then
        echo "  ✅ project wing '$wing_name': ${wing_chunks} chunks"
      else
        echo "  ⚠️  project .memory/ not imported (run: recall import .memory/ --wing $wing_name)"
        warnings=$((warnings + 1))
      fi
    fi
  else
    echo "  ⚠️  recall health --json failed (recall may need upgrade)"
    warnings=$((warnings + 1))
  fi
fi

# Check for project-level overrides
if [[ -d "$PROJECT/.kiro/steering" ]]; then
  local_steering=$(ls "$PROJECT/.kiro/steering/"*.md 2>/dev/null | wc -l || true)
  echo "  ✅ $local_steering project-specific steering override(s)"
fi

# Warn if local prompts/ shadows global skills
if [[ -d "$PROJECT/.kiro/prompts" ]] && ls "$PROJECT/.kiro/prompts/"*.md &>/dev/null 2>&1; then
  local_prompts=$(ls "$PROJECT/.kiro/prompts/"*.md 2>/dev/null | wc -l)
  echo "  ⚠️  $local_prompts local prompt file(s) in .kiro/prompts/ — these shadow global skills (no descriptions in picker)"
  warnings=$((warnings + 1))
fi

echo ""
echo "---"
echo "Errors: $errors | Warnings: $warnings"
[[ $errors -eq 0 ]] && echo "✅ Healthy" || echo "❌ Fix errors above"
exit $errors
