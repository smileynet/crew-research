#!/bin/bash
# tools/evals/harness/run-qualitative-experiment.sh
# Like run-experiment.sh but captures agent output text for LLM judging
# Usage: ./run-qualitative-experiment.sh --experiment <name> [--trials 3] [--fixture defu]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EVALS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ATOMICS_DIR="$EVALS_DIR/../../atomics/skills"

ADAPTER_FILE="$EVALS_DIR/../proofs/adapters/kiro-cli.yaml"
INVOKE_CMD=$(yq '.invoke.command_no_agent' "$ADAPTER_FILE")
SKILL_LOCATION=$(yq '.skill.location' "$ADAPTER_FILE")

EXPERIMENT=""
TRIALS=1
FIXTURE=""
TIMEOUT=180

while [[ $# -gt 0 ]]; do
  case $1 in
    --experiment) EXPERIMENT="$2"; shift 2 ;;
    --trials) TRIALS="$2"; shift 2 ;;
    --fixture) FIXTURE="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done

[[ -n "$EXPERIMENT" ]] || { echo "Usage: $0 --experiment <name>" >&2; exit 1; }

EXPERIMENT_FILE="$EVALS_DIR/experiments/$EXPERIMENT.yaml"
[[ -f "$EXPERIMENT_FILE" ]] || { echo "Experiment not found: $EXPERIMENT_FILE" >&2; exit 1; }

# Use fixture from experiment file if not overridden
[[ -z "$FIXTURE" ]] && FIXTURE=$(yq '.fixture // ""' "$EXPERIMENT_FILE")

TIMESTAMP=$(date -u +%Y-%m-%dT%H-%M-%SZ)
RESULTS_DIR="$EVALS_DIR/results/${EXPERIMENT}-${TIMESTAMP}"
OUTPUTS_DIR="$RESULTS_DIR/outputs"
mkdir -p "$OUTPUTS_DIR"

echo "Experiment: $EXPERIMENT | Fixture: ${FIXTURE:-none} | Trials: $TRIALS"
echo "Results: $RESULTS_DIR"
echo ""

strip_ansi() { sed 's/\x1B\[[0-9;]*[a-zA-Z]//g'; }

setup_fixture_dir() {
  local workdir="$1"
  if [[ -n "$FIXTURE" ]]; then
    local fixture_file="$EVALS_DIR/fixtures/$FIXTURE.yaml"
    if [[ -f "$fixture_file" ]]; then
      local repo install_cmd
      repo=$(yq '.repo' "$fixture_file")
      install_cmd=$(yq '.install' "$fixture_file")
      echo "  Cloning $FIXTURE..."
      git clone --depth 1 -q "$repo" "$workdir/project" 2>/dev/null || true
      (cd "$workdir/project" && eval "$install_cmd" > /dev/null 2>&1) || true
    fi
  fi
}

deploy_condition() {
  local workdir="$1" condition_idx="$2"
  local deploy_dir="$workdir"
  [[ -d "$workdir/project" ]] && deploy_dir="$workdir/project"
  mkdir -p "$deploy_dir/.kiro/skills"
  local skills
  skills=$(yq ".conditions[$condition_idx].skills[]?" "$EXPERIMENT_FILE" 2>/dev/null || true)
  for sk in $skills; do
    local src="$ATOMICS_DIR/$sk/SKILL.md"
    if [[ -f "$src" ]]; then
      mkdir -p "$deploy_dir/.kiro/skills/$sk"
      cp "$src" "$deploy_dir/.kiro/skills/$sk/SKILL.md"
    fi
  done
}

TASK_COUNT=$(yq '.tasks | length' "$EXPERIMENT_FILE")
CONDITION_COUNT=$(yq '.conditions | length' "$EXPERIMENT_FILE")

# Run all conditions × tasks × trials, capture output
for task_idx in $(seq 0 $((TASK_COUNT - 1))); do
  task_name=$(yq ".tasks[$task_idx].name" "$EXPERIMENT_FILE")
  task_input=$(yq ".tasks[$task_idx].input" "$EXPERIMENT_FILE")

  echo "Task: $task_name"

  for cond_idx in $(seq 0 $((CONDITION_COUNT - 1))); do
    cond_name=$(yq ".conditions[$cond_idx].name" "$EXPERIMENT_FILE")
    printf "  %-20s " "$cond_name:"

    for trial in $(seq 1 "$TRIALS"); do
      workdir=$(mktemp -d -t "qualexp-XXXX")
      setup_fixture_dir "$workdir" 2>/dev/null
      deploy_condition "$workdir" "$cond_idx"

      invoke_dir="$workdir"
      [[ -d "$workdir/project" ]] && invoke_dir="$workdir/project"

      output_file="$OUTPUTS_DIR/${task_name}__${cond_name}__trial${trial}.txt"
      # Write input to temp file to handle multi-line prompts safely
      input_file=$(mktemp)
      printf '%s' "$task_input" > "$input_file"
      cd "$invoke_dir"
      timeout "$TIMEOUT" kiro-cli chat --no-interactive -a --wrap never "$(cat "$input_file")" 2>/dev/null | strip_ansi > "$output_file" || true
      cd "$SCRIPT_DIR"
      rm -f "$input_file"

      rm -rf "$workdir"
      printf "."
    done
    echo " done"
  done
  echo ""
done

# Build judge input document
JUDGE_INPUT="$RESULTS_DIR/judge-input.md"
echo "# Keyword vs Synonym — Judge Input" > "$JUDGE_INPUT"
echo "" >> "$JUDGE_INPUT"
echo "Rate each output on: depth (1-5), actionability (1-5), insight_novelty (1-5), why_reasoning (1-5)." >> "$JUDGE_INPUT"
echo "" >> "$JUDGE_INPUT"

JUDGE_CRITERIA=$(yq '.judge_criteria' "$EXPERIMENT_FILE" 2>/dev/null || echo "")
if [[ -n "$JUDGE_CRITERIA" && "$JUDGE_CRITERIA" != "null" ]]; then
  echo "## Scoring Guide" >> "$JUDGE_INPUT"
  echo "$JUDGE_CRITERIA" >> "$JUDGE_INPUT"
  echo "" >> "$JUDGE_INPUT"
fi

for output_file in "$OUTPUTS_DIR"/*.txt; do
  label=$(basename "$output_file" .txt)
  echo "---" >> "$JUDGE_INPUT"
  echo "## $label" >> "$JUDGE_INPUT"
  echo "" >> "$JUDGE_INPUT"
  # Truncate to 3000 chars to keep judge context manageable
  head -c 3000 "$output_file" >> "$JUDGE_INPUT"
  echo "" >> "$JUDGE_INPUT"
done

echo "---"
echo "Outputs captured: $(ls "$OUTPUTS_DIR"/*.txt | wc -l) files"
echo "Judge input: $JUDGE_INPUT"
echo ""
echo "Next: review outputs manually or run judge:"
echo "  kiro-cli chat --no-interactive -a \"$(cat "$JUDGE_INPUT" | head -5)...\" "
echo ""
echo "Or open and review directly:"
echo "  cat $JUDGE_INPUT"
