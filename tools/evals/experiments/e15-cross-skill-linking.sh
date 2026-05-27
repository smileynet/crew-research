#!/bin/bash
# tools/evals/experiments/e15-cross-skill-linking.sh
# Tests whether cross-skill markdown links trigger progressive loading
# Usage: ./e15-cross-skill-linking.sh --condition <baseline|link|mention|companion>
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EVALS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd "$EVALS_DIR/../.." && pwd)"
SKILLS_DIR="$ROOT_DIR/atomics/skills"
RESULTS_DIR="$EVALS_DIR/results"
CHECK_ACTIVATION="$EVALS_DIR/harness/check-activation.sh"

CONDITION="${1:-}"
[[ "$CONDITION" == "--condition" ]] && CONDITION="${2:-}"
[[ -n "$CONDITION" ]] || { echo "Usage: $0 --condition <baseline|link|mention|companion>"; exit 1; }

HOST_SKILL="script-authoring"
TARGET_SKILL="ai-generation-hygiene"
TIMEOUT=60

# Tasks that activate script-authoring (100%) but NOT ai-generation-hygiene (20%)
TASKS=(
  "Write a bash script to back up the database and rotate old backups."
  "Create a CLI utility that processes CSV files and outputs JSON."
  "Write an automation script to set up the development environment."
  "Create a helper script for running the test suite with different configurations."
  "Write a deployment script that handles rollback on failure."
)

TIMESTAMP=$(date -u +%Y-%m-%dT%H-%M-%SZ)
RUN_DIR="$RESULTS_DIR/e15-$CONDITION-$TIMESTAMP"
mkdir -p "$RUN_DIR"

echo "E15: Cross-skill linking | condition=$CONDITION | $TIMESTAMP"
echo ""

HOST_ACTIVATED=0
TARGET_ACTIVATED=0
TOTAL=${#TASKS[@]}

for task in "${TASKS[@]}"; do
  workdir=$(mktemp -d -t "e15-XXXX")

  # Deploy host skill
  host_dest="$workdir/.kiro/skills/$HOST_SKILL/SKILL.md"
  mkdir -p "$(dirname "$host_dest")"

  case "$CONDITION" in
    baseline)
      # Deploy host skill as-is
      cp "$SKILLS_DIR/$HOST_SKILL/SKILL.md" "$host_dest"
      ;;
    link)
      # Add a markdown link to target skill at end of host
      cp "$SKILLS_DIR/$HOST_SKILL/SKILL.md" "$host_dest"
      echo "" >> "$host_dest"
      echo "## Code Quality" >> "$host_dest"
      echo "Before finalizing, review output against [AI generation hygiene rules](../ai-generation-hygiene/SKILL.md) to eliminate common artifacts." >> "$host_dest"
      ;;
    mention)
      # Add inline text mention (no link) at end of host
      cp "$SKILLS_DIR/$HOST_SKILL/SKILL.md" "$host_dest"
      echo "" >> "$host_dest"
      echo "## Code Quality" >> "$host_dest"
      echo "Before finalizing, check for AI generation hygiene: no redundant defensive checks, no gratuitous logging, no restating comments, no unnecessary casts." >> "$host_dest"
      ;;
    companion)
      # Add a companion file in host's directory with target content
      cp "$SKILLS_DIR/$HOST_SKILL/SKILL.md" "$host_dest"
      echo "" >> "$host_dest"
      echo "## Code Quality" >> "$host_dest"
      echo "See [code hygiene rules](references/code-hygiene.md) for common AI generation artifacts to avoid." >> "$host_dest"
      mkdir -p "$(dirname "$host_dest")/references"
      cp "$SKILLS_DIR/$TARGET_SKILL/SKILL.md" "$(dirname "$host_dest")/references/code-hygiene.md"
      ;;
    *)
      echo "Unknown condition: $CONDITION" >&2; exit 1
      ;;
  esac

  # Deploy target skill (always present — we're testing if it gets LOADED, not if it's available)
  target_dest="$workdir/.kiro/skills/$TARGET_SKILL/SKILL.md"
  mkdir -p "$(dirname "$target_dest")"
  cp "$SKILLS_DIR/$TARGET_SKILL/SKILL.md" "$target_dest"

  # Run task
  cd "$workdir"
  timeout "$TIMEOUT" kiro-cli chat --no-interactive -a "$task" > /dev/null 2>&1 || true

  # Check activations
  host_act=false
  target_act=false
  "$CHECK_ACTIVATION" "$workdir" "$HOST_SKILL" &>/dev/null && host_act=true
  "$CHECK_ACTIVATION" "$workdir" "$TARGET_SKILL" &>/dev/null && target_act=true

  [[ "$host_act" == "true" ]] && HOST_ACTIVATED=$((HOST_ACTIVATED + 1))
  [[ "$target_act" == "true" ]] && TARGET_ACTIVATED=$((TARGET_ACTIVATED + 1))

  short="${task:0:60}"
  echo "  host=$host_act target=$target_act | $short..."
  echo "{\"condition\":\"$CONDITION\",\"task\":\"$short\",\"host_activated\":$host_act,\"target_activated\":$target_act}" >> "$RUN_DIR/results.jsonl"

  rm -rf "$workdir"
done

HOST_RATE=$(echo "scale=2; $HOST_ACTIVATED / $TOTAL" | bc)
TARGET_RATE=$(echo "scale=2; $TARGET_ACTIVATED / $TOTAL" | bc)

echo ""
echo "---"
echo "Host ($HOST_SKILL) activation: $HOST_ACTIVATED/$TOTAL ($HOST_RATE)"
echo "Target ($TARGET_SKILL) activation: $TARGET_ACTIVATED/$TOTAL ($TARGET_RATE)"
echo "Condition: $CONDITION"

cat > "$RUN_DIR/summary.json" << EOF
{
  "timestamp": "$TIMESTAMP",
  "condition": "$CONDITION",
  "host_skill": "$HOST_SKILL",
  "target_skill": "$TARGET_SKILL",
  "total_tasks": $TOTAL,
  "host_activated": $HOST_ACTIVATED,
  "target_activated": $TARGET_ACTIVATED,
  "host_rate": $HOST_RATE,
  "target_rate": $TARGET_RATE
}
EOF

echo "Results: $RUN_DIR"
