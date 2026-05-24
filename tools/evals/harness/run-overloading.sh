#!/bin/bash
# tools/evals/harness/run-overloading.sh — Test skill activation with all skills present
# Measures: does having multiple skills degrade activation accuracy?
# Compares: single-skill activation vs all-skills-present activation
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EVALS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROOFS_DIR="$(cd "$EVALS_DIR/../proofs" && pwd)"
ADAPTERS_DIR="$PROOFS_DIR/adapters"
ATOMICS_DIR="$EVALS_DIR/../../atomics/skills"

ADAPTER_FILE="$ADAPTERS_DIR/kiro-cli.yaml"
INVOKE_NO_AGENT_CMD=$(yq '.invoke.command_no_agent' "$ADAPTER_FILE")
SKILL_LOCATION=$(yq '.skill.location' "$ADAPTER_FILE")
DEFAULT_TIMEOUT=$(yq '.invoke.timeout // 60' "$ADAPTER_FILE")

TIMESTAMP=$(date -u +%Y-%m-%dT%H-%M-%SZ)
RESULTS_DIR="$EVALS_DIR/results/overloading-$TIMESTAMP"
mkdir -p "$RESULTS_DIR"

echo "Overloading experiment: all 5 skills present simultaneously"
echo "Timestamp: $TIMESTAMP"
echo ""

ALL_SKILLS=(five-whys eval-criteria handoff situation-routing verification-protocol)

# Tasks designed to target ONE specific skill
# Format: "target_skill|task_input"
TASKS=(
  "five-whys|The build keeps failing with a cryptic linker error. Why is this happening?"
  "five-whys|Our API latency spiked after the last deploy. Diagnose the root cause."
  "eval-criteria|Write eval criteria for testing whether an agent handles merge conflicts correctly."
  "eval-criteria|Create a scoring rubric for evaluating documentation quality."
  "handoff|Write a handoff document. We refactored the auth module and need to continue tomorrow."
  "handoff|I'm ending my session. Document where things stand for the next developer."
  "situation-routing|Should I fix the flaky test first or implement the new feature the PM is asking for?"
  "situation-routing|I'm not sure whether to use a SQL database or a document store for this. Help me decide."
  "verification-protocol|Add input validation to the signup form and confirm it works."
  "verification-protocol|Fix the null pointer exception in the parser and report done."
)

strip_ansi() { sed 's/\x1B\[[0-9;]*[a-zA-Z]//g'; }

echo "=== Condition A: Single skill present (baseline) ==="
echo ""

SINGLE_RESULTS=()
for task_entry in "${TASKS[@]}"; do
  target="${task_entry%%|*}"
  input="${task_entry#*|}"

  workdir=$(mktemp -d -t "overload-single-XXXX")
  # Deploy ONLY the target skill
  skill_src="$ATOMICS_DIR/$target/SKILL.md"
  skill_dest="$workdir/$(echo "$SKILL_LOCATION" | sed "s/{name}/$target/")"
  mkdir -p "$(dirname "$skill_dest")"
  cp "$skill_src" "$skill_dest"

  # Invoke
  cmd=$(echo "$INVOKE_NO_AGENT_CMD" | sed "s|{query}|$input|")
  cd "$workdir"
  timeout "$DEFAULT_TIMEOUT" bash -c "$cmd" > /dev/null 2>&1 || true

  # Check activation
  activated=false
  if "$SCRIPT_DIR/check-activation.sh" "$workdir" "$target" &>/dev/null; then
    activated=true
  fi

  short="${input:0:55}"
  echo "  [$target] $activated: $short..."
  SINGLE_RESULTS+=("$target|$activated")
  rm -rf "$workdir"
done

echo ""
echo "=== Condition B: All 5 skills present ==="
echo ""

ALL_RESULTS=()
WRONG_SKILL_ACTIVATIONS=()

for task_entry in "${TASKS[@]}"; do
  target="${task_entry%%|*}"
  input="${task_entry#*|}"

  workdir=$(mktemp -d -t "overload-all-XXXX")
  # Deploy ALL skills
  for sk in "${ALL_SKILLS[@]}"; do
    skill_src="$ATOMICS_DIR/$sk/SKILL.md"
    skill_dest="$workdir/$(echo "$SKILL_LOCATION" | sed "s/{name}/$sk/")"
    mkdir -p "$(dirname "$skill_dest")"
    cp "$skill_src" "$skill_dest"
  done

  # Invoke
  cmd=$(echo "$INVOKE_NO_AGENT_CMD" | sed "s|{query}|$input|")
  cd "$workdir"
  timeout "$DEFAULT_TIMEOUT" bash -c "$cmd" > /dev/null 2>&1 || true

  # Check which skills activated
  target_activated=false
  other_activated=()
  for sk in "${ALL_SKILLS[@]}"; do
    if "$SCRIPT_DIR/check-activation.sh" "$workdir" "$sk" &>/dev/null; then
      if [[ "$sk" == "$target" ]]; then
        target_activated=true
      else
        other_activated+=("$sk")
      fi
    fi
  done

  short="${input:0:55}"
  others_str=""
  if [[ ${#other_activated[@]} -gt 0 ]]; then
    others_str=" +[$(IFS=,; echo "${other_activated[*]}")]"
  fi
  echo "  [$target] $target_activated$others_str: $short..."
  ALL_RESULTS+=("$target|$target_activated")
  if [[ ${#other_activated[@]} -gt 0 ]]; then
    WRONG_SKILL_ACTIVATIONS+=("$target|${other_activated[*]}")
  fi

  rm -rf "$workdir"
done

# Compute comparison
echo ""
echo "=== Analysis ==="
echo ""

single_tp=0; all_tp=0; total=${#TASKS[@]}
for i in "${!SINGLE_RESULTS[@]}"; do
  s_act="${SINGLE_RESULTS[$i]#*|}"
  a_act="${ALL_RESULTS[$i]#*|}"
  [[ "$s_act" == "true" ]] && single_tp=$((single_tp + 1))
  [[ "$a_act" == "true" ]] && all_tp=$((all_tp + 1))
done

single_rate=$(echo "scale=2; $single_tp / $total" | bc)
all_rate=$(echo "scale=2; $all_tp / $total" | bc)
degradation=$(echo "scale=2; $single_rate - $all_rate" | bc)

echo "Single-skill activation rate: $single_rate ($single_tp/$total)"
echo "All-skills activation rate:   $all_rate ($all_tp/$total)"
echo "Degradation:                   $degradation"
echo ""

if [[ ${#WRONG_SKILL_ACTIVATIONS[@]} -gt 0 ]]; then
  echo "Cross-activation (wrong skill loaded):"
  for entry in "${WRONG_SKILL_ACTIVATIONS[@]}"; do
    echo "  Target: ${entry%%|*} → Also loaded: ${entry#*|}"
  done
else
  echo "No cross-activation detected."
fi

# Write results
cat > "$RESULTS_DIR/summary.json" << EOF
{
  "timestamp": "$TIMESTAMP",
  "total_tasks": $total,
  "single_skill": {"activation_rate": $single_rate, "activated": $single_tp},
  "all_skills": {"activation_rate": $all_rate, "activated": $all_tp},
  "degradation": $degradation,
  "cross_activations": ${#WRONG_SKILL_ACTIVATIONS[@]}
}
EOF

echo ""
echo "Results: $RESULTS_DIR"
