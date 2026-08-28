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

REVIEW_PROMPT="Use review-new-work to review all uncovered work through TARGET=$TARGET. \
Review run id: RUN_ID=$RUN_ID. Do not apply fixes. Emit each finding as a JSON object \
{id,reviewer_id,severity,category,location:{file,line},summary,evidence,confidence}. \
End with exactly one REVIEW_RESULT line (see the review result contract)."

# ─── Validate one reviewer's captured JSONL ──────────────────────────────────
# opencode exit code is unreliable — a result is VALID only if the stream has a
# step_finish reason:"stop" AND non-empty assistant text. Else → indeterminate.
validate_output() {
  local jsonl="$1"
  [[ -s "$jsonl" ]] || { echo "empty"; return; }
  local stop text
  stop=$(jq -rn 'last(inputs | select(.type=="step_finish") | .part.reason) // "none"' "$jsonl" 2>/dev/null || echo "none")
  text=$(jq -rn '[inputs | select(.type=="text") | .part.text] | join("")' "$jsonl" 2>/dev/null || echo "")
  if [[ "$stop" == "stop" && -n "$text" ]]; then echo "valid"; else echo "indeterminate"; fi
}

# ─── Fan out: one reviewer per model, sequential (one blocking call at a time) ──
declare -a PRODUCED=()
declare -a MISSING=()
declare -a REVIEWER_ROWS=()

for model in "${ACTIVE_MODELS[@]}"; do
  s=$(slug "$model")
  jsonl="$OUT_DIR/$s.jsonl"
  err="$OUT_DIR/$s.err"
  artifact="$OUT_DIR/$s.md"

  echo ""
  echo "  ▶ $model"

  if [[ "$DRY_RUN" == true ]]; then
    echo "    [dry-run] (cd $REVIEW_DIR && opencode run --auto -m $model --format json \"<review prompt>\")"
    REVIEWER_ROWS+=("{\"reviewer\":\"$s\",\"model\":\"$model\",\"result\":\"dry-run\"}")
    continue
  fi

  # Isolated: run in the target repo dir; opencode reads the working tree.
  # stdout(JSONL) and stderr kept SEPARATE — never 2>&1 (corrupts JSON).
  ( cd "$REVIEW_DIR" && timeout "$TIMEOUT" \
      opencode run --auto -m "$model" --format json "$REVIEW_PROMPT" ) \
      > "$jsonl" 2> "$err"
  ec=$?

  status=$(validate_output "$jsonl")
  if [[ $ec -ne 0 && "$status" == "valid" ]]; then
    # nonzero exit but a clean stream — trust the stream (exit code unreliable), note it
    echo "    (note: exit $ec but stream valid)"
  fi

  if [[ "$status" == "valid" ]]; then
    # Extract the reviewer's final text as the artifact (findings + REVIEW_RESULT line).
    jq -rn '[inputs | select(.type=="text") | .part.text] | join("")' "$jsonl" > "$artifact" 2>/dev/null
    result_line=$(grep -m1 '^REVIEW_RESULT ' "$artifact" || echo "")
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
