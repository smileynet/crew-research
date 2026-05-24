#!/bin/bash
# tools/evals/harness/run-experiment.sh — Multi-condition experiment runner
# Runs the same task under multiple conditions and collects metrics + scores
# Usage: ./run-experiment.sh --experiment <name> [--trials 3] [--fixture defu]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EVALS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROOFS_DIR="$(cd "$EVALS_DIR/../proofs" && pwd)"
ADAPTERS_DIR="$PROOFS_DIR/adapters"
ATOMICS_DIR="$EVALS_DIR/../../atomics/skills"

ADAPTER_FILE="$ADAPTERS_DIR/kiro-cli.yaml"
INVOKE_CMD=$(yq '.invoke.command_no_agent' "$ADAPTER_FILE")
SKILL_LOCATION=$(yq '.skill.location' "$ADAPTER_FILE")
DEFAULT_TIMEOUT=$(yq '.invoke.timeout // 90' "$ADAPTER_FILE")

EXPERIMENT=""
TRIALS=3
FIXTURE=""
TIMEOUT=90

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

TIMESTAMP=$(date -u +%Y-%m-%dT%H-%M-%SZ)
RESULTS_DIR="$EVALS_DIR/results/$EXPERIMENT-$TIMESTAMP"
mkdir -p "$RESULTS_DIR"

echo "Experiment: $EXPERIMENT"
echo "Trials: $TRIALS | Fixture: ${FIXTURE:-none} | Timeout: ${TIMEOUT}s"
echo "Results: $RESULTS_DIR"
echo ""

# Parse experiment file
QUESTION=$(yq '.question' "$EXPERIMENT_FILE")
TASK_COUNT=$(yq '.tasks | length' "$EXPERIMENT_FILE")
CONDITION_COUNT=$(yq '.conditions | length' "$EXPERIMENT_FILE")

echo "Question: $QUESTION"
echo "Tasks: $TASK_COUNT | Conditions: $CONDITION_COUNT"
echo ""

strip_ansi() { sed 's/\x1B\[[0-9;]*[a-zA-Z]//g'; }

# Setup fixture if specified
setup_fixture_dir() {
  local workdir="$1"
  if [[ -n "$FIXTURE" ]]; then
    local fixture_file="$EVALS_DIR/fixtures/$FIXTURE.yaml"
    if [[ -f "$fixture_file" ]]; then
      local repo=$(yq '.repo' "$fixture_file")
      local install_cmd=$(yq '.install' "$fixture_file")
      git clone --depth 1 -q "$repo" "$workdir/project" 2>/dev/null || true
      (cd "$workdir/project" && eval "$install_cmd" > /dev/null 2>&1) || true
    fi
  fi
}

# Deploy skills for a condition
deploy_condition() {
  local workdir="$1" condition_idx="$2"
  local deploy_dir="$workdir"
  [[ -d "$workdir/project" ]] && deploy_dir="$workdir/project"
  local skills=$(yq ".conditions[$condition_idx].skills[]?" "$EXPERIMENT_FILE" 2>/dev/null)
  for sk in $skills; do
    local src="$ATOMICS_DIR/$sk/SKILL.md"
    if [[ -f "$src" ]]; then
      local dest="$deploy_dir/$(echo "$SKILL_LOCATION" | sed "s/{name}/$sk/")"
      mkdir -p "$(dirname "$dest")"
      cp "$src" "$dest"
    fi
  done
}

# Run all conditions × tasks × trials
RESULTS_FILE="$RESULTS_DIR/experiment.jsonl"
: > "$RESULTS_FILE"

for task_idx in $(seq 0 $((TASK_COUNT - 1))); do
  task_input=$(yq ".tasks[$task_idx].input" "$EXPERIMENT_FILE")
  task_name=$(yq ".tasks[$task_idx].name // \"task-$task_idx\"" "$EXPERIMENT_FILE")
  echo "Task $((task_idx+1))/$TASK_COUNT: $task_name"

  for cond_idx in $(seq 0 $((CONDITION_COUNT - 1))); do
    cond_name=$(yq ".conditions[$cond_idx].name" "$EXPERIMENT_FILE")
    printf "  %-20s" "$cond_name:"

    trial_metrics=()
    for trial in $(seq 1 "$TRIALS"); do
      workdir=$(mktemp -d -t "exp-${EXPERIMENT}-XXXX")
      setup_fixture_dir "$workdir"
      deploy_condition "$workdir" "$cond_idx"

      # Invoke (from project dir if fixture exists, else workdir)
      local invoke_dir="$workdir"
      [[ -d "$workdir/project" ]] && invoke_dir="$workdir/project"
      cmd=$(echo "$INVOKE_CMD" | sed "s|{query}|$task_input|")
      cd "$invoke_dir"
      timeout "$TIMEOUT" bash -c "$cmd" > /dev/null 2>&1 || true

      # Extract metrics
      metrics=$("$SCRIPT_DIR/extract-metrics.sh" "$workdir" 2>/dev/null || echo '{}')

      # Check activation for each skill in condition
      local check_dir="$workdir"
      [[ -d "$workdir/project" ]] && check_dir="$workdir/project"
      activated=0; activation_total=0
      for sk in $(yq ".conditions[$cond_idx].skills[]?" "$EXPERIMENT_FILE" 2>/dev/null); do
        activation_total=$((activation_total + 1))
        if "$SCRIPT_DIR/check-activation.sh" "$check_dir" "$sk" &>/dev/null; then
          activated=$((activated + 1))
        fi
      done

      # Record
      echo "{\"experiment\":\"$EXPERIMENT\",\"task\":\"$task_name\",\"condition\":\"$cond_name\",\"trial\":$trial,\"activated\":$activated,\"activation_total\":$activation_total,\"metrics\":$metrics}" >> "$RESULTS_FILE"

      rm -rf "$workdir"
    done
    printf "done (%d trials)\n" "$TRIALS"
  done
done

echo ""
echo "---"
echo "Complete. Results: $RESULTS_FILE"
echo ""

# Generate summary
python3 -c "
import json, sys
from collections import defaultdict

results = defaultdict(lambda: defaultdict(list))
with open('$RESULTS_FILE') as f:
    for line in f:
        d = json.loads(line)
        key = (d['task'], d['condition'])
        m = d.get('metrics', {})
        results[key]['tokens'].append(m.get('total_tokens', 0))
        results[key]['duration'].append(m.get('duration_ms', 0))
        results[key]['llm_calls'].append(m.get('llm_calls', 0))
        results[key]['tool_use'].append(m.get('tool_use_count', 0))
        results[key]['context_pct'].append(m.get('context_usage_pct', 0))
        results[key]['activated'].append(d.get('activated', 0))
        results[key]['activation_total'].append(d.get('activation_total', 0))

print('Summary:')
print(f'{\"Task\":<30} {\"Condition\":<20} {\"Tokens\":>8} {\"Duration\":>10} {\"LLM\":>5} {\"Tools\":>6} {\"Ctx%\":>6} {\"Act\":>5}')
print('-' * 95)
for (task, cond), data in sorted(results.items()):
    avg_tok = sum(data['tokens']) / len(data['tokens'])
    avg_dur = sum(data['duration']) / len(data['duration'])
    avg_llm = sum(data['llm_calls']) / len(data['llm_calls'])
    avg_tool = sum(data['tool_use']) / len(data['tool_use'])
    avg_ctx = sum(data['context_pct']) / len(data['context_pct'])
    act = f\"{sum(data['activated'])}/{sum(data['activation_total'])}\"
    print(f'{task:<30} {cond:<20} {avg_tok:>8.0f} {avg_dur:>8.0f}ms {avg_llm:>5.1f} {avg_tool:>6.1f} {avg_ctx:>5.1f}% {act:>5}')
" 2>/dev/null || true

# Write summary json
python3 -c "
import json
from collections import defaultdict

conditions = defaultdict(lambda: {'tokens': [], 'duration': [], 'llm_calls': []})
with open('$RESULTS_FILE') as f:
    for line in f:
        d = json.loads(line)
        m = d.get('metrics', {})
        conditions[d['condition']]['tokens'].append(m.get('total_tokens', 0))
        conditions[d['condition']]['duration'].append(m.get('duration_ms', 0))
        conditions[d['condition']]['llm_calls'].append(m.get('llm_calls', 0))

summary = {}
for cond, data in conditions.items():
    summary[cond] = {
        'avg_tokens': sum(data['tokens']) / max(len(data['tokens']), 1),
        'avg_duration_ms': sum(data['duration']) / max(len(data['duration']), 1),
        'avg_llm_calls': sum(data['llm_calls']) / max(len(data['llm_calls']), 1),
    }

with open('$RESULTS_DIR/summary.json', 'w') as f:
    json.dump({'experiment': '$EXPERIMENT', 'timestamp': '$TIMESTAMP', 'trials': $TRIALS, 'conditions': summary}, f, indent=2)
" 2>/dev/null || true
