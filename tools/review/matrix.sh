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

RUN_ID=""
TARGET=""
MODEL_FILTER=""
REVIEW_DIR=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --run-id) RUN_ID="$2"; shift 2 ;;
    --target) TARGET="$2"; shift 2 ;;
    --models) MODEL_FILTER="$2"; shift 2 ;;
    --dir) REVIEW_DIR="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

# Require explicit scope — a bare invocation must not silently do nothing/everything.
[[ -n "$RUN_ID" ]] || { echo "Error: --run-id required" >&2; exit 2; }
[[ -n "$TARGET" ]] || { echo "Error: --target <sha> required" >&2; exit 2; }
REVIEW_DIR="${REVIEW_DIR:-$REPO_ROOT}"

for tool in opencode yq jq; do
  command -v "$tool" &>/dev/null || { echo "Error: $tool required but not found" >&2; exit 2; }
done
[[ -f "$ADAPTER" ]] || { echo "Error: opencode adapter not found: $ADAPTER" >&2; exit 2; }

# ─── Model roster: from adapter dispatch_review.models, overridable via --models ──
mapfile -t DEFAULT_MODELS < <(yq -r '.dispatch_review.models[]' "$ADAPTER")
[[ ${#DEFAULT_MODELS[@]} -gt 0 ]] || { echo "Error: no dispatch_review.models in adapter" >&2; exit 2; }

ACTIVE_MODELS=()
if [[ -n "$MODEL_FILTER" ]]; then
  IFS=',' read -ra ACTIVE_MODELS <<< "$MODEL_FILTER"
else
  ACTIVE_MODELS=("${DEFAULT_MODELS[@]}")
fi

TIMEOUT=$(yq -r '.dispatch_review.timeout // .invoke.timeout // 300' "$ADAPTER")

# ─── Output layout ──────────────────────────────────────────────────────────
OUT_DIR="$REPO_ROOT/.scratch/review/$RUN_ID"
mkdir -p "$OUT_DIR"
MANIFEST="$OUT_DIR/manifest.json"
SUMMARY="$OUT_DIR/matrix-summary.json"

slug() { echo "$1" | tr '/' '-' | tr -cd '[:alnum:]-'; }

# Pre-write the manifest of EXPECTED reviewers (fan-in reconciles against this).
{
  echo "{"
  echo "  \"run_id\": \"$RUN_ID\","
  echo "  \"target\": \"$TARGET\","
  printf '  "expected": ['
  for i in "${!ACTIVE_MODELS[@]}"; do
    [[ $i -gt 0 ]] && printf ', '
    printf '"%s"' "$(slug "${ACTIVE_MODELS[$i]}")"
  done
  echo "]"
  echo "}"
} > "$MANIFEST"

echo "═══════════════════════════════════════════════════════════"
echo "  dispatch-review matrix fan-out"
echo "  run_id: $RUN_ID   target: $TARGET"
echo "  models: ${ACTIVE_MODELS[*]}"
echo "  out:    $OUT_DIR"
echo "═══════════════════════════════════════════════════════════"

# Build the findings-only review prompt for a given reviewer id (model slug).
# Self-contained contract — does NOT depend on review-new-work activating.
build_prompt() {
  local rid="$1"
  cat <<EOF
You are an independent code reviewer. Review all uncovered work through git commit
TARGET=$TARGET in the current repository. Read the working tree; run tests or inspect
code as needed. Follow the review-new-work method (two-axis: standards + spec) IF that
skill is available, but do NOT depend on it — the output contract below is authoritative.

STRICT RULES:
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
  jsonl="$OUT_DIR/$s.jsonl"
  err="$OUT_DIR/$s.err"
  artifact="$OUT_DIR/$s.md"
  prompt=$(build_prompt "$s")

  echo ""
  echo "  ▶ $model"

  if [[ "$DRY_RUN" == true ]]; then
    echo "    [dry-run] (cd $RUN_IN && opencode run --auto -m $model --format json \"<findings-only prompt>\")"
    REVIEWER_ROWS+=("{\"reviewer\":\"$s\",\"model\":\"$model\",\"result\":\"dry-run\"}")
    continue
  fi

  # Run in the isolated worktree. stdout(JSONL) and stderr kept SEPARATE — never
  # 2>&1 (corrupts JSON). events.jsonl may contain full tool-read file content →
  # treat as sensitive; only the extracted REVIEW_RESULT/findings text is surfaced.
  ( cd "$RUN_IN" && timeout "$TIMEOUT" \
      opencode run --auto -m "$model" --format json "$prompt" ) \
      > "$jsonl" 2> "$err"
  ec=$?

  status=$(validate_output "$jsonl")
  if [[ $ec -ne 0 && "$status" == "valid" ]]; then
    echo "    (note: exit $ec but stream valid — opencode exit code is unreliable)"
  fi

  if [[ "$status" == "valid" ]]; then
    # Extract final text (findings + REVIEW_RESULT), newline-joined (B3).
    jq -rn '[inputs | select(.type=="text") | .part.text] | join("\n")' "$jsonl" > "$artifact" 2>/dev/null
    result_line=$(extract_result_line "$artifact")
    if [[ -n "$result_line" ]]; then
      echo "    ✓ valid — $(echo "$result_line" | cut -c1-80)"
      PRODUCED+=("$s")
      REVIEWER_ROWS+=("{\"reviewer\":\"$s\",\"model\":\"$model\",\"result\":\"produced\",\"artifact\":\".scratch/review/$RUN_ID/$s.md\"}")
    else
      echo "    ⚠ valid stream but no REVIEW_RESULT line → indeterminate"
      MISSING+=("$s")
      REVIEWER_ROWS+=("{\"reviewer\":\"$s\",\"model\":\"$model\",\"result\":\"indeterminate\",\"reason\":\"no_result_line\"}")
    fi
  else
    # empty / no clean stop → indeterminate (NEVER treated as clean). Quota/429
    # exhaustion (per coding-plan-limits) also lands here as a dropped reviewer.
    echo "    ✗ $status (exit $ec) → coverage gap"
    MISSING+=("$s")
    REVIEWER_ROWS+=("{\"reviewer\":\"$s\",\"model\":\"$model\",\"result\":\"indeterminate\",\"reason\":\"$status\"}")
  fi
done

# ─── Summary (machine-readable; fan-in reads this) ───────────────────────────
overall="pass"; [[ ${#MISSING[@]} -gt 0 ]] && overall="coverage_gap"

{
  echo "{"
  echo "  \"status\": \"$overall\","
  echo "  \"run_id\": \"$RUN_ID\","
  echo "  \"target\": \"$TARGET\","
  echo "  \"expected\": ${#ACTIVE_MODELS[@]},"
  echo "  \"produced\": ${#PRODUCED[@]},"
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
echo "  produced ${#PRODUCED[@]}/${#ACTIVE_MODELS[@]}; missing: ${MISSING[*]:-none}"
echo ""
echo "  NEXT (parent, main context): read artifacts + manifest, dedup by"
echo "  (file,line,category), tier by agreement, create ONE aggregate ticket,"
echo "  fail-closed verify. Missing reviewers are coverage gaps, never clean."

[[ "$overall" == "pass" ]] && exit 0 || exit 1
