#!/bin/bash
# tools/generator/doctor.sh — Health check for crew-research deployment
# Usage: ./doctor.sh [--project <path>]
set -euo pipefail

PROJECT="${1:-}"
[[ "$PROJECT" == "--project" ]] && PROJECT="${2:-.}"
[[ -z "$PROJECT" ]] && PROJECT="."
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

# Check for unresolved params in global
if grep -r '{{params' ~/.kiro/skills/ 2>/dev/null | grep -q .; then
  echo "  ⚠️  Unresolved {{params}} in global files (re-run global deploy)"
  warnings=$((warnings + 1))
fi

# Check codex deployment (if in CREW_TOOLS)
if printf '%s\n' "${DEPLOYED_TOOLS[@]}" | grep -qx codex; then
  echo ""
  echo "Global (codex):"
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

# Check recall import status
if command -v recall &>/dev/null && [[ -d "$PROJECT/.memory" ]]; then
  mem_files=$(find "$PROJECT/.memory" -name "*.md" | wc -l)
  if [[ $mem_files -gt 0 ]]; then
    imported=$(recall status 2>/dev/null | grep -c "import:" || true)
    wing_name=$(basename "$PROJECT" | tr '-' '_')
    wing_count=$(recall status 2>/dev/null | grep "$wing_name" | grep -oP '\(\K[0-9]+' || echo "0")
    if [[ ${wing_count:-0} -gt 0 ]]; then
      echo "  ✅ recall: $wing_name wing has ${wing_count} chunks"
    else
      echo "  ⚠️  recall: .memory/ has $mem_files files but not imported (run: recall import .memory/ --wing $wing_name)"
      warnings=$((warnings + 1))
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
