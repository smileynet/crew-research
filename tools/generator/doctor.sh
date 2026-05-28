#!/bin/bash
# tools/generator/doctor.sh — Health check for a crew-research deployment
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
  local name="$1" min_version="${2:-}"
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

# Check workspace structure
echo ""
echo "Workspace:"
for path in .memory/CONTEXT.md .scratch AGENTS.md; do
  if [[ -e "$PROJECT/$path" ]]; then
    echo "  ✅ $path"
  else
    echo "  ⚠️  $path missing"
    warnings=$((warnings + 1))
  fi
done

# Check .kiro deployment
echo ""
echo "Deployment:"
if [[ -d "$PROJECT/.kiro" ]]; then
  skill_count=$(find "$PROJECT/.kiro/skills" -name "SKILL.md" 2>/dev/null | wc -l || true)
  steering_count=$(find "$PROJECT/.kiro/steering" -name "*.md" 2>/dev/null | wc -l || true)
  prompt_count=$(find "$PROJECT/.kiro/prompts" -name "*.md" 2>/dev/null | wc -l || true)
  agent_count=$(find "$PROJECT/.kiro/agents" -name "*.json" 2>/dev/null | wc -l || true)
  echo "  ✅ $skill_count skills, $steering_count steering, $prompt_count prompts, $agent_count agents"
else
  echo "  ⚠️  No .kiro/ directory (run init first)"
  warnings=$((warnings + 1))
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

# Check CONTEXT.md has content
if [[ -f "$PROJECT/.memory/CONTEXT.md" ]]; then
  lines=$(wc -l < "$PROJECT/.memory/CONTEXT.md")
  if [[ $lines -le 3 ]]; then
    echo "  ⚠️  .memory/CONTEXT.md is empty (add project terms)"
    warnings=$((warnings + 1))
  else
    echo "  ✅ .memory/CONTEXT.md has content ($lines lines)"
  fi
fi

echo ""
echo "---"
echo "Errors: $errors | Warnings: $warnings"
[[ $errors -eq 0 ]] && echo "✅ Healthy" || echo "❌ Fix errors above"
exit $errors
