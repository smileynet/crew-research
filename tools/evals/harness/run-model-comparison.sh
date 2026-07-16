#!/bin/bash
# tools/evals/harness/run-model-comparison.sh
# Runs bedrock-model-family-comparison across all model families
# Usage: ./run-model-comparison.sh [--trials 3] [--dry-run] [--models "claude,gpt,deepseek"]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EVALS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
EXPERIMENT="$EVALS_DIR/experiments/bedrock-model-family-comparison.yaml"
RESULTS_DIR="$EVALS_DIR/results"

TRIALS=3
DRY_RUN=false
MODEL_FILTER=""
JUDGE_MODEL="anthropic.claude-opus-4-8"

while [[ $# -gt 0 ]]; do
  case $1 in
    --trials) TRIALS="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --models) MODEL_FILTER="$2"; shift 2 ;;
    --judge) JUDGE_MODEL="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

# ─── Model roster (validated Jul 15 2026) ──────────────────────────────────
declare -A MODELS
MODELS[claude]="anthropic.claude-sonnet-5"
MODELS[gpt]="openai.gpt-5.4"
MODELS[glm]="zai.glm-5"
MODELS[kimi]="moonshot.kimi-k2-thinking"
MODELS[qwen]="qwen.qwen3-coder-480b-a35b-v1:0"
MODELS[mistral]="mistral.devstral-2-123b"
MODELS[grok]="xai.grok-4.3"
MODELS[minimax]="minimax.minimax-m2.5"
# EXCLUDED: deepseek (account access denied), llama4 (needs max_tokens override)
# NOTE: GPT-5.5 only accessible via codex wrapper; using GPT-5.4 via closecode

# ─── Task prompts (extracted from YAML for direct use) ─────────────────────
TASKS=(
  "code-comprehension"
  "bug-diagnosis"
  "code-generation"
  "refactoring"
  "planning-before-acting"
  "instruction-following"
  "tool-use-reasoning"
)

# ─── Filter models if specified ────────────────────────────────────────────
ACTIVE_MODELS=()
if [[ -n "$MODEL_FILTER" ]]; then
  IFS=',' read -ra FILTER_LIST <<< "$MODEL_FILTER"
  for key in "${FILTER_LIST[@]}"; do
    if [[ -v "MODELS[$key]" ]]; then
      ACTIVE_MODELS+=("$key")
    else
      echo "Warning: unknown model key '$key', skipping" >&2
    fi
  done
else
  ACTIVE_MODELS=("${!MODELS[@]}")
fi

# ─── Setup ─────────────────────────────────────────────────────────────────
TIMESTAMP=$(date -u +%Y-%m-%dT%H-%M-%SZ)
RUN_DIR="$RESULTS_DIR/model-comparison-$TIMESTAMP"
mkdir -p "$RUN_DIR/outputs"

echo "═══════════════════════════════════════════════════════════════"
echo "  Bedrock Model Family Comparison"
echo "═══════════════════════════════════════════════════════════════"
echo "  Models: ${ACTIVE_MODELS[*]}"
echo "  Tasks:  ${#TASKS[@]}"
echo "  Trials: $TRIALS"
echo "  Judge:  $JUDGE_MODEL"
echo "  Output: $RUN_DIR"
echo "  Dry-run: $DRY_RUN"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Check tool availability
for tool in closecode yq jq; do
  if ! command -v "$tool" &>/dev/null; then
    echo "Error: $tool required but not found" >&2
    exit 2
  fi
done

# ─── Extract task inputs from experiment YAML ──────────────────────────────
extract_task_input() {
  local idx=$1
  yq ".tasks[$idx].input" "$EXPERIMENT"
}

extract_task_criteria() {
  local idx=$1
  yq ".tasks[$idx].criteria" "$EXPERIMENT"
}

# ─── Run a single model × task × trial ────────────────────────────────────
run_single() {
  local model_key="$1" task_idx="$2" trial="$3"
  local model_id="${MODELS[$model_key]}"
  local task_name="${TASKS[$task_idx]}"
  local input
  input=$(extract_task_input "$task_idx")

  local out_file="$RUN_DIR/outputs/${model_key}_${task_name}_trial${trial}.txt"

  if [[ "$DRY_RUN" == true ]]; then
    echo "  [dry-run] closecode run --model amazon-bedrock/$model_id \"${input:0:60}...\""
    echo "(dry-run)" > "$out_file"
    return 0
  fi

  local start_ms=$(($(date +%s%N) / 1000000))

  # Run via CloseCode with model override — inside an isolated temp workdir
  # (closecode is agentic and writes files; running in the caller's cwd leaked
  # debounce.ts/fixed-code.js into the repo root on 2026-07-15)
  local workdir
  workdir=$(mktemp -d -t "modelcmp-${model_key}-XXXX")
  (cd "$workdir" && timeout 180 closecode run --model "amazon-bedrock/$model_id" "$input") \
    > "$out_file" 2>/dev/null || {
      echo "TIMEOUT_OR_ERROR" > "$out_file"
      rm -rf "$workdir"
      return 1
    }
  rm -rf "$workdir"

  local end_ms=$(($(date +%s%N) / 1000000))
  local duration=$((end_ms - start_ms))

  # Record metadata
  echo "{\"model\":\"$model_key\",\"task\":\"$task_name\",\"trial\":$trial,\"duration_ms\":$duration}" \
    >> "$RUN_DIR/timing.jsonl"
}

# ─── Judge a single output ─────────────────────────────────────────────────
judge_output() {
  local model_key="$1" task_idx="$2" trial="$3"
  local task_name="${TASKS[$task_idx]}"
  local out_file="$RUN_DIR/outputs/${model_key}_${task_name}_trial${trial}.txt"
  local criteria
  criteria=$(extract_task_criteria "$task_idx")

  local output
  output=$(cat "$out_file")

  if [[ "$output" == "TIMEOUT_OR_ERROR" || "$output" == "(dry-run)" ]]; then
    echo "{\"model\":\"$model_key\",\"task\":\"$task_name\",\"trial\":$trial,\"score\":0,\"reason\":\"timeout or error\"}"
    return
  fi

  # Use kiro-cli as judge with the criteria rubric
  local judge_prompt="Score the following output on a 1-5 scale using ONLY the criteria below. Return ONLY a JSON object: {\"score\": N, \"reason\": \"one sentence\"}.

CRITERIA:
$criteria

OUTPUT TO JUDGE:
$output"

  local judge_result judge_dir
  # Judge in an isolated temp dir without -a: judges only score, never need file writes
  judge_dir=$(mktemp -d -t "modelcmp-judge-XXXX")
  judge_result=$( (cd "$judge_dir" && timeout 60 kiro-cli chat --no-interactive --wrap never "$judge_prompt") 2>/dev/null || echo '{"score": 0, "reason": "judge timeout"}')
  rm -rf "$judge_dir"

  # Extract JSON from judge response
  local score reason
  score=$(echo "$judge_result" | grep -oP '"score"\s*:\s*\K[0-9]+' | head -1 || echo "0")
  reason=$(echo "$judge_result" | grep -oP '"reason"\s*:\s*"\K[^"]+' | head -1 || echo "parse error")

  echo "{\"model\":\"$model_key\",\"task\":\"$task_name\",\"trial\":$trial,\"score\":$score,\"reason\":\"$reason\"}"
}

# ─── Main execution loop ───────────────────────────────────────────────────
echo "Phase 1: Generating outputs..."
echo ""

for model_key in "${ACTIVE_MODELS[@]}"; do
  echo "  ▶ $model_key (${MODELS[$model_key]})"
  for task_idx in "${!TASKS[@]}"; do
    for trial in $(seq 1 "$TRIALS"); do
      printf "    [%s] trial %d/%d... " "${TASKS[$task_idx]}" "$trial" "$TRIALS"
      if run_single "$model_key" "$task_idx" "$trial"; then
        echo "✓"
      else
        echo "✗"
      fi
    done
  done
  echo ""
done

echo ""
echo "Phase 2: Judging outputs..."
echo ""

SCORES_FILE="$RUN_DIR/scores.jsonl"
: > "$SCORES_FILE"

for model_key in "${ACTIVE_MODELS[@]}"; do
  echo "  ▶ Judging $model_key..."
  for task_idx in "${!TASKS[@]}"; do
    for trial in $(seq 1 "$TRIALS"); do
      result=$(judge_output "$model_key" "$task_idx" "$trial")
      echo "$result" >> "$SCORES_FILE"
    done
  done
done

# ─── Summary ───────────────────────────────────────────────────────────────
echo ""
echo "Phase 3: Generating summary..."

# Compute averages per model per task
python3 - "$SCORES_FILE" "$RUN_DIR/summary.json" << 'PYTHON'
import json, sys
from collections import defaultdict

scores_file = sys.argv[1]
output_file = sys.argv[2]

data = defaultdict(lambda: defaultdict(list))
with open(scores_file) as f:
    for line in f:
        if not line.strip():
            continue
        rec = json.loads(line)
        data[rec["model"]][rec["task"]].append(rec["score"])

summary = {}
for model, tasks in sorted(data.items()):
    summary[model] = {}
    total = []
    for task, scores in sorted(tasks.items()):
        avg = sum(scores) / len(scores) if scores else 0
        summary[model][task] = {"avg": round(avg, 2), "scores": scores}
        total.extend(scores)
    summary[model]["_overall"] = round(sum(total) / len(total), 2) if total else 0

with open(output_file, 'w') as f:
    json.dump(summary, f, indent=2)

# Print leaderboard
print("\n╔═══════════════════════════════════════════════════════════╗")
print("║             MODEL FAMILY LEADERBOARD                      ║")
print("╠═══════════════════════════════════════════════════════════╣")
ranked = sorted(summary.items(), key=lambda x: x[1].get("_overall", 0), reverse=True)
for i, (model, scores) in enumerate(ranked, 1):
    overall = scores.get("_overall", 0)
    print(f"║  {i}. {model:<20} {overall:.2f}/5.00                     ║")
print("╚═══════════════════════════════════════════════════════════╝")
PYTHON

echo ""
echo "Results: $RUN_DIR"
echo "  scores.jsonl  — raw per-trial scores"
echo "  summary.json  — aggregated averages"
echo "  timing.jsonl  — latency measurements"
echo "  outputs/      — raw model responses"
echo ""
echo "Done."
