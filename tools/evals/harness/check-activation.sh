#!/bin/bash
# tools/evals/harness/check-activation.sh — Detect skill activation from agent output
# Usage: ./check-activation.sh <workspace_path> <skill_name>
# Returns: exit 0 if skill was activated, exit 1 if not, exit 2 on error
#
# Detection strategy (in priority order):
# 1. Captured output ($workspace/.eval-output, written by run-activation.sh since
#    ticket 24 — before that this strategy was dead code): skill-specific
#    behavioral markers, else the generic skill-load log line
# 2. kiro-cli session DB fallback: grep the latest conversations_v2 entry for the
#    skill's H1. Fragile (matches anywhere in a large conversation JSON and
#    depends on the DB schema) — kept as fallback only
# 3. Workspace artifacts the skill is expected to produce
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
  # Skill-specific behavioral markers — stronger evidence than a content grep.
  # (recall marker removed: activation-recall def retired, ticket 19.)
  case "$SKILL_NAME" in
    handoff)
      # live def: handoff behavior = writing HANDOFF.md with a handoff_key
      grep -qi "HANDOFF.md\|handoff_key\|session state" "$OUTPUT_FILE" && { echo "activated"; exit 0; }
      ;;
    read-handoff)
      # live def: orientation behavior mentions the handoff file / prior session
      grep -qi "HANDOFF.md\|read.*handoff\|prior session\|last session" "$OUTPUT_FILE" && { echo "activated"; exit 0; }
      ;;
  esac
  # Generic: kiro-cli logs the SKILL.md path when it loads a skill
  grep -qi "skills/$SKILL_NAME/SKILL.md" "$OUTPUT_FILE" && { echo "activated"; exit 0; }
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
