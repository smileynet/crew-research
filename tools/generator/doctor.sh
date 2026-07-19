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

echo "Doctor: $PROJECT"
echo ""

errors=0
warnings=0

# Check tools
check_tool() {
  local name="$1"
  if command -v "$name" &>/dev/null; then
    ver=$($name --version 2>/dev/null | head -1)
    echo "  ✅ $name ($ver)"
  else
    echo "  ❌ $name not found"
    errors=$((errors + 1))
  fi
}

echo "Tools:"
check_tool kiro-cli
check_tool yq
check_tool jq

# Determine deployed tools from CREW_TOOLS env (default: kiro-cli)
read -ra DEPLOYED_TOOLS <<< "${CREW_TOOLS:-kiro-cli}"

# Check global deployment
echo ""
echo "Global (~/.kiro/):"
steering_count=$(find ~/.kiro/steering -name "*.md" 2>/dev/null | wc -l || true)
skill_count=$(find ~/.kiro/skills -name "SKILL.md" 2>/dev/null | wc -l || true)

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
    for d in ~/.kiro/skills/$kt_glob; do
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
  if [[ -f ~/.kiro/.crew-tier ]]; then
    TIER=$(cat ~/.kiro/.crew-tier)
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
    [[ -f ~/.kiro/steering/"$s".md ]] || missing_steering+=("$s")
  done < <(yq -r '.steering[]' "$TIERS_DIR/$TIER.yaml" 2>/dev/null)

  while IFS= read -r s; do
    [[ -z "$s" || "$s" == "null" ]] && continue
    [[ -f ~/.kiro/skills/"$s"/SKILL.md ]] || missing_skills+=("$s")
  done < <(yq -r '.skills[]' "$TIERS_DIR/$TIER.yaml" 2>/dev/null)

  # Extensions: if the prerequisite passes, its steering/skills must be deployed
  ext_count=$(yq -r '.extensions | length' "$TIERS_DIR/$TIER.yaml" 2>/dev/null || echo 0)
  for ((i=0; i<ext_count; i++)); do
    ext_name=$(yq -r ".extensions[$i].name" "$TIERS_DIR/$TIER.yaml")
    prereq=$(yq -r ".extensions[$i].prerequisite.command" "$TIERS_DIR/$TIER.yaml")
    if eval "$prereq" &>/dev/null; then
      while IFS= read -r s; do
        [[ -z "$s" || "$s" == "null" ]] && continue
        [[ -f ~/.kiro/steering/"$s".md ]] || missing_steering+=("$s (ext:$ext_name)")
      done < <(yq -r ".extensions[$i].steering[]" "$TIERS_DIR/$TIER.yaml" 2>/dev/null)
      while IFS= read -r s; do
        [[ -z "$s" || "$s" == "null" ]] && continue
        [[ -f ~/.kiro/skills/"$s"/SKILL.md ]] || missing_skills+=("$s (ext:$ext_name)")
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

  # Unmanaged drift: regular files in ~/.kiro/steering not owned by the tier.
  # init.sh's prune deletes these on the next deploy — symlinks survive.
  expected_steering=$( { yq -r '.steering[]' "$TIERS_DIR/$TIER.yaml"; yq -r '.extensions[].steering[]' "$TIERS_DIR/$TIER.yaml" 2>/dev/null; } 2>/dev/null | grep -v '^null$')
  for f in ~/.kiro/steering/*.md; do
    [[ -f "$f" ]] || continue
    [[ -L "$f" ]] && continue
    base=$(basename "$f" .md)
    if ! grep -qx "$base" <<< "$expected_steering"; then
      echo "  ⚠️  unmanaged steering file: $(basename "$f") — next deploy will PRUNE it; convert to a symlink to survive (ln -sf <source> ~/.kiro/steering/$(basename "$f"))"
      warnings=$((warnings + 1))
    fi
  done

  # Unmanaged skill dirs: kept by init.sh's manifest-based prune (ticket 20),
  # but surfaced here so their ownership is explicit. Symlinks are the
  # recommended convention for other projects deploying into ~/.kiro/skills.
  if [[ -f ~/.kiro/.crew-skills ]]; then
    managed_skills=$(cat ~/.kiro/.crew-skills)
    deprecated_names=$(yq -r '.skills[].name' "$ROOT_DIR/compositions/deprecated.yaml" 2>/dev/null)
    for d in ~/.kiro/skills/*/; do
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
if grep -r '{{params' ~/.kiro/skills/ 2>/dev/null | grep -q .; then
  echo "  ⚠️  Unresolved {{params}} in global files (re-run global deploy)"
  warnings=$((warnings + 1))
fi

# Check codex deployment (if in CREW_TOOLS)
if printf '%s\n' "${DEPLOYED_TOOLS[@]}" | grep -qx codex; then
  echo ""
  echo "Global (codex):"
  check_tool codex
  codex_skills=$(find ~/.agents/skills -name "SKILL.md" 2>/dev/null | wc -l || true)
  codex_agents_md="${CODEX_HOME:-$HOME/.codex}/AGENTS.md"
  if [[ $codex_skills -gt 0 && -f "$codex_agents_md" ]]; then
    echo "  ✅ $codex_skills skills, AGENTS.md present"
  else
    echo "  ❌ Codex not deployed (run: mise run init -- --global)"
    errors=$((errors + 1))
  fi
fi

# Check agy deployment (if in CREW_TOOLS)
if printf '%s\n' "${DEPLOYED_TOOLS[@]}" | grep -qx agy; then
  echo ""
  echo "Global (agy):"
  check_tool agy
  agy_desktop_skills=$(find ~/.agents/skills -name "SKILL.md" 2>/dev/null | wc -l || true)
  agy_cli_skills=$(find ~/.gemini/antigravity-cli/skills -name "SKILL.md" 2>/dev/null | wc -l || true)
  if [[ $agy_desktop_skills -gt 0 && -f "$HOME/.gemini/AGENTS.md" ]]; then
    echo "  ✅ $agy_desktop_skills skills (~/.agents/skills), $agy_cli_skills skills (CLI), AGENTS.md present"
  else
    echo "  ❌ agy not fully deployed (run: mise run init -- --global)"
    [[ $agy_desktop_skills -eq 0 ]] && echo "     missing: ~/.agents/skills/"
    [[ ! -f "$HOME/.gemini/AGENTS.md" ]] && echo "     missing: ~/.gemini/AGENTS.md"
    errors=$((errors + 1))
  fi
fi

# Check crush deployment (if in CREW_TOOLS)
# Note: crush shares ~/.agents/skills with codex; steering at ~/.config/crush/AGENTS.md
if printf '%s\n' "${DEPLOYED_TOOLS[@]}" | grep -qx crush; then
  echo ""
  echo "Global (crush):"
  crush_skills=$(find ~/.agents/skills -name "SKILL.md" 2>/dev/null | wc -l || true)
  crush_agents_md="${CRUSH_HOME:-$HOME/.config/crush}/AGENTS.md"
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
  # Ingest staleness: recall-session-start steering depends on <24h-old ingest
  if [[ -f ~/.recall/last_ingest ]]; then
    now=$(date +%s)
    ingest_mtime=$(stat -c %Y ~/.recall/last_ingest 2>/dev/null || stat -f %m ~/.recall/last_ingest 2>/dev/null || echo 0)
    age_h=$(( (now - ingest_mtime) / 3600 ))
    if [[ $age_h -gt 24 ]]; then
      echo "  ⚠️  recall ingest stale (${age_h}h old — run: recall ingest ~/.kiro/sessions/cli)"
      warnings=$((warnings + 1))
    else
      echo "  ✅ recall ingest fresh (${age_h}h old)"
    fi
  else
    echo "  ⚠️  recall never ingested (~/.recall/last_ingest missing — run: recall ingest ~/.kiro/sessions/cli)"
    warnings=$((warnings + 1))
  fi
  if ! crontab -l 2>/dev/null | grep -q "recall ingest"; then
    echo "  ⚠️  no cron entry for recall ingest (memory goes stale without it)"
    warnings=$((warnings + 1))
  fi

  if [[ -d "$PROJECT/.memory" ]]; then
    mem_files=$(find "$PROJECT/.memory" -name "*.md" | wc -l)
    if [[ $mem_files -gt 0 ]]; then
      wing_name=$(basename "$PROJECT" | tr '-' '_')
      wing_count=$(recall status 2>/dev/null | grep "$wing_name" | sed -n 's/.*(\([0-9][0-9]*\)).*/\1/p' | head -1)
      if [[ ${wing_count:-0} -gt 0 ]]; then
        echo "  ✅ recall: $wing_name wing has ${wing_count} chunks"
      else
        echo "  ⚠️  recall: .memory/ has $mem_files files but not imported (run: recall import .memory/ --wing $wing_name)"
        warnings=$((warnings + 1))
      fi
    fi
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
