#!/bin/bash
# tools/evals/harness/check-activation.sh — Detect skill activation from kiro-cli session data
# Usage: ./check-activation.sh <workspace_path> <skill_name>
# Returns: exit 0 if skill was activated, exit 1 if not, exit 2 on error
set -euo pipefail

WORKSPACE="${1:-}"
SKILL_NAME="${2:-}"
DB="$HOME/.local/share/kiro-cli/data.sqlite3"

if [[ -z "$WORKSPACE" || -z "$SKILL_NAME" ]]; then
  echo "Usage: $0 <workspace_path> <skill_name>" >&2
  exit 2
fi

if [[ ! -f "$DB" ]]; then
  echo "error: database not found: $DB" >&2
  exit 2
fi

# Get the skill's unique content marker (first non-frontmatter line of SKILL.md)
SKILL_DIR="$(cd "$(dirname "$0")/../../.." && pwd)/atomics/skills/$SKILL_NAME"
if [[ -f "$SKILL_DIR/SKILL.md" ]]; then
  # Extract a unique content marker from the skill (first heading or first substantive line)
  MARKER=$(sed -n '/^---$/,/^---$/d; /^#/{p;q}' "$SKILL_DIR/SKILL.md" | head -1)
  if [[ -z "$MARKER" ]]; then
    MARKER=$(sed -n '/^---$/,/^---$/d; /^$/d; /^#/!{p;q}' "$SKILL_DIR/SKILL.md")
  fi
else
  # Fallback: use skill name as marker
  MARKER="$SKILL_NAME"
fi

# Query sqlite for the conversation from this workspace
FOUND=$(sqlite3 "$DB" "SELECT value FROM conversations_v2 WHERE key='$WORKSPACE' ORDER BY created_at DESC LIMIT 1" 2>/dev/null | grep -c "$MARKER" || true)

if [[ "$FOUND" -gt 0 ]]; then
  echo "activated"
  exit 0
else
  echo "not_activated"
  exit 1
fi
