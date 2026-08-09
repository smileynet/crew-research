#!/usr/bin/env bash
# detect-convention-files.sh — Scan a project for all known AI convention files
# Usage: bash tools/lint/detect-convention-files.sh <project-path>
# Outputs JSON array of found convention files with metadata.
# Exit 0 always (detection, not validation).

set -euo pipefail

PROJECT="${1:-.}"
PROJECT="$(cd "$PROJECT" && pwd)"

# Results accumulator
declare -a RESULTS=()

add_result() {
  local file="$1" tool="$2" scope="$3" format="$4"
  local relpath="${file#"$PROJECT"/}"
  RESULTS+=("{\"file\":\"$relpath\",\"tool\":\"$tool\",\"scope\":\"$scope\",\"format\":\"$format\"}")
}

# AGENTS.md / AGENT.md (root + subdirs, max depth 2)
while IFS= read -r f; do
  if [[ "$f" == "$PROJECT/AGENTS.md" || "$f" == "$PROJECT/AGENT.md" ]]; then
    add_result "$f" "universal" "project-wide" "markdown"
  else
    dir="$(dirname "$f")"
    scope="${dir#"$PROJECT"/}"
    add_result "$f" "universal" "scoped:$scope" "markdown"
  fi
done < <(find "$PROJECT" -maxdepth 3 \( -name "AGENTS.md" -o -name "AGENT.md" \) -not -path "*/.git/*" -not -path "*/node_modules/*" -not -path "*/.references/*" -not -path "*/vendor/*" 2>/dev/null)

# CLAUDE.md (root + subdirs)
while IFS= read -r f; do
  if [[ "$f" == "$PROJECT/CLAUDE.md" ]]; then
    add_result "$f" "claude-code" "project-wide" "markdown"
  else
    dir="$(dirname "$f")"
    scope="${dir#"$PROJECT"/}"
    add_result "$f" "claude-code" "scoped:$scope" "markdown"
  fi
done < <(find "$PROJECT" -maxdepth 3 -name "CLAUDE.md" -not -path "*/.git/*" -not -path "*/node_modules/*" -not -path "*/.references/*" -not -path "*/vendor/*" 2>/dev/null)

# GEMINI.md
while IFS= read -r f; do
  if [[ "$f" == "$PROJECT/GEMINI.md" ]]; then
    add_result "$f" "gemini-cli" "project-wide" "markdown"
  else
    dir="$(dirname "$f")"
    scope="${dir#"$PROJECT"/}"
    add_result "$f" "gemini-cli" "scoped:$scope" "markdown"
  fi
done < <(find "$PROJECT" -maxdepth 3 -name "GEMINI.md" -not -path "*/.git/*" -not -path "*/node_modules/*" -not -path "*/.references/*" -not -path "*/vendor/*" 2>/dev/null)

# .cursorrules (legacy, root only)
if [[ -f "$PROJECT/.cursorrules" ]]; then
  add_result "$PROJECT/.cursorrules" "cursor-legacy" "project-wide" "plaintext"
fi

# .cursor/rules/*.mdc (current Cursor)
if [[ -d "$PROJECT/.cursor/rules" ]]; then
  while IFS= read -r f; do
    add_result "$f" "cursor" "project-wide" "mdc"
  done < <(find "$PROJECT/.cursor/rules" -name "*.mdc" 2>/dev/null)
fi

# .windsurfrules (legacy)
if [[ -f "$PROJECT/.windsurfrules" ]]; then
  add_result "$PROJECT/.windsurfrules" "windsurf-legacy" "project-wide" "plaintext"
fi

# .windsurf/rules/*.md (current Windsurf)
if [[ -d "$PROJECT/.windsurf/rules" ]]; then
  while IFS= read -r f; do
    add_result "$f" "windsurf" "project-wide" "markdown"
  done < <(find "$PROJECT/.windsurf/rules" -name "*.md" 2>/dev/null)
fi

# .github/copilot-instructions.md
if [[ -f "$PROJECT/.github/copilot-instructions.md" ]]; then
  add_result "$PROJECT/.github/copilot-instructions.md" "copilot" "project-wide" "markdown"
fi

# .github/instructions/*.instructions.md (scoped Copilot)
if [[ -d "$PROJECT/.github/instructions" ]]; then
  while IFS= read -r f; do
    add_result "$f" "copilot-scoped" "file-pattern" "markdown"
  done < <(find "$PROJECT/.github/instructions" -name "*.instructions.md" 2>/dev/null)
fi

# .clinerules/*
if [[ -d "$PROJECT/.clinerules" ]]; then
  while IFS= read -r f; do
    add_result "$f" "cline" "project-wide" "markdown"
  done < <(find "$PROJECT/.clinerules" -type f 2>/dev/null)
fi

# .rules/*
if [[ -d "$PROJECT/.rules" ]]; then
  while IFS= read -r f; do
    add_result "$f" "generic" "project-wide" "markdown"
  done < <(find "$PROJECT/.rules" -type f 2>/dev/null)
fi

# .kiro/steering/ (our own — report for completeness)
if [[ -d "$PROJECT/.kiro/steering" ]]; then
  count=$(find "$PROJECT/.kiro/steering" -name "*.md" | wc -l)
  RESULTS+=("{\"file\":\".kiro/steering/ ($count files)\",\"tool\":\"kiro-cli\",\"scope\":\"project-wide\",\"format\":\"markdown+frontmatter\"}")
fi

# Output
echo "["
for i in "${!RESULTS[@]}"; do
  if [[ $i -lt $((${#RESULTS[@]} - 1)) ]]; then
    echo "  ${RESULTS[$i]},"
  else
    echo "  ${RESULTS[$i]}"
  fi
done
echo "]"

# Summary to stderr
echo "" >&2
echo "Found ${#RESULTS[@]} convention file(s) in $PROJECT" >&2
