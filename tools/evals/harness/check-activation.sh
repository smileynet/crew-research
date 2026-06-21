#!/bin/bash
# tools/evals/harness/check-activation.sh — Detect skill activation from agent output
# Usage: ./check-activation.sh <workspace_path> <skill_name>
# Returns: exit 0 if skill was activated, exit 1 if not, exit 2 on error
#
# Detection strategy (in priority order):
# 1. Check captured output file for skill-specific markers
# 2. Check kiro-cli session DB (if available)
# 3. Check workspace for skill-produced artifacts
set -euo pipefail

WORKSPACE="${1:-}"
SKILL_NAME="${2:-}"

if [[ -z "$WORKSPACE" || -z "$SKILL_NAME" ]]; then
  echo "Usage: $0 <workspace_path> <skill_name>" >&2
  exit 2
fi

# --- Strategy 1: Output-based detection (preferred) ---
OUTPUT_FILE="$WORKSPACE/.eval-output"
if [[ -f "$OUTPUT_FILE" ]]; then
  # Skill-specific markers
  case "$SKILL_NAME" in
    recall)
      grep -qi "recall search\|recall prime\|recall add\|Results for:" "$OUTPUT_FILE" && { echo "activated"; exit 0; }
      ;;
    handoff)
      grep -qi "HANDOFF.md\|handoff_key\|session state" "$OUTPUT_FILE" && { echo "activated"; exit 0; }
      ;;
    read-handoff)
      grep -qi "HANDOFF.md\|read.*handoff\|prior session\|last session" "$OUTPUT_FILE" && { echo "activated"; exit 0; }
      ;;
    *)
      # Generic: check if the skill's SKILL.md was read (kiro-cli logs this)
      grep -qi "skills/$SKILL_NAME/SKILL.md" "$OUTPUT_FILE" && { echo "activated"; exit 0; }
      ;;
  esac
fi

# --- Strategy 2: Session DB (legacy, may not exist) ---
DB="$HOME/.local/share/kiro-cli/data.sqlite3"
if [[ -f "$DB" ]] && command -v sqlite3 &>/dev/null; then
  SKILL_DIR="$(cd "$(dirname "$0")/../../.." && pwd)/atomics/skills/$SKILL_NAME"
  MARKER=""
  if [[ -f "$SKILL_DIR/SKILL.md" ]]; then
    MARKER=$(sed -n '/^---$/,/^---$/d; /^#/{p;q}' "$SKILL_DIR/SKILL.md" | head -1)
  fi
  [[ -z "$MARKER" ]] && MARKER="$SKILL_NAME"

  FOUND=$(sqlite3 "$DB" "SELECT value FROM conversations_v2 WHERE key='$WORKSPACE' ORDER BY created_at DESC LIMIT 1" 2>/dev/null | grep -c "$MARKER" || true)
  if [[ "$FOUND" -gt 0 ]]; then
    echo "activated"
    exit 0
  fi
fi

# --- Strategy 3: Artifact-based detection ---
# Check if skill produced expected artifacts
case "$SKILL_NAME" in
  handoff)
    [[ -f "$WORKSPACE/.scratch/HANDOFF.md" ]] && { echo "activated"; exit 0; }
    ;;
  init-project)
    [[ -f "$WORKSPACE/.memory/CONTEXT.md" ]] && { echo "activated"; exit 0; }
    ;;
esac

echo "not_activated"
exit 1
