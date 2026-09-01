#!/bin/bash
# tools/review/matrix.sh — dispatch-review multi-model FAN-OUT helper.
#
# Launches one `opencode run` reviewer per model over an isolated clone-free
# working dir, captures each reviewer's JSONL + REVIEW_RESULT line to a per-model
# artifact, and reconciles produced-vs-expected against a manifest. FAN-OUT ONLY:
# it does NOT dedup findings, tier by agreement, or create tickets — that is the
# parent's skill-guided fan-in (main context), per subagent-reliability.
#
# Usage:
#   matrix.sh --run-id <uuid> --target <sha> [--models a,b,c] [--dir <repo>] [--dry-run]
#
# Exit: 0 = all expected reviewers produced a valid result
#       1 = coverage gap (>=1 reviewer indeterminate/missing)
#       2 = usage / environment error
set -uo pipefail   # NOT -e: the wait/validate loop inspects exit codes explicitly

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ADAPTER="$REPO_ROOT/tools/proofs/adapters/opencode.yaml"
AGY_ADAPTER="$REPO_ROOT/tools/proofs/adapters/agy.yaml"
CREW_ENV="${CREW_ENV:-}"

RUN_ID=""
TARGET=""
MODEL_FILTER=""
REVIEW_DIR=""
DRY_RUN=false
HEALTH=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --run-id) RUN_ID="$2"; shift 2 ;;
    --target) TARGET="$2"; shift 2 ;;
    --models) MODEL_FILTER="$2"; shift 2 ;;
    --dir) REVIEW_DIR="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --health) HEALTH=true; shift ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

# --health is a preflight readiness probe (no review, no target/run-id needed).
if [[ "$HEALTH" == true ]]; then
  RUN_ID="${RUN_ID:-health-$(date +%s)}"
else
  # Require explicit scope — a bare review invocation must not silently do nothing/everything.
  [[ -n "$RUN_ID" ]] || { echo "Error: --run-id required" >&2; exit 2; }
  [[ -n "$TARGET" ]] || { echo "Error: --target <sha> required" >&2; exit 2; }
fi
REVIEW_DIR="${REVIEW_DIR:-$REPO_ROOT}"

for tool in yq jq; do
  command -v "$tool" &>/dev/null || { echo "Error: $tool required but not found" >&2; exit 2; }
done
[[ -f "$ADAPTER" ]] || { echo "Error: opencode adapter not found: $ADAPTER" >&2; exit 2; }

# ─── Model roster + per-model tool resolution ────────────────────────────────
# The reviewer TOOL is resolved per model, so a matrix can mix opencode-hosted
# models and agy-hosted Gemini models (ticket 142). Resolution order:
#   1. explicit "tool:model" prefix in --models (e.g. agy:gemini-3.1-pro-high)
#   2. membership in an adapter's dispatch_review.models roster
#   3. default → opencode
# tool_of() writes to the global TOOL_OF associative array (model → tool).
declare -A TOOL_OF=()
declare -A AGY_ROSTER=()
declare -A OC_ROSTER=()

if [[ -f "$AGY_ADAPTER" ]]; then
  while IFS= read -r m; do [[ -n "$m" ]] && AGY_ROSTER["$m"]=1; done \
    < <(yq -r '.dispatch_review.models[]' "$AGY_ADAPTER" 2>/dev/null)
fi
while IFS= read -r m; do [[ -n "$m" ]] && OC_ROSTER["$m"]=1; done \
  < <(yq -r '.dispatch_review.models[]' "$ADAPTER" 2>/dev/null)

# Resolve a raw roster entry into "tool|model" (strips an explicit tool: prefix).
resolve_entry() {
  local raw="$1"
  local tool="" model="$raw"
  case "$raw" in
    agy:*)      tool="agy";      model="${raw#agy:}" ;;
    opencode:*) tool="opencode"; model="${raw#opencode:}" ;;
    *)
      if [[ -n "${AGY_ROSTER[$raw]:-}" ]]; then tool="agy"
      elif [[ -n "${OC_ROSTER[$raw]:-}" ]]; then tool="opencode"
      else tool="opencode"; fi
      ;;
  esac
  echo "$tool|$model"
}

# Default roster = opencode models + agy models (each tool contributes its leg).
DEFAULT_MODELS=()
for m in "${!OC_ROSTER[@]}"; do DEFAULT_MODELS+=("$m"); done
# stable-ish: append agy models after opencode
for m in "${!AGY_ROSTER[@]}"; do DEFAULT_MODELS+=("agy:$m"); done
[[ ${#DEFAULT_MODELS[@]} -gt 0 ]] || { echo "Error: no dispatch_review.models in any adapter" >&2; exit 2; }

RAW_MODELS=()
if [[ -n "$MODEL_FILTER" ]]; then
  IFS=',' read -ra RAW_MODELS <<< "$MODEL_FILTER"
else
  RAW_MODELS=("${DEFAULT_MODELS[@]}")
fi

# Build ACTIVE_MODELS (bare model ids) + TOOL_OF, applying the CREW_ENV policy
# floor: on corp, agy is policy-blocked (ticket 36) — exclude the leg with a
# DISTINCT reason (degrade-as-gap, like the eval judge leg; NOT a hard exit, since
# a matrix has other legs). This is the hard floor ticket 144 layers under.
ACTIVE_MODELS=()
declare -A POLICY_BLOCKED=()
for raw in "${RAW_MODELS[@]}"; do
  IFS='|' read -r t m < <(resolve_entry "$raw")
  if [[ "$t" == "agy" && "$CREW_ENV" == "corp" ]]; then
    POLICY_BLOCKED["$m"]="policy-blocked (CREW_ENV=corp)"
    TOOL_OF["$m"]="$t"
    continue
  fi
  TOOL_OF["$m"]="$t"
  ACTIVE_MODELS+=("$m")
done

# Require only the reviewer tools actually in play (an agy-only run must not
# hard-fail on a missing opencode, and vice-versa).
NEED_OC=false; NEED_AGY=false
for m in "${ACTIVE_MODELS[@]}"; do
  case "${TOOL_OF[$m]}" in opencode) NEED_OC=true ;; agy) NEED_AGY=true ;; esac
done
$NEED_OC && { command -v opencode &>/dev/null || { echo "Error: opencode required for the active roster but not found" >&2; exit 2; }; }
$NEED_AGY && { command -v agy &>/dev/null || { echo "Error: agy required for the active roster but not found" >&2; exit 2; }; }

# Timeout: prefer opencode adapter's dispatch_review.timeout, else its invoke, else 300.
TIMEOUT=$(yq -r '.dispatch_review.timeout // .invoke.timeout // 300' "$ADAPTER")
AGY_TIMEOUT=$(yq -r '.dispatch_review.timeout // .invoke.timeout // 300' "$AGY_ADAPTER" 2>/dev/null)
[[ "$AGY_TIMEOUT" =~ ^[0-9]+$ ]] || AGY_TIMEOUT="$TIMEOUT"

# ─── Output layout ──────────────────────────────────────────────────────────
OUT_DIR="$REPO_ROOT/.scratch/review/$RUN_ID"
mkdir -p "$OUT_DIR"
MANIFEST="$OUT_DIR/manifest.json"
SUMMARY="$OUT_DIR/matrix-summary.json"

slug() { echo "$1" | tr '/' '-' | tr -cd '[:alnum:]-'; }

# Pre-write the manifest of EXPECTED reviewers (fan-in reconciles against this).
# Policy-blocked legs ARE expected (they'd run but for policy) — listed so fan-in
# reconciliation reports them as a gap, not as silently absent.
if [[ "$HEALTH" != true ]]; then
{
  echo "{"
  echo "  \"run_id\": \"$RUN_ID\","
  echo "  \"target\": \"$TARGET\","
  printf '  "expected": ['
  first=true
  for m in "${ACTIVE_MODELS[@]}"; do
    $first || printf ', '; first=false; printf '"%s"' "$(slug "$m")"
  done
  for m in "${!POLICY_BLOCKED[@]}"; do
    $first || printf ', '; first=false; printf '"%s"' "$(slug "$m")"
  done
  echo "],"
  printf '  "policy_blocked": ['
  first=true
  for m in "${!POLICY_BLOCKED[@]}"; do
    $first || printf ', '; first=false; printf '"%s"' "$(slug "$m")"
  done
  echo "]"
  echo "}"
} > "$MANIFEST"
fi

if [[ "$HEALTH" != true ]]; then
echo "═══════════════════════════════════════════════════════════"
echo "  dispatch-review matrix fan-out"
echo "  run_id: $RUN_ID   target: $TARGET"
echo "  models: ${ACTIVE_MODELS[*]}"
echo "  out:    $OUT_DIR"
echo "═══════════════════════════════════════════════════════════"
fi

# Build the findings-only review prompt for a given reviewer id (model slug).
# Self-contained contract — does NOT depend on review-new-work activating.
build_prompt() {
  local rid="$1"
  cat <<EOF
You are an independent code reviewer. You are ALREADY inside a git working tree
checked out at the commit under review (TARGET=$TARGET — for reference only). The
code to review is the files in the CURRENT working directory, as they are on disk.

STRICT RULES:
- Do NOT search for, locate, or check out any commit. Do NOT run \`find\` or \`grep\`
  across the filesystem, and do NOT run \`git log\`/\`git checkout\` to hunt for TARGET —
  the code to review is the current working directory. Just read the files here.
- Review ALL source files in the current directory (two-axis: standards + spec).
  Follow the review-new-work method IF that skill is available, but do NOT depend on
  it — the output contract below is authoritative.
- Do NOT apply fixes or edit any file.
- Do NOT create, commit, or push any ticket or file. Emit findings inline ONLY.
- Output findings as JSON Lines: one JSON object per line, no markdown fences, no prose.

Each finding line (emit ALL keys; use null, never omit):
{"id":"F1","reviewer_id":"$rid","severity":"critical|high|medium|low","category":"security|performance|architecture|testing|correctness|style","location":{"file":"path","line":0},"summary":"one line","evidence":"observed code/behavior","confidence":0.0}

Example:
{"id":"F1","reviewer_id":"$rid","severity":"high","category":"correctness","location":{"file":"src/x.ts","line":42},"summary":"off-by-one in loop bound","evidence":"i <= len iterates past end","confidence":0.9}

After all findings, emit EXACTLY ONE final line at column 0, no fence, nothing after it:
REVIEW_RESULT {"run_id":"$RUN_ID","reviewer":"$rid","target":"$TARGET","result":"findings"}
If you found nothing, emit the same line with "result":"clean" and no finding lines.
EOF
}

# ─── Validate one reviewer's captured JSONL ──────────────────────────────────
# opencode exit code is unreliable — a result is VALID only if the stream has a
# step_finish reason:"stop" AND non-empty assistant text. Else → indeterminate.
validate_output() {
  local jsonl="$1"
  [[ -s "$jsonl" ]] || { echo "empty"; return; }
  local stop text
  # last() correctly skips a "tool-calls" step_finish; only the final is "stop".
  stop=$(jq -rn 'last(inputs | select(.type=="step_finish") | .part.reason) // "none"' "$jsonl" 2>/dev/null || echo "none")
  # join with newline (B3) so the REVIEW_RESULT line stays at column 0.
  text=$(jq -rn '[inputs | select(.type=="text") | .part.text] | join("\n")' "$jsonl" 2>/dev/null || echo "")
  if [[ "$stop" == "stop" && -n "$text" ]]; then echo "valid"; else echo "indeterminate"; fi
}

# Fence-tolerant, last-match REVIEW_RESULT extraction (B3). Handles the line
# appearing mid-stream (echoed example) by taking the LAST real one, and strips
# a leading markdown fence marker if a model wrapped output.
extract_result_line() {
  local artifact="$1"
  grep -Eo 'REVIEW_RESULT \{.*\}' "$artifact" 2>/dev/null | tail -1
}

# ─── Tool-aware reviewer interface (opencode + agy) ──────────────────────────
# Each tool has a distinct invocation, clean-stop signal, and error surface. The
# wrappers normalize all of that so the fan-out/health loops stay tool-agnostic:
#   invoke_reviewer  <tool> <model> <prompt> <jsonl> <err> <run_dir> <timeout>
#   validate_stream  <tool> <jsonl>            → valid | indeterminate | empty
#   extract_text     <tool> <jsonl>            → final assistant text (newline-joined)
#   classify_error   <tool> <jsonl> <err>      → coding-plan-limits reason token

invoke_reviewer() {
  local tool="$1" model="$2" prompt="$3" jsonl="$4" err="$5" run_dir="$6" to="$7"
  case "$tool" in
    opencode)
      ( cd "$run_dir" && timeout "$to" \
          opencode run --auto -m "$model" --format json "$prompt" ) \
          > "$jsonl" 2> "$err"
      ;;
    agy)
      # --print is greedy: prompt MUST be --print="..."; bypass flag elsewhere.
      # --print-timeout matches the outer `timeout` so agy's internal 5m default
      # doesn't cut a slow Pro review short; the outer `timeout` is the hard ceiling.
      ( cd "$run_dir" && timeout "$to" \
          agy --dangerously-skip-permissions --model "$model" \
              --output-format stream-json --print-timeout "${to}s" \
              --print="$prompt" ) \
          > "$jsonl" 2> "$err"
      ;;
    *) return 2 ;;
  esac
}

# agy clean-stop: terminal event:"result" with result.status=="SUCCESS" + non-empty response.
validate_agy() {
  local jsonl="$1"
  [[ -s "$jsonl" ]] || { echo "empty"; return; }
  local status resp
  status=$(jq -rn 'last(inputs | select(.event=="result") | .result.status) // "none"' "$jsonl" 2>/dev/null || echo "none")
  resp=$(jq -rn 'last(inputs | select(.event=="result") | .result.response) // ""' "$jsonl" 2>/dev/null || echo "")
  if [[ "$status" == "SUCCESS" && -n "$resp" ]]; then echo "valid"; else echo "indeterminate"; fi
}

validate_stream() {
  local tool="$1" jsonl="$2"
  case "$tool" in
    opencode) validate_output "$jsonl" ;;
    agy)      validate_agy "$jsonl" ;;
    *)        echo "indeterminate" ;;
  esac
}

extract_text() {
  local tool="$1" jsonl="$2"
  case "$tool" in
    opencode)
      jq -rn '[inputs | select(.type=="text") | .part.text] | join("\n")' "$jsonl" 2>/dev/null || echo ""
      ;;
    agy)
      # Prefer the terminal result.response (whole answer); fall back to concatenated
      # agent_response text_deltas if a response field is absent.
      local t
      t=$(jq -rn 'last(inputs | select(.event=="result") | .result.response) // ""' "$jsonl" 2>/dev/null || echo "")
      if [[ -z "$t" ]]; then
        t=$(jq -rn '[inputs | select(.event=="step_update" and .step_update.step_type=="agent_response") | .step_update.text_delta // ""] | join("")' "$jsonl" 2>/dev/null || echo "")
      fi
      printf '%s' "$t"
      ;;
    *) echo "" ;;
  esac
}

# Classify a failure into coding-plan-limits vocabulary (best-effort). Both tools
# surface provider errors in-stream (stdout) as well as stderr — inspect both.
classify_error() {
  local tool="$1" jsonl="$2" err="$3" errtext=""
  case "$tool" in
    opencode)
      errtext=$(jq -rn 'last(inputs | select(.type=="error") | (.error.data.message // .error.name // "")) // ""' "$jsonl" 2>/dev/null || echo "")
      ;;
    agy)
      errtext=$(jq -rn 'last(inputs | select(.event=="result") | (.result.error // "")) // ""' "$jsonl" 2>/dev/null || echo "")
      # also scan tool_info errors and any error event
      errtext="$errtext $(jq -rn '[inputs | select(.event=="step_update") | .step_update.tool_info.error.message // empty] | join(" ")' "$jsonl" 2>/dev/null || echo "")"
      ;;
  esac
  errtext="$errtext $(cat "$err" 2>/dev/null)"
  if   grep -qiE "not supported|requires a newer|not found|invalid model|no such model|unknown.?model" <<<"$errtext"; then echo "model_unavailable"
  elif grep -qiE "401|unauthor|invalid.*key|\bauth|sign.?in" <<<"$errtext"; then echo "auth"
  elif grep -qiE "429|quota|rate.?limit|insufficient|overloaded|out of credits" <<<"$errtext"; then echo "quota"
  elif grep -qiE "timeout|timed out|deadline" <<<"$errtext"; then echo "timeout"
  elif grep -qiE "server error|UnknownError|unexpected" <<<"$errtext"; then echo "server_error"
  else echo "empty_or_timeout"; fi
}

# ─── --health preflight: readiness-probe each model (ticket 134) ──────────────
# Per-model (opencode is ONE binary hosting N models — a single probe would miss a
# down model, the codex-131 case). Readiness not liveness: send a real minimal
# completion, validate OUTPUT (not exit code). Cheapest possible prompt.
probe_model() {
  local model="$1"
  local tool="${TOOL_OF[$model]:-opencode}" s jsonl err status text
  s=$(slug "$model")
  jsonl="$OUT_DIR/health-$s.jsonl"; err="$OUT_DIR/health-$s.err"
  local to="$TIMEOUT"; [[ "$tool" == "agy" ]] && to="$AGY_TIMEOUT"
  invoke_reviewer "$tool" "$model" "Reply with exactly: OK" "$jsonl" "$err" "$REPO_ROOT" "$to"
  status=$(validate_stream "$tool" "$jsonl")
  if [[ "$status" == "valid" ]]; then
    text=$(extract_text "$tool" "$jsonl")
    if grep -qi "OK" <<<"$text"; then echo "healthy"; return; fi
    echo "unhealthy:no_ok_in_reply"; return
  fi
  local reason; reason=$(classify_error "$tool" "$jsonl" "$err")
  [[ "$status" == "empty" ]] && reason="empty_or_timeout"
  echo "unhealthy:$reason"
}

run_health() {
  echo "═══════════════════════════════════════════════════════════"
  echo "  dispatch-review health check (readiness probe)"
  echo "  models: ${ACTIVE_MODELS[*]:-none}"
  [[ ${#POLICY_BLOCKED[@]} -gt 0 ]] && echo "  policy-blocked: ${!POLICY_BLOCKED[*]}"
  echo "═══════════════════════════════════════════════════════════"
  local rows=() down=0 blocked=0
  # Policy-blocked legs: reported as a distinct gap, no token spend, not "down".
  for model in "${!POLICY_BLOCKED[@]}"; do
    printf "  ▶ %-34s " "$model"
    echo "⊘ ${POLICY_BLOCKED[$model]}"
    blocked=$((blocked+1))
    rows+=("{\"model\":\"$model\",\"healthy\":false,\"reason\":\"policy-blocked\",\"detail\":\"${POLICY_BLOCKED[$model]}\"}")
  done
  for model in "${ACTIVE_MODELS[@]}"; do
    printf "  ▶ %-34s " "$model"
    local r; r=$(probe_model "$model")
    if [[ "$r" == "healthy" ]]; then
      echo "✅ healthy"
      rows+=("{\"model\":\"$model\",\"healthy\":true,\"reason\":null}")
    else
      echo "❌ ${r#unhealthy:}"
      down=$((down+1))
      rows+=("{\"model\":\"$model\",\"healthy\":false,\"reason\":\"${r#unhealthy:}\"}")
    fi
  done
  local hsum="$OUT_DIR/health-summary.json" st="healthy"
  { [[ $down -gt 0 ]] || [[ $blocked -gt 0 ]]; } && st="degraded"
  local checked=$(( ${#ACTIVE_MODELS[@]} + blocked ))
  { echo "{"; echo "  \"status\": \"$st\","; echo "  \"checked\": $checked,";
    echo "  \"unhealthy\": $down,"; echo "  \"policy_blocked\": $blocked,"; printf '  "models": [';
    for i in "${!rows[@]}"; do [[ $i -gt 0 ]] && printf ', '; printf '%s' "${rows[$i]}"; done
    echo "]"; echo "}"; } > "$hsum"
  echo ""
  echo "  summary: $hsum  ($st — $checked checked, $down down, $blocked policy-blocked)"
  { [[ $down -eq 0 ]] && [[ $blocked -eq 0 ]]; } && return 0 || return 1
}

if [[ "$HEALTH" == true ]]; then
  run_health; exit $?
fi

# ─── Isolation (B9): review in a throwaway git worktree at TARGET, not the live tree ──
# opencode runs with --auto (permission bypass); the prompt forbids edits, but a
# worktree contains any accidental write and keeps the live repo clean. Worktrees
# share the object store (cheap). Skipped in --dry-run.
WORKTREE=""
cleanup() {
  [[ -n "$WORKTREE" && -d "$WORKTREE" ]] && git -C "$REVIEW_DIR" worktree remove --force "$WORKTREE" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

if [[ "$DRY_RUN" != true ]]; then
  WORKTREE=$(mktemp -d -t "review-wt-XXXX")
  if ! git -C "$REVIEW_DIR" worktree add --detach "$WORKTREE" "$TARGET" >/dev/null 2>&1; then
    echo "Error: could not create worktree at $TARGET (is it a valid commit in $REVIEW_DIR?)" >&2
    exit 2
  fi
  RUN_IN="$WORKTREE"
else
  RUN_IN="$REVIEW_DIR"
fi

# ─── Fan out: one reviewer per model, sequential (one blocking call at a time) ──
declare -a PRODUCED=()
declare -a MISSING=()
declare -a REVIEWER_ROWS=()

for model in "${ACTIVE_MODELS[@]}"; do
  s=$(slug "$model")
  tool="${TOOL_OF[$model]:-opencode}"
  jsonl="$OUT_DIR/$s.jsonl"
  err="$OUT_DIR/$s.err"
  artifact="$OUT_DIR/$s.md"
  prompt=$(build_prompt "$s")
  to="$TIMEOUT"; [[ "$tool" == "agy" ]] && to="$AGY_TIMEOUT"

  echo ""
  echo "  ▶ $model  [$tool]"

  if [[ "$DRY_RUN" == true ]]; then
    case "$tool" in
      opencode) echo "    [dry-run] (cd $RUN_IN && opencode run --auto -m $model --format json \"<findings-only prompt>\")" ;;
      agy)      echo "    [dry-run] (cd $RUN_IN && agy --dangerously-skip-permissions --model $model --output-format stream-json --print=\"<findings-only prompt>\")" ;;
    esac
    REVIEWER_ROWS+=("{\"reviewer\":\"$s\",\"model\":\"$model\",\"tool\":\"$tool\",\"result\":\"dry-run\"}")
    continue
  fi

  # Run in the isolated worktree. stdout(JSONL) and stderr kept SEPARATE — never
  # 2>&1 (corrupts JSON). events.jsonl may contain full tool-read file content →
  # treat as sensitive; only the extracted REVIEW_RESULT/findings text is surfaced.
  invoke_reviewer "$tool" "$model" "$prompt" "$jsonl" "$err" "$RUN_IN" "$to"
  ec=$?

  status=$(validate_stream "$tool" "$jsonl")
  if [[ $ec -ne 0 && "$status" == "valid" ]]; then
    echo "    (note: exit $ec but stream valid — reviewer exit code is unreliable)"
  fi

  if [[ "$status" == "valid" ]]; then
    # Extract final text (findings + REVIEW_RESULT), newline-joined (B3).
    extract_text "$tool" "$jsonl" > "$artifact"
    result_line=$(extract_result_line "$artifact")
    if [[ -n "$result_line" ]]; then
      echo "    ✓ valid — $(echo "$result_line" | cut -c1-80)"
      PRODUCED+=("$s")
      REVIEWER_ROWS+=("{\"reviewer\":\"$s\",\"model\":\"$model\",\"tool\":\"$tool\",\"result\":\"produced\",\"artifact\":\".scratch/review/$RUN_ID/$s.md\"}")
    else
      echo "    ⚠ valid stream but no REVIEW_RESULT line → indeterminate"
      MISSING+=("$s")
      REVIEWER_ROWS+=("{\"reviewer\":\"$s\",\"model\":\"$model\",\"tool\":\"$tool\",\"result\":\"indeterminate\",\"reason\":\"no_result_line\"}")
    fi
  else
    # empty / no clean stop → indeterminate (NEVER treated as clean). Quota/429
    # exhaustion (per coding-plan-limits) also lands here as a dropped reviewer.
    reason=$(classify_error "$tool" "$jsonl" "$err")
    [[ "$status" == "empty" ]] && reason="empty_or_timeout"
    echo "    ✗ $status ($reason, exit $ec) → coverage gap"
    MISSING+=("$s")
    REVIEWER_ROWS+=("{\"reviewer\":\"$s\",\"model\":\"$model\",\"tool\":\"$tool\",\"result\":\"indeterminate\",\"reason\":\"$reason\"}")
  fi
done

# Policy-blocked legs are reported coverage gaps with a DISTINCT reason (ticket 36
# floor; ticket 144 will layer under this). Never silently dropped, never clean.
for model in "${!POLICY_BLOCKED[@]}"; do
  s=$(slug "$model")
  echo ""
  echo "  ⊘ $model  [agy] — ${POLICY_BLOCKED[$model]}"
  MISSING+=("$s")
  REVIEWER_ROWS+=("{\"reviewer\":\"$s\",\"model\":\"$model\",\"tool\":\"agy\",\"result\":\"policy-blocked\",\"reason\":\"policy-blocked\",\"detail\":\"${POLICY_BLOCKED[$model]}\"}")
done

# ─── Summary (machine-readable; fan-in reads this) ───────────────────────────
overall="pass"; [[ ${#MISSING[@]} -gt 0 ]] && overall="coverage_gap"

{
  echo "{"
  echo "  \"status\": \"$overall\","
  echo "  \"run_id\": \"$RUN_ID\","
  echo "  \"target\": \"$TARGET\","
  echo "  \"expected\": $(( ${#ACTIVE_MODELS[@]} + ${#POLICY_BLOCKED[@]} )),"
  echo "  \"produced\": ${#PRODUCED[@]},"
  echo "  \"policy_blocked\": ${#POLICY_BLOCKED[@]},"
  printf '  "missing": ['
  for i in "${!MISSING[@]}"; do [[ $i -gt 0 ]] && printf ', '; printf '"%s"' "${MISSING[$i]}"; done
  echo "],"
  printf '  "reviewers": ['
  for i in "${!REVIEWER_ROWS[@]}"; do [[ $i -gt 0 ]] && printf ', '; printf '%s' "${REVIEWER_ROWS[$i]}"; done
  echo "]"
  echo "}"
} > "$SUMMARY"

echo ""
echo "  summary: $SUMMARY"
echo "  produced ${#PRODUCED[@]}/$(( ${#ACTIVE_MODELS[@]} + ${#POLICY_BLOCKED[@]} )); missing: ${MISSING[*]:-none}"
echo ""
echo "  NEXT (parent, main context): read artifacts + manifest, dedup by"
echo "  (file,line,category), tier by agreement, create ONE aggregate ticket,"
echo "  fail-closed verify. Missing reviewers are coverage gaps, never clean."

[[ "$overall" == "pass" ]] && exit 0 || exit 1
