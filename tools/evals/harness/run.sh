#!/bin/bash
# tools/evals/harness/run.sh — LLM-as-judge eval harness with dual-run support
# Usage: ./run.sh [--adapter kiro-cli|crush|codex|agy] [--definition name] [--all] [--dry-run] [--trials 3] [--engine v2|v3] [--skip-completed <results-dir>]
#   --skip-completed <dir>: resume an interrupted run — skip definitions already scored in <dir>/scores.jsonl, append new scores into <dir>
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
RESUME_DIR=""
CHANGED_ONLY_DIR=""
JUDGE_ONLY_DIR=""
PROBE_TIMEOUT="${EVAL_PROBE_TIMEOUT:-30}"

# Identity hashes (ticket 33): one hashing implementation shared with check-staleness.sh
source "$SCRIPT_DIR/identity.sh"

while [[ $# -gt 0 ]]; do
  case $1 in
    --adapter) ADAPTER="$2"; shift 2 ;;
    --definition) DEFINITION="$2"; shift 2 ;;
    --all) RUN_ALL=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --isolated) ISOLATED=true; shift ;;
    --trials) TRIALS="$2"; shift 2 ;;
    --model) MODEL="$2"; shift 2 ;;
    --changed-only) CHANGED_ONLY_DIR="$2"; shift 2 ;;
    --judge-only) JUDGE_ONLY_DIR="$2"; shift 2 ;;
    --engine) ENGINE="$2"; shift 2 ;;
    --judge) JUDGE_CONFIG="$2"; shift 2 ;;
    --skip-completed) RESUME_DIR="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

# Validate tools
for cmd in yq; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: $cmd required" >&2; exit 2
  fi
done
# Adapter availability is verified by a live access probe at first use
# (ensure_agent_probed) — PATH presence != model access. No-access defs SKIP.

# Validate trials
[[ "$TRIALS" -gt 0 ]] 2>/dev/null || { echo "Error: --trials must be > 0" >&2; exit 1; }

# Policy gate (ticket 36): agy agent leg never runs on corp — before any probe
if [[ "$ADAPTER" == "agy" && "${CREW_ENV:-}" == "corp" ]]; then
  echo "Error: policy-blocked (CREW_ENV=corp) — agy may not run on corp machines (company policy)." >&2
  exit 1
fi

# Validate changed-only baseline
if [[ -n "$CHANGED_ONLY_DIR" ]]; then
  [[ -f "$CHANGED_ONLY_DIR/scores.jsonl" ]] || { echo "Error: --changed-only dir has no scores.jsonl: $CHANGED_ONLY_DIR" >&2; exit 2; }
fi
CHANGED_ONLY_CURRENT=()

# Load adapter
ADAPTER_FILE="$ADAPTERS_DIR/$ADAPTER.yaml"
[[ -f "$ADAPTER_FILE" ]] || { echo "Error: adapter not found: $ADAPTER_FILE" >&2; exit 2; }

TOOL_NAME=$(yq '.tool' "$ADAPTER_FILE")
VERSION_CMD=$(yq '.version_command' "$ADAPTER_FILE")
INVOKE_CMD=$(yq '.invoke.command' "$ADAPTER_FILE")
INVOKE_NO_AGENT_CMD=$(yq '.invoke.command_no_agent' "$ADAPTER_FILE")
DEFAULT_TIMEOUT=$(yq '.invoke.timeout // 90' "$ADAPTER_FILE")
SKILL_LOCATION=$(yq '.skill.location' "$ADAPTER_FILE")

# Load judge config. Every leg's model comes from the config — the judge tier policy
# (ticket 35) is only enforceable if no leg silently rides a tool default.
JUDGE_MODEL=$(yq '.judges[0].model // .model // "claude-opus-5"' "$JUDGE_CONFIG")
judge_model_for() {  # judge_model_for <tool> : model id, or "" for tool default
  local m
  m=$(yq ".judges[] | select(.tool == \"$1\") | .model" "$JUDGE_CONFIG" 2>/dev/null | head -1)
  [[ "$m" == "null" ]] && m=""
  echo "$m"
}
JUDGE_MODEL_CODEX=$(judge_model_for codex)
JUDGE_MODEL_CRUSH="${CREW_CRUSH_JUDGE_MODEL:-$(judge_model_for crush)}"
JUDGE_MODEL_AGY=$(judge_model_for agy)
JUDGE_MODE=$(yq '.mode // "single"' "$JUDGE_CONFIG")
JUDGE_TEMP=$(yq '.temperature' "$JUDGE_CONFIG")

# Metadata
TOOL_VERSION=$($VERSION_CMD 2>/dev/null | head -1 || echo "unknown")
TIMESTAMP=$(date -u +%Y-%m-%dT%H-%M-%SZ)
COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

echo "Eval harness: $TOOL_NAME ($TOOL_VERSION)"
echo "Judge: $JUDGE_MODE (candidates: ${JUDGE_MODEL}+codex+crush+agy — live set probed at first judging call) | Trials: $TRIALS | Dry-run: $DRY_RUN"
echo "Timestamp: $TIMESTAMP"
echo ""

# Collect definitions
DEFS=()
if [[ -n "$JUDGE_ONLY_DIR" ]]; then
  # Re-judge mode (ticket 32): defs come from the results dir's scores.jsonl
  [[ -d "$JUDGE_ONLY_DIR" ]] || JUDGE_ONLY_DIR="$RESULTS_DIR/$JUDGE_ONLY_DIR"
  [[ -f "$JUDGE_ONLY_DIR/scores.jsonl" && -d "$JUDGE_ONLY_DIR/outputs" ]] || { echo "Error: --judge-only dir needs scores.jsonl + outputs/: $JUDGE_ONLY_DIR" >&2; exit 2; }
  DEFS=()
elif [[ -n "$DEFINITION" ]]; then
  DEFS=("$DEFINITIONS_DIR/$DEFINITION.yaml")
elif [[ "$RUN_ALL" == true ]]; then
  # Exclude retired/ and activation-* (activation defs lack criteria; run-activation.sh is their harness)
  mapfile -t DEFS < <(find "$DEFINITIONS_DIR" -name "*.yaml" -not -path "*/retired/*" -not -name "activation-*" | sort)
else
  echo "Specify --definition <name> or --all" >&2; exit 1
fi

[[ ${#DEFS[@]} -gt 0 || -n "$JUDGE_ONLY_DIR" ]] || { echo "No definitions found." >&2; exit 1; }

# Resume mode: skip definitions already scored in a prior run's dir, append into that dir
if [[ -n "$RESUME_DIR" ]]; then
  [[ -d "$RESUME_DIR" ]] || RESUME_DIR="$RESULTS_DIR/$RESUME_DIR"
  [[ -d "$RESUME_DIR" ]] || { echo "Error: --skip-completed dir not found: $RESUME_DIR" >&2; exit 2; }
  RESUME_SCORES="$RESUME_DIR/scores.jsonl"
  REMAINING_DEFS=()
  for def_file in "${DEFS[@]}"; do
    def_name=$(yq '.name' "$def_file")
    # A SKIP row is not a completed def — only scored (PASS/FAIL) rows count
    if [[ -f "$RESUME_SCORES" ]] && grep "\"name\":\"$def_name\"" "$RESUME_SCORES" | grep -qv '"status":"SKIP"'; then
      echo "  ⏭  $def_name — already completed in $(basename "$RESUME_DIR"), skipping"
    else
      REMAINING_DEFS+=("$def_file")
    fi
  done
  DEFS=("${REMAINING_DEFS[@]+"${REMAINING_DEFS[@]}"}")
  if [[ ${#DEFS[@]} -eq 0 ]]; then
    echo ""
    echo "All definitions already completed in $RESUME_DIR — nothing to do."
    exit 0
  fi
  echo ""
fi

if [[ -z "$JUDGE_ONLY_DIR" ]]; then
  echo "Running ${#DEFS[@]} eval(s)..."
  echo ""
fi

# Results setup — resume mode appends into the prior run's dir; judge-only
# writes NEW files into the source dir (original scores.jsonl is never touched)
if [[ -n "$JUDGE_ONLY_DIR" ]]; then
  RUN_DIR="$JUDGE_ONLY_DIR"
elif [[ -n "$RESUME_DIR" ]]; then
  RUN_DIR="$RESUME_DIR"
else
  RUN_DIR="$RESULTS_DIR/$TIMESTAMP"
fi
mkdir -p "$RUN_DIR"

# Warm up recall embedding model (avoids first-run latency in trials)
if command -v recall &>/dev/null; then
  recall search "warmup" --results 1 >/dev/null 2>&1 || true
fi

TOTAL=0; PASSED=0; FAILED=0; SKIPPED=0
SCORES_FILE="$RUN_DIR/scores.jsonl"
# Resume mode appends to existing scores; judge-only never touches the original; fresh runs start clean
[[ -n "$RESUME_DIR" || -n "$JUDGE_ONLY_DIR" ]] || : > "$SCORES_FILE"

# Emit a SKIP row: pending-with-reason, never silent (extension-protocol principle).
# SKIPs are excluded from pass/fail tallies and do NOT count as completed for --skip-completed.
emit_skip() {
  local name="$1" def_id="$2" why="$3"
  SKIPPED=$((SKIPPED + 1))
  echo "  ⏭  SKIP $name — $why"
  # Resume mode: don't append duplicate SKIP rows across resumes
  if [[ -n "$RESUME_DIR" && -f "$SCORES_FILE" ]] && grep "\"name\":\"$name\"" "$SCORES_FILE" | grep -q '"status":"SKIP"'; then
    return
  fi
  local id_json="null"
  [[ -n "$def_id" ]] && id_json="\"$def_id\""
  echo "{\"id\":$id_json,\"name\":\"$name\",\"adapter\":\"$ADAPTER\",\"status\":\"SKIP\",\"reason\":\"$why\",\"judges\":[],\"skill_hash\":null,\"def_hash\":null,\"env_id\":null}" >> "$SCORES_FILE"
}

strip_ansi() { sed 's/\x1B\[[0-9;]*[a-zA-Z]//g'; }

# --- Adapter access probes ---------------------------------------------------
# PATH presence != model access (verified 2026-07-19: crush spawns but scores
# nothing; codex exec dies on untrusted temp dirs with stderr discarded).
# A tool is "live" only when a tiny real prompt produces the expected token.
declare -A PROBE_RESULTS=()   # tool -> "live" | "dead"

probe_tool() {
  local tool="$1"
  if [[ -n "${PROBE_RESULTS[$tool]:-}" ]]; then
    [[ "${PROBE_RESULTS[$tool]}" == "live" ]]; return
  fi
  local verdict="dead"
  if command -v "$tool" &>/dev/null; then
    local probe_dir out=""
    probe_dir=$(mktemp -d -t "probe-${tool}-XXXX")
    case "$tool" in
      kiro-cli) out=$(cd "$probe_dir" && timeout "$PROBE_TIMEOUT" kiro-cli chat --no-interactive --wrap never "Reply with exactly: OK" </dev/null 2>/dev/null | strip_ansi) || true ;;
      codex)    out=$(cd "$probe_dir" && timeout "$PROBE_TIMEOUT" codex exec -s read-only --skip-git-repo-check "Reply with exactly: OK" </dev/null 2>/dev/null | strip_ansi) || true ;;
      crush)    out=$(cd "$probe_dir" && timeout "$PROBE_TIMEOUT" crush run --quiet --model "${MODEL:-${JUDGE_MODEL_CRUSH:-glm-5.2}}" "Reply with exactly: OK" </dev/null 2>/dev/null | strip_ansi) || true ;;
      agy)      out=$(cd "$probe_dir" && timeout "$PROBE_TIMEOUT" agy --print "Reply with exactly: OK" </dev/null 2>/dev/null | strip_ansi) || true ;;
    esac
    rm -rf "$probe_dir"
    grep -q "OK" <<< "$out" && verdict="live"
  fi
  PROBE_RESULTS[$tool]="$verdict"
  [[ "$verdict" == "live" ]]
}

# Agent probe — lazy, once per run, only when a def actually needs to run
AGENT_PROBED=false
AGENT_LIVE=false
ensure_agent_probed() {
  [[ "$AGENT_PROBED" == true ]] && return 0
  AGENT_PROBED=true
  [[ "$DRY_RUN" == true ]] && { AGENT_LIVE=true; return 0; }
  if probe_tool "$ADAPTER"; then
    AGENT_LIVE=true
  else
    echo "  ⚠️  Agent adapter '$ADAPTER' failed access probe (on PATH: $(command -v "$ADAPTER" &>/dev/null && echo yes || echo no)) — defs will SKIP" >&2
  fi
}

# Judge probes — lazy, once per run, before the first judging call
JUDGES_PROBED=false
LIVE_JUDGES=()          # subset of kiro codex crush agy
JUDGES_EXCLUDED=""      # "crush (probe failed), agy (not on PATH)"
ensure_judges_probed() {
  [[ "$JUDGES_PROBED" == true ]] && return 0
  JUDGES_PROBED=true
  [[ "$DRY_RUN" == true ]] && return 0
  local tool short
  for tool in kiro-cli codex crush agy; do
    short="${tool%%-*}"   # kiro-cli -> kiro
    # Policy gate (ticket 36): agy never runs on corp — checked BEFORE command -v
    # so the reason string can't be conflated with an access failure
    if [[ "$tool" == "agy" && "${CREW_ENV:-}" == "corp" ]]; then
      JUDGES_EXCLUDED="${JUDGES_EXCLUDED:+$JUDGES_EXCLUDED, }$short (policy-blocked (CREW_ENV=corp))"
      continue
    fi
    if probe_tool "$tool"; then
      LIVE_JUDGES+=("$short")
    else
      local why="probe failed"
      command -v "$tool" &>/dev/null || why="not on PATH"
      JUDGES_EXCLUDED="${JUDGES_EXCLUDED:+$JUDGES_EXCLUDED, }$short ($why)"
    fi
  done
  echo "  Judges live: ${LIVE_JUDGES[*]:-none}${JUDGES_EXCLUDED:+ | excluded: $JUDGES_EXCLUDED}"
}

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
    # Run install for workspace-injection fixtures (e.g. generate test files)
    if [[ -n "$install_cmd" && "$install_cmd" != "null" && "$install_cmd" != "" ]]; then
      (cd "$workdir" && eval "$install_cmd" > /dev/null 2>&1) || { echo "[warn] Fixture install failed" >&2; }
    fi
  fi
}

# Invoke agent in isolated workspace, capture output
invoke_agent() {
  local workdir="$1" input="$2" skill_name="${3:-}" timeout="${4:-$DEFAULT_TIMEOUT}"

  # Deploy skill if specified
  if [[ -n "$skill_name" ]]; then
    local skill_dir="$EVALS_DIR/../../atomics/skills/$skill_name"
    local skill_src="$skill_dir/SKILL.md"
    if [[ -f "$skill_src" ]]; then
      local skill_dest="$workdir/$(echo "$SKILL_LOCATION" | sed "s/{name}/$skill_name/")"
      mkdir -p "$(dirname "$skill_dest")"
      cp "$skill_src" "$skill_dest"
      # Also deploy references/ if present
      if [[ -d "$skill_dir/references" ]]; then
        local ref_dest="$(dirname "$skill_dest")/references"
        mkdir -p "$ref_dest"
        cp "$skill_dir/references/"* "$ref_dest/" 2>/dev/null || true
      fi
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
      # Isolate skills to workdir — prevents global ~/.agents/skills leaking into eval
      local crush_skills_dir="$workdir/.agents/skills"
      timeout "$timeout" bash -c 'cd "$1" && CRUSH_SKILLS_DIR="$3" crush run --quiet '"$model_flag"' "$(cat "$2")"' _ "$workdir" "$input_file" "$crush_skills_dir" 2>&1 | strip_ansi || true
      ;;
    codex)
      local model_flag=""
      [[ -n "$MODEL" ]] && model_flag="--model $MODEL"
      timeout "$timeout" bash -c 'codex exec --dangerously-bypass-approvals-and-sandbox --ephemeral '"$model_flag"' -C "$1" "$(cat "$2")" < /dev/null' _ "$workdir" "$input_file" 2>&1 | strip_ansi || true
      ;;
    agy)
      local model_flag=""
      [[ -n "$MODEL" ]] && model_flag="--model $MODEL"
      # --add-dir ensures agy sees the workspace files; print mode soft-denies
      # tool calls (Issue #548), so tasks requiring file reads may not work
      timeout "$timeout" bash -c 'cd "$1" && agy --print --add-dir "$1" '"$model_flag"' "$(cat "$2")"' _ "$workdir" "$input_file" 2>&1 | strip_ansi || true
      ;;
    *)
      local model_flag=""
      [[ -n "$MODEL" ]] && model_flag="--model $MODEL"
      local engine_flag=""
      [[ -n "$ENGINE" ]] && engine_flag="--agent-engine $ENGINE"
      local env_prefix=""
      # Always isolate kiro-cli to workdir .kiro — prevents global steering leaking into eval conditions
      if [[ -d "$workdir/.kiro" ]]; then
        env_prefix="KIRO_HOME=$workdir/.kiro"
      elif [[ "$ISOLATED" == true ]]; then
        mkdir -p "$workdir/.kiro-isolated"
        [[ -d "$workdir/.kiro/skills" ]] && cp -r "$workdir/.kiro/skills" "$workdir/.kiro-isolated/"
        env_prefix="KIRO_HOME=$workdir/.kiro-isolated"
      fi
      local out_file=$(mktemp)
      if [[ -n "$env_prefix" ]]; then
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
    echo "JUDGES:"
    return
  fi

  # Multi-model consensus judging
  # Run all available judge models in parallel, take median score
  local judge_dir=$(mktemp -d -t "judge-XXXX")
  local scores=()
  local reasons=()

  # Write prompt to file (avoids shell quoting issues with large prompts)
  local prompt_file="$judge_dir/prompt.txt"
  printf '%s' "$judge_prompt" > "$prompt_file"

  # Run live judges in parallel (probed once per run — see ensure_judges_probed)
  ensure_judges_probed
  local pids=()
  local j
  for j in "${LIVE_JUDGES[@]+"${LIVE_JUDGES[@]}"}"; do
    case "$j" in
      kiro)
        (cd "$judge_dir" && kiro-cli chat --no-interactive --model "$JUDGE_MODEL" --wrap never "$(cat "$prompt_file")" 2>/dev/null | strip_ansi > "$judge_dir/result-kiro.txt") &
        pids+=($!) ;;
      codex)
        # --skip-git-repo-check: codex exec silently dies in untrusted temp dirs
        # (discovered 2026-07-19 — the leg produced zero scores in every prior run)
        (cd "$judge_dir" && timeout 60 codex exec -s read-only --skip-git-repo-check ${JUDGE_MODEL_CODEX:+-m "$JUDGE_MODEL_CODEX"} "$(cat "$prompt_file")" </dev/null 2>/dev/null | strip_ansi > "$judge_dir/result-codex.txt") &
        pids+=($!) ;;
      crush)
        (cd "$judge_dir" && timeout 60 crush run --quiet ${JUDGE_MODEL_CRUSH:+--model "$JUDGE_MODEL_CRUSH"} "$(cat "$prompt_file")" 2>/dev/null > "$judge_dir/result-crush.txt") &
        pids+=($!) ;;
      agy)
        (cd "$judge_dir" && timeout 60 agy --print "$(cat "$prompt_file")" 2>/dev/null | strip_ansi > "$judge_dir/result-agy.txt") &
        pids+=($!) ;;
    esac
  done

  # Wait for all judges
  for pid in "${pids[@]}"; do
    wait "$pid" 2>/dev/null || true
  done

  # Collect scores from all judges
  local judge_names=()
  for result_file in "$judge_dir"/result-*.txt; do
    [[ -f "$result_file" ]] || continue
    local s=$(grep -o 'SCORE: *[0-9]*' "$result_file" | grep -o '[0-9]*$' | tail -1)
    local r=$(grep -o 'REASON: .*' "$result_file" | sed 's/^REASON: //' | tail -1)
    local judge_name=$(basename "$result_file" .txt | sed 's/result-//')
    if [[ -n "$s" && "$s" -ge 1 && "$s" -le 5 ]]; then
      scores+=("$s")
      judge_names+=("$judge_name")
      reasons+=("[$judge_name:$s] ${r:-no reason}")
    fi
  done

  rm -rf "$judge_dir"

  # Compute median score
  if [[ ${#scores[@]} -eq 0 ]]; then
    echo "SCORE: 0"
    echo "REASON: no judge produced a valid score"
    echo "JUDGES:"
    return
  fi

  local sorted_scores=($(printf '%s\n' "${scores[@]}" | sort -n))
  local n=${#sorted_scores[@]}
  local median_idx=$(( (n - 1) / 2 ))
  local median_score=${sorted_scores[$median_idx]}

  # Return median score with all judge reasons + participating judges
  echo "SCORE: $median_score"
  echo "REASON: median of $n judges [${scores[*]}] — ${reasons[0]}"
  echo "JUDGES: ${judge_names[*]}"
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

# Participating judges as a JSON string array: ["kiro","codex"]
parse_judges() {
  local judge_output="$1"
  local names
  names=$(echo "$judge_output" | grep -o '^JUDGES:.*' | sed 's/^JUDGES:*//' | tail -1)
  if [[ -z "${names// /}" ]]; then
    echo "[]"
  else
    printf '%s\n' "$names" | awk '{out=""; for(i=1;i<=NF;i++){out=out (i>1?",":"") "\""$i"\""} print "["out"]"}'
  fi
}

# Run a single eval (standard or dual-run)
run_eval() {
  local def_file="$1"

  # Batch-extract frontmatter fields in one yq call (ticket 65: reduces forks on MSYS2).
  # For dry-run, this single call provides everything needed for the plan report.
  # Uses pipe delimiter (not @tsv) because IFS=$'\t' collapses consecutive tabs (empty fields).
  local _fields
  _fields=$(yq '[.name, (.id // ""), (.adapters // [] | join(",")), (.skill // "")] | join("|")' "$def_file")
  local name def_id def_adapters _skill_field
  IFS="|" read -r name def_id def_adapters _skill_field <<< "$_fields"
  [[ "$def_id" == "null" ]] && def_id=""
  [[ "$def_adapters" == "null" ]] && def_adapters=""
  [[ "$_skill_field" == "null" ]] && _skill_field=""

  # Adapter scoping: a def listing adapters runs ONLY under those adapters
  if [[ -n "$def_adapters" && ",$def_adapters," != *",$ADAPTER,"* ]]; then
    emit_skip "$name" "$def_id" "needs adapter: $def_adapters"
    return
  fi

  # Dry-run early exit (ticket 65): discovery phase complete — report and return.
  # Skips hash computation, field extraction, agent/judge probes, and trial loop
  # which collectively spawn 750-900 forks (hanging on Windows/MSYS2).
  if [[ "$DRY_RUN" == true ]]; then
    echo "  ✓ $name (skill: ${_skill_field:-none}, adapter: $ADAPTER) — would run"
    TOTAL=$((TOTAL + 1))
    PASSED=$((PASSED + 1))
    return
  fi

  # Access probe: PATH presence != model access
  ensure_agent_probed
  if [[ "$AGENT_LIVE" != true ]]; then
    emit_skip "$name" "$def_id" "adapter $ADAPTER: no access (probe failed)"
    return
  fi

  # Probe judges in the PARENT shell — judge_output runs in a $(...) subshell,
  # so state set there (LIVE_JUDGES, JUDGES_PROBED) never reaches meta.json and
  # probing would silently repeat on every judging call
  ensure_judges_probed

  # Identity hashes (ticket 33): computed HERE, per def at execution time — not
  # once at run start — so a mid-run merge (the a03798e incident) stamps defs
  # before/after it with different hashes.
  local row_skill_hash row_def_hash row_env_id
  row_skill_hash=$(identity_skill_hash "$def_file")
  row_def_hash=$(identity_def_hash "$def_file")
  row_env_id=$(identity_env_id "$ADAPTER" "$TOOL_VERSION" "$MODEL" ${LIVE_JUDGES[@]+"${LIVE_JUDGES[@]}"})

  # --changed-only: skip defs whose baseline row matches all three components.
  # The baseline row remains the valid result; no new row is emitted.
  if [[ -n "$CHANGED_ONLY_DIR" ]]; then
    local base_line
    base_line=$(grep "\"name\":\"$name\"" "$CHANGED_ONLY_DIR/scores.jsonl" | tail -1)
    if [[ -n "$base_line" ]]; then
      local b_skill b_def b_env
      b_skill=$(sed -n 's/.*"skill_hash":"\([^"]*\)".*/\1/p' <<< "$base_line")
      b_def=$(sed -n 's/.*"def_hash":"\([^"]*\)".*/\1/p' <<< "$base_line")
      b_env=$(sed -n 's/.*"env_id":"\([^"]*\)".*/\1/p' <<< "$base_line")
      if [[ "$b_skill" == "$row_skill_hash" && "$b_def" == "$row_def_hash" && "$b_env" == "$row_env_id" ]]; then
        CHANGED_ONLY_CURRENT+=("$name")
        echo "  ⏭  $name — current vs baseline (skill/def/env all match), skipped"
        return
      fi
    fi
  fi

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
  local inputs=() criterias=() ideals=() task_fixtures=()

  if [[ $task_count -gt 0 ]]; then
    for i in $(seq 0 $((task_count - 1))); do
      inputs+=("$(yq ".tasks[$i].input" "$def_file")")
      criterias+=("$(yq ".tasks[$i].criteria" "$def_file")")
      ideals+=("$(yq ".tasks[$i].ideal // \"\"" "$def_file")")
      task_fixtures+=("$(yq ".tasks[$i].fixture // \"\"" "$def_file")")
    done
  else
    inputs+=("$(yq '.input' "$def_file")")
    criterias+=("$(yq '.criteria' "$def_file")")
    ideals+=("$(yq '.ideal // ""' "$def_file")")
    task_fixtures+=("")
  fi

  # Run each condition
  declare -A cond_scores=()
  declare -A cond_stddev=()
  declare -A cond_min=()
  declare -A cond_max=()
  declare -A row_judges=()
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
      local task_trial_judges=()

      for trial in $(seq 1 "$run_trials"); do
        local workdir=$(mktemp -d -t "eval-${name}-${cond}-XXXX")
        # Per-task fixture overrides def-level fixture
        local effective_fixture="${task_fixtures[$task_idx]:-}"
        [[ -z "$effective_fixture" ]] && effective_fixture="$fixture"
        [[ -n "$effective_fixture" ]] && setup_fixture "$workdir" "$effective_fixture"
        mkdir -p "$workdir/.kiro/skills" "$workdir/.kiro/steering"

        # Deploy all skills for this condition (SKILL.md + references/)
        for s in "${skills_arr[@]}"; do
          [[ -z "$s" ]] && continue
          local skill_dir="$EVALS_DIR/../../atomics/skills/$s"
          local skill_src="$skill_dir/SKILL.md"
          if [[ -f "$skill_src" ]]; then
            local skill_dest="$workdir/$(echo "$SKILL_LOCATION" | sed "s/{name}/$s/")"
            mkdir -p "$(dirname "$skill_dest")"
            cp "$skill_src" "$skill_dest"
            # Also deploy references/ if present (progressive loading companions)
            if [[ -d "$skill_dir/references" ]]; then
              local ref_dest="$(dirname "$skill_dest")/references"
              mkdir -p "$ref_dest"
              cp "$skill_dir/references/"* "$ref_dest/" 2>/dev/null || true
            fi
          fi
        done

        # Deploy steering files for this condition
        IFS=',' read -ra steering_arr <<< "${condition_steering[$cond]:-}"
        for st in "${steering_arr[@]}"; do
          [[ -z "$st" ]] && continue
          local steering_src="$EVALS_DIR/steering/$st"
          if [[ -f "$steering_src" ]]; then
            case "$ADAPTER" in
              codex|agy|crush)
                # Codex/agy/crush read steering from AGENTS.md — append steering content
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
          echo "$output" > "$RUN_DIR/outputs/${name}-${cond}-task${task_idx}-trial${trial}.txt"
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
        # Record judge participation for this trial
        task_trial_judges+=("$(parse_judges "$judge_result")")
        local jn
        for jn in $(echo "$judge_result" | grep -o '^JUDGES:.*' | sed 's/^JUDGES://'); do
          row_judges[$jn]=1
        done
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
      local task_judges_join=$(IFS=,; echo "${task_trial_judges[*]}")
      task_scores_json="$task_scores_json{\"task\":$task_idx,\"condition\":\"$cond\",\"avg\":$task_avg,\"scores\":[$(IFS=,; echo "${task_trial_scores[*]}")],\"judges\":[$task_judges_join]}"
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
  # Self-describing row: immutable id (joins survive renames), run adapter,
  # judge-set union, and null placeholders for ticket 33's identity hashes
  local id_json="null"
  [[ -n "$def_id" ]] && id_json="\"$def_id\""
  local judges_union="[]"
  if [[ ${#row_judges[@]} -gt 0 ]]; then
    judges_union=$(printf '%s\n' "${!row_judges[@]}" | sort | awk '{out=out (NR>1?",":"") "\""$1"\""} END{print "["out"]"}')
  fi
  local score_line="{\"id\":$id_json,\"name\":\"$name\",\"adapter\":\"$ADAPTER\",\"judges\":$judges_union,\"skill_hash\":\"$row_skill_hash\",\"def_hash\":\"$row_def_hash\",\"env_id\":\"$row_env_id\",\"status\":\"$status\",\"score\":$avg_score,\"reason\":\"$escaped_reason\",\"activated\":$activation_count,\"activation_total\":$activation_total,\"activation_rate\":$activation_rate"
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

# Re-judge an existing run's retained outputs (ticket 32). Criteria come from
# the def at the RECORDED commit (meta.json), scored by the CURRENTLY reachable
# judge set. Writes scores-rejudge-{ts}.jsonl + meta-rejudge-{ts}.json alongside
# the originals — never overwrites — and prints a verdict delta per def.
run_judge_only() {
  local src="$JUDGE_ONLY_DIR"
  local out_scores="$src/scores-rejudge-$TIMESTAMP.jsonl"
  local recorded_commit
  recorded_commit=$(sed -n 's/.*"commit": *"\([^"]*\)".*/\1/p' "$src/meta.json" 2>/dev/null | head -1)
  local repo_root; repo_root=$(_identity_repo_root)
  local tmp_defs; tmp_defs=$(mktemp -d -t "rejudge-defs-XXXX")

  ensure_judges_probed
  echo "Re-judging $(basename "$src") — recorded commit: ${recorded_commit:-unknown} | judges live: ${LIVE_JUDGES[*]:-none}"
  echo ""
  : > "$out_scores"
  local changed=0 total=0

  while IFS= read -r row; do
    [[ -z "$row" ]] && continue
    grep -q '"status":"SKIP"' <<< "$row" && continue
    local name orig_status orig_score
    name=$(sed -n 's/.*"name":"\([^"]*\)".*/\1/p' <<< "$row")
    orig_status=$(sed -n 's/.*"status":"\([^"]*\)".*/\1/p' <<< "$row")
    orig_score=$(sed -n 's/.*"score":\([0-9.]*\).*/\1/p' <<< "$row")
    total=$((total + 1))

    # Def at the recorded commit; fall back to the current tree with a marker
    local def_file="$tmp_defs/$name.yaml" criteria_source="commit:$recorded_commit"
    if [[ -z "$recorded_commit" ]] || ! git -C "$repo_root" show "$recorded_commit:tools/evals/definitions/$name.yaml" > "$def_file" 2>/dev/null; then
      criteria_source="current-tree"
      cp "$DEFINITIONS_DIR/$name.yaml" "$def_file" 2>/dev/null || cp "$DEFINITIONS_DIR/retired/$name.yaml" "$def_file" 2>/dev/null || {
        echo "  ⚠️  $name — def not found at recorded commit or current tree; skipped" >&2
        continue
      }
    fi
    local threshold delta_threshold
    threshold=$(yq '.threshold // 4' "$def_file")
    delta_threshold=$(yq '.delta_threshold // .acceptance.min_delta // 0' "$def_file")

    # Aggregate re-judged scores per condition from retained outputs
    local -A csum=() ccount=()
    local -A row_judges=()
    local task_scores_json="[" first_task=true
    local out_file
    for out_file in "$src/outputs/$name-"*.txt; do
      [[ -f "$out_file" ]] || continue
      local base cond task_idx
      base=$(basename "$out_file" .txt)
      task_idx=$(sed -n 's/.*-task\([0-9]*\)-trial[0-9]*$/\1/p' <<< "$base")
      [[ -z "$task_idx" ]] && continue
      cond=$(sed -n "s/^$name-\(.*\)-task[0-9]*-trial[0-9]*$/\1/p" <<< "$base")
      [[ -z "$cond" ]] && continue
      local criteria ideal judged score jjson
      criteria=$(yq ".tasks[$task_idx].criteria // .criteria" "$def_file")
      ideal=$(yq ".tasks[$task_idx].ideal // \"\"" "$def_file")
      judged=$(judge_output "$(cat "$out_file")" "$criteria" "$ideal")
      score=$(parse_score "$judged")
      jjson=$(parse_judges "$judged")
      local jn
      for jn in $(sed 's/[]["]//g;s/,/ /g' <<< "$jjson"); do row_judges[$jn]=1; done
      [[ "$score" -ge 1 && "$score" -le 5 ]] 2>/dev/null || score=0
      csum[$cond]=$(echo "${csum[$cond]:-0} + $score" | bc)
      ccount[$cond]=$(( ${ccount[$cond]:-0} + 1 ))
      [[ "$first_task" == true ]] || task_scores_json="$task_scores_json,"
      first_task=false
      task_scores_json="$task_scores_json{\"task\":$task_idx,\"condition\":\"$cond\",\"score\":$score,\"judges\":$jjson,\"file\":\"$(basename "$out_file")\"}"
    done
    task_scores_json="$task_scores_json]"

    [[ ${#ccount[@]} -eq 0 ]] && { echo "  ⚠️  $name — no outputs found; skipped" >&2; continue; }

    # Recompute verdict: dual-run uses with/baseline avgs + delta; single uses avg
    local with_avg="null" base_avg="null" delta="null" new_status cond
    for cond in "${!ccount[@]}"; do
      local avg; avg=$(echo "scale=2; ${csum[$cond]} / ${ccount[$cond]}" | bc | sed 's/^\./0./')
      if [[ "$cond" == "baseline" ]]; then base_avg="$avg"; else with_avg="$avg"; fi
    done
    if [[ "$base_avg" != "null" ]]; then
      delta=$(echo "scale=2; $with_avg - $base_avg" | bc | sed 's/^\./0./;s/^-\./-0./')
      if (( $(echo "$with_avg >= $threshold" | bc) )) && (( $(echo "$delta >= $delta_threshold" | bc) )); then new_status="PASS"; else new_status="FAIL"; fi
    else
      if (( $(echo "$with_avg >= $threshold" | bc) )); then new_status="PASS"; else new_status="FAIL"; fi
    fi

    local judges_union="[]"
    if [[ ${#row_judges[@]} -gt 0 ]]; then
      judges_union=$(printf '%s\n' "${!row_judges[@]}" | sort | awk '{out=out (NR>1?",":"") "\""$1"\""} END{print "["out"]"}')
    fi
    # Carry identity + join keys from the original row (outputs are unchanged)
    local orig_id orig_adapter orig_skill orig_def orig_env
    orig_id=$(sed -n 's/.*"id":\("\?[^",}]*"\?\),.*/\1/p' <<< "$row" | head -1)
    orig_adapter=$(sed -n 's/.*"adapter":"\([^"]*\)".*/\1/p' <<< "$row")
    orig_skill=$(sed -n 's/.*"skill_hash":\("\?[^",}]*"\?\).*/\1/p' <<< "$row")
    orig_def=$(sed -n 's/.*"def_hash":\("\?[^",}]*"\?\).*/\1/p' <<< "$row")
    orig_env=$(sed -n 's/.*"env_id":\("\?[^",}]*"\?\).*/\1/p' <<< "$row")

    echo "{\"id\":${orig_id:-null},\"name\":\"$name\",\"adapter\":\"$orig_adapter\",\"judges\":$judges_union,\"skill_hash\":${orig_skill:-null},\"def_hash\":${orig_def:-null},\"env_id\":${orig_env:-null},\"status\":\"$new_status\",\"score\":$with_avg,\"with_score\":$with_avg,\"without_score\":$base_avg,\"delta\":$delta,\"original_status\":\"$orig_status\",\"original_score\":${orig_score:-null},\"criteria_source\":\"$criteria_source\",\"rejudge_of\":\"scores.jsonl\",\"task_scores\":$task_scores_json}" >> "$out_scores"

    local marker="="
    [[ "$new_status" != "$orig_status" ]] && { marker="≠"; changed=$((changed + 1)); }
    echo "  $marker $name: ${orig_score:-?} ($orig_status) -> $with_avg ($new_status) | judges: $(sed 's/[]["]//g' <<< "$judges_union")"
  done < "$src/scores.jsonl"

  rm -rf "$tmp_defs"

  cat > "$src/meta-rejudge-$TIMESTAMP.json" << EOF
{
  "rejudge_of": "scores.jsonl",
  "timestamp": "$TIMESTAMP",
  "recorded_commit": "${recorded_commit:-unknown}",
  "identity": {"algorithm": "$IDENTITY_HASH_VERSION"},
  "judges": {"live": $(printf '%s\n' ${LIVE_JUDGES[@]+"${LIVE_JUDGES[@]}"} | awk '{out=out (NR>1?",":"") "\""$1"\""} END{print "["out"]"}'), "excluded": "${JUDGES_EXCLUDED//\"/\\\"}"},
  "summary": {"rejudged": $total, "verdict_changed": $changed}
}
EOF
  echo ""
  echo "Re-judged $total def(s), $changed verdict change(s)."
  echo "Wrote: $out_scores"
  return 0
}

if [[ -n "$JUDGE_ONLY_DIR" ]]; then
  run_judge_only
  exit $?
fi

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
echo "Results: $PASSED passed, $FAILED failed, $SKIPPED skipped ($TOTAL run)"
if [[ -n "$CHANGED_ONLY_DIR" ]]; then
  echo "Changed-only: ${#CHANGED_ONLY_CURRENT[@]} def(s) current vs $CHANGED_ONLY_DIR, not re-run"
  [[ ${#CHANGED_ONLY_CURRENT[@]} -gt 0 ]] && printf '  = %s\n' "${CHANGED_ONLY_CURRENT[@]}"
fi

# Live judge set as JSON (empty if judging never happened this run)
JUDGES_LIVE_JSON="[]"
if [[ ${#LIVE_JUDGES[@]} -gt 0 ]]; then
  JUDGES_LIVE_JSON=$(printf '%s\n' "${LIVE_JUDGES[@]}" | awk '{out=out (NR>1?",":"") "\""$1"\""} END{print "["out"]"}')
fi
JUDGES_EXCLUDED_ESCAPED="${JUDGES_EXCLUDED//\"/\\\"}"

# Write meta.json (resume mode: preserve the original, record the resume separately)
META_FILE="$RUN_DIR/meta.json"
[[ -n "$RESUME_DIR" && -f "$META_FILE" ]] && META_FILE="$RUN_DIR/meta-resume-$TIMESTAMP.json"
cat > "$META_FILE" << EOF
{
  "tool": "$TOOL_NAME",
  "tool_version": "$TOOL_VERSION",
  "timestamp": "$TIMESTAMP",
  "commit": "$COMMIT",
  "config": {"trials": $TRIALS, "judge": "$JUDGE_MODEL", "adapter": "$ADAPTER", "dry_run": $DRY_RUN},
  "identity": {"algorithm": "$IDENTITY_HASH_VERSION", "changed_only_baseline": "${CHANGED_ONLY_DIR:-null}", "skipped_as_current": ${#CHANGED_ONLY_CURRENT[@]}},
  "judges": {"live": $JUDGES_LIVE_JSON, "excluded": "$JUDGES_EXCLUDED_ESCAPED"},
  "summary": {"total": $TOTAL, "passed": $PASSED, "failed": $FAILED, "skipped": $SKIPPED, "avg_score": 0}
}
EOF

echo "Results dir: $RUN_DIR"
[[ $FAILED -eq 0 ]] && exit 0 || exit 1
