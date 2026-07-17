#!/bin/bash
# tools/evals/harness/run-activation.sh — Lightweight activation-only test runner
# Tests whether skills activate on relevant tasks and don't activate on irrelevant tasks
# Usage: ./run-activation.sh [--definition name] [--all] [--adapter kiro-cli]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EVALS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROOFS_DIR="$(cd "$EVALS_DIR/../proofs" && pwd)"
ADAPTERS_DIR="$PROOFS_DIR/adapters"
DEFINITIONS_DIR="$EVALS_DIR/definitions"
RESULTS_DIR="$EVALS_DIR/results"

ADAPTER="kiro-cli"
DEFINITION=""
RUN_ALL=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --adapter) ADAPTER="$2"; shift 2 ;;
    --definition) DEFINITION="$2"; shift 2 ;;
    --all) RUN_ALL=true; shift ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

for cmd in yq sqlite3; do
  command -v "$cmd" &>/dev/null || { echo "Error: $cmd required" >&2; exit 2; }
done

ADAPTER_FILE="$ADAPTERS_DIR/$ADAPTER.yaml"
[[ -f "$ADAPTER_FILE" ]] || { echo "Error: adapter not found" >&2; exit 2; }

TOOL_NAME=$(yq '.tool' "$ADAPTER_FILE")
INVOKE_NO_AGENT_CMD=$(yq '.invoke.command_no_agent' "$ADAPTER_FILE")
SKILL_LOCATION=$(yq '.skill.location' "$ADAPTER_FILE")
DEFAULT_TIMEOUT=$(yq '.invoke.timeout // 60' "$ADAPTER_FILE")

TIMESTAMP=$(date -u +%Y-%m-%dT%H-%M-%SZ)
echo "Activation test: $TOOL_NAME | $TIMESTAMP"
echo ""

# Collect definitions (only activation-* ones)
DEFS=()
if [[ -n "$DEFINITION" ]]; then
  DEFS=("$DEFINITIONS_DIR/$DEFINITION.yaml")
elif [[ "$RUN_ALL" == true ]]; then
  mapfile -t DEFS < <(find "$DEFINITIONS_DIR" -name "activation-*.yaml" | sort)
fi

[[ ${#DEFS[@]} -gt 0 ]] || { echo "No activation definitions found." >&2; exit 1; }

RUN_DIR="$RESULTS_DIR/activation-$TIMESTAMP"
mkdir -p "$RUN_DIR"
RESULTS_FILE="$RUN_DIR/activation.jsonl"
: > "$RESULTS_FILE"

strip_ansi() { sed 's/\x1B\[[0-9;]*[a-zA-Z]//g'; }

TP=0; FP=0; TN=0; FN=0

for def_file in "${DEFS[@]}"; do
  [[ -f "$def_file" ]] || continue
  local_name=$(yq '.name' "$def_file")
  skill=$(yq '.skill' "$def_file")
  task_count=$(yq '.tasks | length' "$def_file")

  echo "  $local_name ($skill) — $task_count tasks"

  for i in $(seq 0 $((task_count - 1))); do
    input=$(yq ".tasks[$i].input" "$def_file")
    expect=$(yq ".tasks[$i].expect_activation" "$def_file")

    # Create workspace with skill deployed
    workdir=$(mktemp -d -t "act-${skill}-XXXX")
    skill_src="$EVALS_DIR/../../atomics/skills/$skill/SKILL.md"
    if [[ -f "$skill_src" ]]; then
      skill_dest="$workdir/$(echo "$SKILL_LOCATION" | sed "s/{name}/$skill/")"
      mkdir -p "$(dirname "$skill_dest")"
      cp "$skill_src" "$skill_dest"
    fi

    # Invoke agent
    cmd=$(echo "$INVOKE_NO_AGENT_CMD" | sed "s|{query}|$input|")
    cd "$workdir"
    timeout "$DEFAULT_TIMEOUT" bash -c "$cmd" > /dev/null 2>&1 || true

    # Check activation
    activated=false
    if "$SCRIPT_DIR/check-activation.sh" "$workdir" "$skill" &>/dev/null; then
      activated=true
    fi

    # Score
    if [[ "$expect" == "true" && "$activated" == "true" ]]; then
      result="TP"; TP=$((TP + 1))
    elif [[ "$expect" == "true" && "$activated" == "false" ]]; then
      result="FN"; FN=$((FN + 1))
    elif [[ "$expect" == "false" && "$activated" == "false" ]]; then
      result="TN"; TN=$((TN + 1))
    else
      result="FP"; FP=$((FP + 1))
    fi

    short_input="${input:0:60}"
    echo "    $result: $short_input..."
    echo "{\"skill\":\"$skill\",\"input\":\"$short_input\",\"expect\":$expect,\"activated\":$activated,\"result\":\"$result\"}" >> "$RESULTS_FILE"

    rm -rf "$workdir"
  done
done

TOTAL=$((TP + FP + TN + FN))
TPR=$(echo "scale=2; $TP / ($TP + $FN)" | bc 2>/dev/null || echo "0")
FPR=$(echo "scale=2; $FP / ($FP + $TN)" | bc 2>/dev/null || echo "0")
ACCURACY=$(echo "scale=2; ($TP + $TN) / $TOTAL" | bc 2>/dev/null || echo "0")

echo ""
echo "---"
echo "Results: TP=$TP FP=$FP TN=$TN FN=$FN (total=$TOTAL)"
echo "True Positive Rate (recall): $TPR"
echo "False Positive Rate: $FPR"
echo "Accuracy: $ACCURACY"

# Explicit verdict: unforced activation baseline is ~40-50% (see glossary),
# so gate at TPR >= 0.5 with FPR <= 0.2. Overridable via env.
TPR_GATE="${ACTIVATION_TPR_GATE:-0.5}"
FPR_GATE="${ACTIVATION_FPR_GATE:-0.2}"
if (( $(echo "$TPR >= $TPR_GATE" | bc -l) )) && (( $(echo "$FPR <= $FPR_GATE" | bc -l) )); then
  VERDICT="PASS"
else
  VERDICT="FAIL"
fi
echo "Verdict: $VERDICT (gates: TPR >= $TPR_GATE, FPR <= $FPR_GATE)"

cat > "$RUN_DIR/summary.json" << EOF
{
  "timestamp": "$TIMESTAMP",
  "tool": "$TOOL_NAME",
  "total": $TOTAL,
  "tp": $TP, "fp": $FP, "tn": $TN, "fn": $FN,
  "true_positive_rate": $TPR,
  "false_positive_rate": $FPR,
  "accuracy": $ACCURACY,
  "verdict": "$VERDICT",
  "gates": {"tpr_min": $TPR_GATE, "fpr_max": $FPR_GATE}
}
EOF

echo "Results: $RUN_DIR"
