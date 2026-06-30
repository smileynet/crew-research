#!/bin/bash
# tools/evals/harness/run.sh — LLM-as-judge eval harness with dual-run support
# Usage: ./run.sh [--adapter kiro-cli|crush|codex|agy] [--definition name] [--all] [--dry-run] [--trials 3] [--engine v2|v3]
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
ISOLATED=false
TRIALS=3
MODEL=""
ENGINE=""
JUDGE_CONFIG="$JUDGES_DIR/default.yaml"

while [[ $# -gt 0 ]]; do
  case $1 in
    --adapter) ADAPTER="$2"; shift 2 ;;
    --definition) DEFINITION="$2"; shift 2 ;;
    --all) RUN_ALL=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --isolated) ISOLATED=true; shift ;;
    --trials) TRIALS="$2"; shift 2 ;;
    --model) MODEL="$2"; shift 2 ;;
    --engine) ENGINE="$2"; shift 2 ;;
    --judge) JUDGE_CONFIG="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

# Validate tools
for cmd in yq; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: $cmd required" >&2; exit 2
  fi
done
# Validate adapter tool is available
case "$ADAPTER" in
  crush) command -v crush &>/dev/null || { echo "Error: crush not found" >&2; exit 2; } ;;
  codex) command -v codex &>/dev/null || { echo "Error: codex not found" >&2; exit 2; } ;;
  agy) command -v agy &>/dev/null || { echo "Error: agy not found" >&2; exit 2; } ;;
  *) command -v kiro-cli &>/dev/null || { echo "Error: kiro-cli not found" >&2; exit 2; } ;;
esac

# Validate trials
[[ "$TRIALS" -gt 0 ]] 2>/dev/null || { echo "Error: --trials must be > 0" >&2; exit 1; }

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

# Warm up recall embedding model (avoids first-run latency in trials)
if command -v recall &>/dev/null; then
  recall search "warmup" --results 1 >/dev/null 2>&1 || true
fi

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

  # Clone repo if specified
  if [[ -n "$repo" && "$repo" != "null" && "$repo" != "" ]]; then
    git clone --depth 1 -q "$repo" "$workdir/project" 2>/dev/null || { echo "[warn] Clone failed" >&2; return 0; }
    (cd "$workdir/project" && eval "$install_cmd" > /dev/null 2>&1) || { echo "[warn] Install failed" >&2; return 0; }
  fi

  # Inject workspace files if specified
  local file_count=$(yq '.files | length // 0' "$fixture_file" 2>/dev/null)
  if [[ "$file_count" -gt 0 ]]; then
    for key in $(yq '.files | keys | .[]' "$fixture_file" 2>/dev/null); do
      local dest="$workdir/$key"
      mkdir -p "$(dirname "$dest")"
      yq ".files.\"$key\"" "$fixture_file" > "$dest"
    done
  fi
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

  # Write input to temp file, pass via xargs to avoid shell escaping issues
  local input_file=$(mktemp "$workdir/.eval-input-XXXX")
  printf '%s' "$input" > "$input_file"
  cd "$workdir"

  # Use adapter-specific invocation
  case "$ADAPTER" in
    crush)
      local model_flag="--model glm-5.2"
      [[ -n "$MODEL" ]] && model_flag="--model $MODEL"
      timeout "$timeout" bash -c 'cd "$1" && crush run --quiet '"$model_flag"' "$(cat "$2")"' _ "$workdir" "$input_file" 2>&1 | strip_ansi || true
      ;;
    codex)
      local model_flag=""
      [[ -n "$MODEL" ]] && model_flag="--model $MODEL"
      timeout "$timeout" bash -c 'codex exec --dangerously-bypass-approvals-and-sandbox --ephemeral '"$model_flag"' -C "$1" "$(cat "$2")" < /dev/null' _ "$workdir" "$input_file" 2>&1 | strip_ansi || true
      ;;
    agy)
      local model_flag=""
      [[ -n "$MODEL" ]] && model_flag="--model $MODEL"
      timeout "$timeout" bash -c 'cd "$1" && agy --print '"$model_flag"' "$(cat "$2")"' _ "$workdir" "$input_file" 2>&1 | strip_ansi || true
      ;;
    *)
      local model_flag=""
      [[ -n "$MODEL" ]] && model_flag="--model $MODEL"
      local engine_flag=""
      [[ -n "$ENGINE" ]] && engine_flag="--agent-engine $ENGINE"
      local env_prefix=""
      [[ "$ISOLATED" == true ]] && env_prefix="KIRO_HOME=$workdir/.kiro-isolated"
      local out_file=$(mktemp)
      if [[ -n "$env_prefix" ]]; then
        mkdir -p "$workdir/.kiro-isolated"
        # Copy skill into isolated home if deployed
        [[ -d "$workdir/.kiro/skills" ]] && cp -r "$workdir/.kiro/skills" "$workdir/.kiro-isolated/"
        timeout "$timeout" bash -c "$env_prefix"' kiro-cli chat --no-interactive -a --wrap never '"$model_flag"' '"$engine_flag"' "$(cat "$1")" > "$2" 2>&1' _ "$input_file" "$out_file" || true
      else
        timeout "$timeout" bash -c 'kiro-cli chat --no-interactive -a --wrap never '"$model_flag"' '"$engine_flag"' "$(cat "$1")" > "$2" 2>&1' _ "$input_file" "$out_file" || true
      fi
      strip_ansi < "$out_file"
      rm -f "$out_file"
      ;;
  esac
  rm -f "$input_file"
}

# Send output to judge, get SCORE and REASON
judge_output() {
  local output="$1" criteria="$2" ideal="${3:-}" session_summary="${4:-}"

  local behavioral_section=""
  if [[ -n "$session_summary" ]]; then
    behavioral_section="
BEHAVIORAL CONTEXT (from session log — factor this into your scoring):
$session_summary

NOTE: Excessive tool calls, error loops, or scope violations should lower the score even if the final output looks correct. Efficient execution with appropriate tool usage should be considered positively.
"
  fi

  local judge_prompt="You are an evaluation judge. Score the following agent output on a 1-5 scale.

CRITERIA:
$criteria
$behavioral_section
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

  # Judge runs in isolated empty dir (no skills, no context contamination)
  # Try available tools as judge — fail gracefully if one is unavailable
  local judge_dir=$(mktemp -d -t "judge-XXXX")
  local judge_result=""
  local judge_tool_used=""

  # Try kiro-cli first (primary), then codex, then crush, then agy
  if command -v kiro-cli &>/dev/null; then
    judge_result=$(cd "$judge_dir" && kiro-cli chat --no-interactive --model "$JUDGE_MODEL" --wrap never "$judge_prompt" 2>/dev/null | strip_ansi) && judge_tool_used="kiro-cli"
  fi

  if [[ -z "$judge_tool_used" ]] && command -v codex &>/dev/null; then
    judge_result=$(cd "$judge_dir" && codex exec --skip-git-repo-check "$judge_prompt" 2>/dev/null | strip_ansi) && judge_tool_used="codex"
  fi

  if [[ -z "$judge_tool_used" ]] && command -v crush &>/dev/null; then
    judge_result=$(cd "$judge_dir" && crush run --quiet --model glm/glm-5.2 "$judge_prompt" 2>/dev/null) && judge_tool_used="crush"
  fi

  if [[ -z "$judge_tool_used" ]] && command -v agy &>/dev/null; then
    judge_result=$(cd "$judge_dir" && agy --print "$judge_prompt" 2>/dev/null | strip_ansi) && judge_tool_used="agy"
  fi

  if [[ -z "$judge_tool_used" ]]; then
    echo "[warn] No judge tool available (tried: kiro-cli, codex, crush, agy)" >&2
    judge_result="SCORE: 0
REASON: no judge tool available"
  fi

  rm -rf "$judge_dir"
  echo "$judge_result"
}

# Parse score from judge output
parse_score() {
  local judge_output="$1"
  echo "$judge_output" | grep -o 'SCORE: *[0-9]*' | grep -o '[0-9]*$' | tail -1 || echo "0"
}

parse_reason() {
  local judge_output="$1"
  echo "$judge_output" | grep -o 'REASON: .*' | sed 's/^REASON: //' | tail -1 || echo "parse error"
}

# Run a single eval (standard or dual-run)
run_eval() {
  local def_file="$1"
  local name=$(yq '.name' "$def_file")
  local skill=$(yq '.skill // ""' "$def_file")
  local threshold=$(yq '.threshold // 4' "$def_file")
  local delta_threshold=$(yq '.delta_threshold // .acceptance.min_delta // 0' "$def_file")
  local timeout=$(yq '.timeout // 120' "$def_file")
  local fixture=$(yq '.fixture // ""' "$def_file")
  local def_trials=$(yq '.trials // 0' "$def_file")
  local run_trials=${def_trials:-$TRIALS}
  [[ "$run_trials" == "0" || "$run_trials" == "null" ]] && run_trials=$TRIALS

  TOTAL=$((TOTAL + 1))

  # Resolve conditions: new format (conditions:) or legacy (runs:)
  local -A condition_skills=()
  local -A condition_steering=()
  local condition_names=()
  local has_conditions=$(yq '.conditions // null' "$def_file")

  if [[ "$has_conditions" != "null" ]]; then
    # New format: conditions map
    mapfile -t condition_names < <(yq '.conditions | keys | .[]' "$def_file")
    for cond in "${condition_names[@]}"; do
      local skills_list=$(yq ".conditions.${cond}.skills | join(\",\")" "$def_file")
      condition_skills["$cond"]="$skills_list"
      # Parse steering files per condition
      local steering_list=$(yq ".conditions.${cond}.steering // [] | join(\",\")" "$def_file")
      condition_steering["$cond"]="$steering_list"
    done
  else
    # Legacy format: runs.with_skill / runs.without_skill
    local is_dual_run=$(yq '.runs.without_skill // false' "$def_file")
    if [[ "$is_dual_run" == "true" ]]; then
      condition_names=("with-skill" "baseline")
      condition_skills["with-skill"]="$skill"
      condition_skills["baseline"]=""
    else
      condition_names=("with-skill")
      condition_skills["with-skill"]="$skill"
    fi
  fi

  local is_comparison=$(( ${#condition_names[@]} > 1 ))

  # Collect tasks
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

  # Run each condition
  declare -A cond_scores=()
  declare -A cond_stddev=()
  declare -A cond_min=()
  declare -A cond_max=()
  local activation_count=0 activation_total=0
  local task_scores_json="["

  for cond in "${condition_names[@]}"; do
    local cond_all_scores=()
    IFS=',' read -ra skills_arr <<< "${condition_skills[$cond]}"

    for task_idx in "${!inputs[@]}"; do
      local input="${inputs[$task_idx]}"
      local criteria="${criterias[$task_idx]}"
      local ideal="${ideals[$task_idx]}"
      local task_trial_scores=()

      for trial in $(seq 1 "$run_trials"); do
        local workdir=$(mktemp -d -t "eval-${name}-${cond}-XXXX")
        [[ -n "$fixture" ]] && setup_fixture "$workdir" "$fixture"

        # Deploy all skills for this condition
        for s in "${skills_arr[@]}"; do
          [[ -z "$s" ]] && continue
          local skill_src="$EVALS_DIR/../../atomics/skills/$s/SKILL.md"
          if [[ -f "$skill_src" ]]; then
            local skill_dest="$workdir/$(echo "$SKILL_LOCATION" | sed "s/{name}/$s/")"
            mkdir -p "$(dirname "$skill_dest")"
            cp "$skill_src" "$skill_dest"
          fi
        done

        # Deploy steering files for this condition
        IFS=',' read -ra steering_arr <<< "${condition_steering[$cond]:-}"
        for st in "${steering_arr[@]}"; do
          [[ -z "$st" ]] && continue
          local steering_src="$EVALS_DIR/steering/$st"
          if [[ -f "$steering_src" ]]; then
            case "$ADAPTER" in
              codex|agy)
                # Codex/agy reads steering from AGENTS.md — append steering content
                mkdir -p "$workdir"
                cat "$steering_src" >> "$workdir/AGENTS.md"
                ;;
              *)
                local steering_dest="$workdir/.kiro/steering/$st"
                mkdir -p "$(dirname "$steering_dest")"
                cp "$steering_src" "$steering_dest"
                ;;
            esac
          else
            echo "[warn] Steering file not found: $steering_src" >&2
          fi
        done

        local output
        output=$(invoke_agent "$workdir" "$input" "" "$timeout")

        # Save output for activation detection and post-hoc analysis
        echo "$output" > "$workdir/.eval-output"
        if [[ -d "$RUN_DIR" ]]; then
          mkdir -p "$RUN_DIR/outputs"
          echo "$output" > "$RUN_DIR/outputs/${cond}-task${task_idx}-trial${trial}.txt"
        fi

        # Extract session behavioral summary for judge context
        local session_summary=""
        local use_log_analysis=$(yq '.log_analysis.include_in_judge // true' "$def_file")
        if [[ "$DRY_RUN" != true && "$use_log_analysis" != "false" ]]; then
          session_summary=$("$SCRIPT_DIR/extract-session-summary.sh" --adapter "$ADAPTER" 2>/dev/null) || session_summary=""
        fi

        # Apply log penalties (hard score adjustments)
        local log_penalty=0
        if [[ "$DRY_RUN" != true ]]; then
          local max_tools=$(yq '.log_analysis.penalties.max_tool_calls // 0' "$def_file")
          if [[ "$max_tools" -gt 0 && -n "$session_summary" ]]; then
            local actual_tools=$(echo "$session_summary" | grep -o 'Total tool invocations: [0-9]*' | grep -o '[0-9]*$' || echo 0)
            [[ "$actual_tools" -gt "$max_tools" ]] && log_penalty=$((log_penalty + 1))
          fi
          local max_retries=$(yq '.log_analysis.penalties.max_retries // 0' "$def_file")
          if [[ "$max_retries" -gt 0 && -n "$session_summary" ]]; then
            local actual_retries=$(echo "$session_summary" | grep -o 'Retry patterns detected: [0-9]*' | grep -o '[0-9]*$' || echo 0)
            [[ "$actual_retries" -gt "$max_retries" ]] && log_penalty=$((log_penalty + 1))
          fi
        fi

        local judge_result
        judge_result=$(judge_output "$output" "$criteria" "$ideal" "$session_summary")
        local score
        score=$(parse_score "$judge_result")
        # Apply log penalties (floor at 1)
        if [[ $log_penalty -gt 0 ]]; then
          score=$((score - log_penalty))
          [[ $score -lt 1 ]] && score=1
        fi
        cond_all_scores+=("$score")
        task_trial_scores+=("$score")

        # Check activation for first skill in list
        if [[ "$DRY_RUN" != true && ${#skills_arr[@]} -gt 0 && -n "${skills_arr[0]}" ]]; then
          activation_total=$((activation_total + 1))
          if "$SCRIPT_DIR/check-activation.sh" "$workdir" "${skills_arr[0]}" &>/dev/null; then
            activation_count=$((activation_count + 1))
          fi
        fi

        rm -rf "$workdir"
      done

      # Per-task average for this condition
      local task_sum=0
      for s in "${task_trial_scores[@]}"; do task_sum=$((task_sum + s)); done
      local task_avg=$(echo "scale=2; $task_sum / ${#task_trial_scores[@]}" | bc | sed 's/^\./0./;s/^-\./-0./')
      task_scores_json="$task_scores_json{\"task\":$task_idx,\"condition\":\"$cond\",\"avg\":$task_avg,\"scores\":[$(IFS=,; echo "${task_trial_scores[*]}")]}"
      # Add comma if not last
      if [[ $task_idx -lt $((${#inputs[@]} - 1)) || "$cond" != "${condition_names[-1]}" ]]; then
        task_scores_json="$task_scores_json,"
      fi
    done

    # Compute average, stddev, min, max for this condition
    local sum=0 count=${#cond_all_scores[@]}
    if [[ $count -eq 0 ]]; then
      cond_scores["$cond"]="0"
      cond_stddev["$cond"]="0"
      cond_min["$cond"]="0"
      cond_max["$cond"]="0"
      continue
    fi
    local min_s=${cond_all_scores[0]} max_s=${cond_all_scores[0]}
    for s in "${cond_all_scores[@]}"; do
      sum=$((sum + s))
      [[ $s -lt $min_s ]] && min_s=$s
      [[ $s -gt $max_s ]] && max_s=$s
    done
    local avg=$(echo "scale=2; $sum / $count" | bc | sed 's/^\./0./;s/^-\./-0./')
    # Population stddev (intentional: measuring all trials, not sampling)
    local sq_sum=0
    for s in "${cond_all_scores[@]}"; do
      sq_sum=$(echo "$sq_sum + ($s - $avg)^2" | bc -l)
    done
    local stddev=$(echo "scale=2; sqrt($sq_sum / $count)" | bc -l | sed 's/^\./0./;s/^-\./-0./')

    cond_scores["$cond"]="$avg"
    cond_stddev["$cond"]="$stddev"
    cond_min["$cond"]="$min_s"
    cond_max["$cond"]="$max_s"
  done
  task_scores_json="$task_scores_json]"

  # Compute results
  local status="PASS" reason="" avg_score=0 delta=0

  if [[ $is_comparison -eq 1 ]]; then
    # Find the primary condition (first non-baseline) and baseline
    local primary_cond="" baseline_cond=""
    for cond in "${condition_names[@]}"; do
      if [[ "$cond" == "baseline" ]]; then
        baseline_cond="$cond"
      elif [[ -z "$primary_cond" ]]; then
        primary_cond="$cond"
      fi
    done
    [[ -z "$baseline_cond" ]] && baseline_cond="${condition_names[-1]}"
    [[ -z "$primary_cond" ]] && primary_cond="${condition_names[0]}"

    local avg_primary=${cond_scores[$primary_cond]}
    local avg_baseline=${cond_scores[$baseline_cond]}
    delta=$(echo "scale=2; $avg_primary - $avg_baseline" | bc | sed 's/^\./0./;s/^-\./-0./')
    avg_score=$avg_primary

    if [[ "$(echo "$avg_primary < $threshold" | bc)" == 1* ]]; then
      status="FAIL"; reason="$primary_cond avg $avg_primary < threshold $threshold"
    elif [[ "$(echo "$delta < $delta_threshold" | bc)" == 1* ]]; then
      status="FAIL"; reason="delta $delta < delta_threshold $delta_threshold"
    else
      reason="$primary_cond=$avg_primary $baseline_cond=$avg_baseline delta=$delta"
    fi
  else
    # Single condition: majority pass
    local cond="${condition_names[0]}"
    avg_score=${cond_scores[$cond]}
    if [[ "$(echo "$avg_score < $threshold" | bc)" == 1* ]]; then
      status="FAIL"; reason="avg $avg_score < threshold $threshold"
    else
      reason="avg=$avg_score (threshold=$threshold)"
    fi
  fi

  # Report
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
    activation_rate=$(echo "scale=2; $activation_count / $activation_total" | bc | sed 's/^\./0./;s/^-\./-0./')
  fi
  local escaped_reason="${reason//\\/\\\\}"
  escaped_reason="${escaped_reason//\"/\\\"}"
  local score_line="{\"name\":\"$name\",\"status\":\"$status\",\"score\":$avg_score,\"reason\":\"$escaped_reason\",\"activated\":$activation_count,\"activation_total\":$activation_total,\"activation_rate\":$activation_rate"
  if [[ $is_comparison -eq 1 ]]; then
    local primary_cond="" baseline_cond=""
    for cond in "${condition_names[@]}"; do
      if [[ "$cond" == "baseline" ]]; then baseline_cond="$cond"
      elif [[ -z "$primary_cond" ]]; then primary_cond="$cond"; fi
    done
    [[ -z "$baseline_cond" ]] && baseline_cond="${condition_names[-1]}"
    [[ -z "$primary_cond" ]] && primary_cond="${condition_names[0]}"
    score_line="$score_line,\"with_score\":${cond_scores[$primary_cond]},\"with_stddev\":${cond_stddev[$primary_cond]},\"with_min\":${cond_min[$primary_cond]},\"with_max\":${cond_max[$primary_cond]},\"without_score\":${cond_scores[$baseline_cond]},\"without_stddev\":${cond_stddev[$baseline_cond]},\"without_min\":${cond_min[$baseline_cond]},\"without_max\":${cond_max[$baseline_cond]},\"delta\":$delta"
  else
    local cond="${condition_names[0]}"
    score_line="$score_line,\"stddev\":${cond_stddev[$cond]},\"min\":${cond_min[$cond]},\"max\":${cond_max[$cond]}"
  fi
  score_line="$score_line,\"task_scores\":$task_scores_json}"
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
