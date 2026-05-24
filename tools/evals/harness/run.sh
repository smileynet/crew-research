#!/bin/bash
# tools/evals/harness/run.sh — LLM-as-judge eval harness with dual-run support
# Usage: ./run.sh [--adapter kiro-cli] [--definition name] [--all] [--dry-run] [--trials 3]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EVALS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROOFS_DIR="$(cd "$EVALS_DIR/../proofs" && pwd)"
ADAPTERS_DIR="$PROOFS_DIR/adapters"
DEFINITIONS_DIR="$EVALS_DIR/definitions"
RESULTS_DIR="$EVALS_DIR/results"
JUDGES_DIR="$EVALS_DIR/judges"

# Defaults
ADAPTER="kiro-cli"
DEFINITION=""
RUN_ALL=false
DRY_RUN=false
TRIALS=3
JUDGE_CONFIG="$JUDGES_DIR/default.yaml"

while [[ $# -gt 0 ]]; do
  case $1 in
    --adapter) ADAPTER="$2"; shift 2 ;;
    --definition) DEFINITION="$2"; shift 2 ;;
    --all) RUN_ALL=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --trials) TRIALS="$2"; shift 2 ;;
    --judge) JUDGE_CONFIG="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

# Validate tools
for cmd in yq claude; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: $cmd required" >&2; exit 2
  fi
done

# Load adapter
ADAPTER_FILE="$ADAPTERS_DIR/$ADAPTER.yaml"
[[ -f "$ADAPTER_FILE" ]] || { echo "Error: adapter not found: $ADAPTER_FILE" >&2; exit 2; }

TOOL_NAME=$(yq '.tool' "$ADAPTER_FILE")
VERSION_CMD=$(yq '.version_command' "$ADAPTER_FILE")
INVOKE_CMD=$(yq '.invoke.command' "$ADAPTER_FILE")
INVOKE_NO_AGENT_CMD=$(yq '.invoke.command_no_agent' "$ADAPTER_FILE")
DEFAULT_TIMEOUT=$(yq '.invoke.timeout // 90' "$ADAPTER_FILE")
SKILL_LOCATION=$(yq '.skill.location' "$ADAPTER_FILE")

# Load judge config
JUDGE_MODEL=$(yq '.model' "$JUDGE_CONFIG")
JUDGE_TEMP=$(yq '.temperature' "$JUDGE_CONFIG")

# Metadata
TOOL_VERSION=$($VERSION_CMD 2>/dev/null | head -1 || echo "unknown")
TIMESTAMP=$(date -u +%Y-%m-%dT%H-%M-%SZ)
COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

echo "Eval harness: $TOOL_NAME ($TOOL_VERSION)"
echo "Judge: $JUDGE_MODEL | Trials: $TRIALS | Dry-run: $DRY_RUN"
echo "Timestamp: $TIMESTAMP"
echo ""

# Collect definitions
DEFS=()
if [[ -n "$DEFINITION" ]]; then
  DEFS=("$DEFINITIONS_DIR/$DEFINITION.yaml")
elif [[ "$RUN_ALL" == true ]]; then
  mapfile -t DEFS < <(find "$DEFINITIONS_DIR" -name "*.yaml" | sort)
else
  echo "Specify --definition <name> or --all" >&2; exit 1
fi

[[ ${#DEFS[@]} -gt 0 ]] || { echo "No definitions found." >&2; exit 1; }
echo "Running ${#DEFS[@]} eval(s)..."
echo ""

# Results setup
RUN_DIR="$RESULTS_DIR/$TIMESTAMP"
mkdir -p "$RUN_DIR"

TOTAL=0; PASSED=0; FAILED=0
SCORES_FILE="$RUN_DIR/scores.jsonl"
: > "$SCORES_FILE"

strip_ansi() { sed 's/\x1B\[[0-9;]*[a-zA-Z]//g'; }

# Set up a project fixture in the workspace
setup_fixture() {
  local workdir="$1" fixture_name="$2"
  local fixture_file="$EVALS_DIR/fixtures/$fixture_name.yaml"
  [[ -f "$fixture_file" ]] || { echo "[warn] Fixture not found: $fixture_file" >&2; return 0; }

  local repo=$(yq '.repo' "$fixture_file")
  local install_cmd=$(yq '.install' "$fixture_file")

  git clone --depth 1 -q "$repo" "$workdir/project" 2>/dev/null || { echo "[warn] Clone failed" >&2; return 0; }
  (cd "$workdir/project" && eval "$install_cmd" > /dev/null 2>&1) || { echo "[warn] Install failed" >&2; return 0; }
}

# Invoke agent in isolated workspace, capture output
invoke_agent() {
  local workdir="$1" input="$2" skill_name="${3:-}" timeout="${4:-$DEFAULT_TIMEOUT}"

  # Deploy skill if specified
  if [[ -n "$skill_name" ]]; then
    local skill_src="$EVALS_DIR/../../atomics/skills/$skill_name/SKILL.md"
    if [[ -f "$skill_src" ]]; then
      local skill_dest="$workdir/$(echo "$SKILL_LOCATION" | sed "s/{name}/$skill_name/")"
      mkdir -p "$(dirname "$skill_dest")"
      cp "$skill_src" "$skill_dest"
    else
      echo "[warn] Skill not found: $skill_src" >&2
    fi
  fi

  if [[ "$DRY_RUN" == true ]]; then
    echo "[dry-run] Would invoke: $input (skill: ${skill_name:-none})"
    return
  fi

  local cmd
  cmd=$(echo "$INVOKE_NO_AGENT_CMD" | sed "s|{query}|$input|")
  cd "$workdir"
  timeout "$timeout" bash -c "$cmd" 2>&1 | strip_ansi || true
}

# Send output to judge, get SCORE and REASON
judge_output() {
  local output="$1" criteria="$2" ideal="${3:-}"

  local judge_prompt="You are an evaluation judge. Score the following agent output on a 1-5 scale.

CRITERIA:
$criteria

$(if [[ -n "$ideal" ]]; then echo "IDEAL RESPONSE (for calibration):
$ideal
"; fi)
AGENT OUTPUT:
$output

First reason step-by-step about the output quality against the criteria, then provide your final score.
Respond with EXACTLY this format at the end:
SCORE: <number 1-5>
REASON: <one sentence>"

  if [[ "$DRY_RUN" == true ]]; then
    echo "SCORE: 3"
    echo "REASON: dry-run placeholder"
    return
  fi

  claude --print --model "$JUDGE_MODEL" "$judge_prompt" 2>/dev/null || echo "SCORE: 0
REASON: judge invocation failed"
}

# Parse score from judge output
parse_score() {
  local judge_output="$1"
  echo "$judge_output" | grep -oP 'SCORE:\s*\K[0-9]+' | tail -1 || echo "0"
}

parse_reason() {
  local judge_output="$1"
  echo "$judge_output" | grep -oP 'REASON:\s*\K.*' | tail -1 || echo "parse error"
}

# Run a single eval (standard or dual-run)
run_eval() {
  local def_file="$1"
  local name=$(yq '.name' "$def_file")
  local skill=$(yq '.skill // ""' "$def_file")
  local threshold=$(yq '.threshold // 4' "$def_file")
  local delta_threshold=$(yq '.delta_threshold // 0' "$def_file")
  local timeout=$(yq '.timeout // 120' "$def_file")
  local is_dual_run=$(yq '.runs.without_skill // false' "$def_file")
  local fixture=$(yq '.fixture // ""' "$def_file")

  TOTAL=$((TOTAL + 1))

  # Collect tasks (single input or tasks array)
  local task_count=$(yq '.tasks | length // 0' "$def_file")
  local inputs=() criterias=() ideals=()

  if [[ $task_count -gt 0 ]]; then
    for i in $(seq 0 $((task_count - 1))); do
      inputs+=("$(yq ".tasks[$i].input" "$def_file")")
      criterias+=("$(yq ".tasks[$i].criteria" "$def_file")")
      ideals+=("$(yq ".tasks[$i].ideal // \"\"" "$def_file")")
    done
  else
    inputs+=("$(yq '.input' "$def_file")")
    criterias+=("$(yq '.criteria' "$def_file")")
    ideals+=("$(yq '.ideal // ""' "$def_file")")
  fi

  local all_scores=() all_with_scores=() all_without_scores=()
  local activation_count=0 activation_total=0

  for task_idx in "${!inputs[@]}"; do
    local input="${inputs[$task_idx]}"
    local criteria="${criterias[$task_idx]}"
    local ideal="${ideals[$task_idx]}"

    local trial_scores=() trial_with=() trial_without=()

    for trial in $(seq 1 "$TRIALS"); do
      local workdir=$(mktemp -d -t "eval-${name}-XXXX")
      [[ -n "$fixture" ]] && setup_fixture "$workdir" "$fixture"

      if [[ "$is_dual_run" == "true" ]]; then
        # Run WITH skill
        local with_output
        with_output=$(invoke_agent "$workdir" "$input" "$skill" "$timeout")
        local with_judge
        with_judge=$(judge_output "$with_output" "$criteria" "$ideal")
        local with_score
        with_score=$(parse_score "$with_judge")
        trial_with+=("$with_score")

        # Check activation
        if [[ "$DRY_RUN" != true && -n "$skill" ]]; then
          activation_total=$((activation_total + 1))
          if "$SCRIPT_DIR/check-activation.sh" "$workdir" "$skill" &>/dev/null; then
            activation_count=$((activation_count + 1))
          fi
        fi

        # Run WITHOUT skill (fresh workspace)
        rm -rf "$workdir"
        workdir=$(mktemp -d -t "eval-${name}-base-XXXX")
        [[ -n "$fixture" ]] && setup_fixture "$workdir" "$fixture"
        local without_output
        without_output=$(invoke_agent "$workdir" "$input" "" "$timeout")
        local without_judge
        without_judge=$(judge_output "$without_output" "$criteria" "$ideal")
        local without_score
        without_score=$(parse_score "$without_judge")
        trial_without+=("$without_score")
      else
        # Standard eval
        local output
        output=$(invoke_agent "$workdir" "$input" "$skill" "$timeout")
        local judge_result
        judge_result=$(judge_output "$output" "$criteria" "$ideal")
        local score
        score=$(parse_score "$judge_result")
        trial_scores+=("$score")

        # Check activation
        if [[ "$DRY_RUN" != true && -n "$skill" ]]; then
          activation_total=$((activation_total + 1))
          if "$SCRIPT_DIR/check-activation.sh" "$workdir" "$skill" &>/dev/null; then
            activation_count=$((activation_count + 1))
          fi
        fi
      fi

      rm -rf "$workdir"
    done

    if [[ "$is_dual_run" == "true" ]]; then
      all_with_scores+=("${trial_with[@]}")
      all_without_scores+=("${trial_without[@]}")
    else
      all_scores+=("${trial_scores[@]}")
    fi
  done

  # Compute results
  local status="PASS" reason="" avg_score=0 avg_with=0 avg_without=0 delta=0

  if [[ "$is_dual_run" == "true" ]]; then
    # Average with/without scores
    local sum_w=0 sum_wo=0 count=${#all_with_scores[@]}
    for s in "${all_with_scores[@]}"; do sum_w=$((sum_w + s)); done
    for s in "${all_without_scores[@]}"; do sum_wo=$((sum_wo + s)); done
    avg_with=$(echo "scale=2; $sum_w / $count" | bc)
    avg_without=$(echo "scale=2; $sum_wo / $count" | bc)
    delta=$(echo "scale=2; $avg_with - $avg_without" | bc)
    avg_score=$avg_with

    # Pass criteria: with >= threshold AND delta >= delta_threshold
    if (( $(echo "$avg_with < $threshold" | bc -l) )); then
      status="FAIL"; reason="with_skill avg $avg_with < threshold $threshold"
    elif (( $(echo "$delta < $delta_threshold" | bc -l) )); then
      status="FAIL"; reason="delta $delta < delta_threshold $delta_threshold"
    else
      reason="with=$avg_with without=$avg_without delta=$delta"
    fi
  else
    # Majority pass: count scores >= threshold
    local pass_count=0 sum=0 count=${#all_scores[@]}
    for s in "${all_scores[@]}"; do
      sum=$((sum + s))
      [[ $s -ge $threshold ]] && pass_count=$((pass_count + 1))
    done
    avg_score=$(echo "scale=2; $sum / $count" | bc)
    local majority=$(( (count / 2) + 1 ))

    if [[ $pass_count -lt $majority ]]; then
      status="FAIL"; reason="$pass_count/$count trials passed (need $majority)"
    else
      reason="$pass_count/$count trials passed, avg=$avg_score"
    fi
  fi

  # Record
  if [[ "$status" == "PASS" ]]; then
    PASSED=$((PASSED + 1))
    echo "  ✅ $name ($reason)"
  else
    FAILED=$((FAILED + 1))
    echo "  ❌ $name ($reason)"
  fi

  # Write JSONL
  local activation_rate="null"
  if [[ $activation_total -gt 0 ]]; then
    activation_rate=$(echo "scale=2; $activation_count / $activation_total" | bc)
  fi
  local score_line="{\"name\":\"$name\",\"status\":\"$status\",\"score\":$avg_score,\"reason\":\"$reason\",\"activated\":$activation_count,\"activation_total\":$activation_total,\"activation_rate\":$activation_rate"
  if [[ "$is_dual_run" == "true" ]]; then
    score_line="$score_line,\"with_score\":$avg_with,\"without_score\":$avg_without,\"delta\":$delta"
  fi
  score_line="$score_line}"
  echo "$score_line" >> "$SCORES_FILE"
}

# Execute
for def in "${DEFS[@]}"; do
  if [[ -f "$def" ]]; then
    run_eval "$def"
  else
    echo "  ⚠️  Not found: $def" >&2
  fi
done

echo ""
echo "---"
echo "Results: $PASSED passed, $FAILED failed ($TOTAL total)"

# Write meta.json
cat > "$RUN_DIR/meta.json" << EOF
{
  "tool": "$TOOL_NAME",
  "tool_version": "$TOOL_VERSION",
  "timestamp": "$TIMESTAMP",
  "commit": "$COMMIT",
  "config": {"trials": $TRIALS, "judge": "$JUDGE_MODEL", "adapter": "$ADAPTER", "dry_run": $DRY_RUN},
  "summary": {"total": $TOTAL, "passed": $PASSED, "failed": $FAILED, "avg_score": 0}
}
EOF

echo "Results dir: $RUN_DIR"
[[ $FAILED -eq 0 ]] && exit 0 || exit 1
