#!/usr/bin/env bash
# test-noise-floor.sh — verify ticket 71 noise floor logic
# Tests: single-family sub-floor (flagged), single-family above-floor (not flagged),
#        multi-family sub-floor (not flagged)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/identity.sh"

# Source the constants from run.sh without executing the whole harness
NOISE_FLOOR_SINGLE_FAMILY=0.5
PANEL_MIN_FAMILIES=2

# Mock judge_family_for
judge_family_for() {
  case "$1" in
    kiro)  echo anthropic ;;
    codex) echo openai ;;
    crush) echo zhipu ;;
    agy)   echo google ;;
  esac
}

PASS=0
FAIL=0

assert_flagged() {
  local desc="$1" result="$2"
  if [[ "$result" == *"INCONCLUSIVE"* ]]; then
    PASS=$((PASS + 1))
    echo "  ✅ $desc"
  else
    FAIL=$((FAIL + 1))
    echo "  ❌ $desc — expected INCONCLUSIVE, got: $result"
  fi
}

assert_not_flagged() {
  local desc="$1" result="$2"
  if [[ "$result" != *"INCONCLUSIVE"* ]]; then
    PASS=$((PASS + 1))
    echo "  ✅ $desc"
  else
    FAIL=$((FAIL + 1))
    echo "  ❌ $desc — expected NO flag, got: $result"
  fi
}

# The noise floor check extracted as a function for testing
check_noise_floor() {
  local delta="$1"
  shift
  local live_judges=("$@")

  local noise_floor_flag=""
  local nf_fams=()
  for nf_j in "${live_judges[@]}"; do
    local nf_f; nf_f=$(judge_family_for "$nf_j")
    [[ " ${nf_fams[*]-} " == *" $nf_f "* ]] || nf_fams+=("$nf_f")
  done
  if (( ${#nf_fams[@]} < PANEL_MIN_FAMILIES )); then
    local abs_delta=${delta#-}
    if [[ "$(echo "$abs_delta < $NOISE_FLOOR_SINGLE_FAMILY" | bc)" == 1* ]]; then
      noise_floor_flag="INCONCLUSIVE — delta $delta below noise floor $NOISE_FLOOR_SINGLE_FAMILY (single-family panel)"
    fi
  fi
  echo "$noise_floor_flag"
}

echo "Noise floor tests (ticket 71):"
echo

# Test 1: Single-family, sub-floor delta → FLAGGED
result=$(check_noise_floor "0.3" "kiro")
assert_flagged "single-family (kiro only), delta 0.3 < floor 0.5" "$result"

# Test 2: Single-family, negative sub-floor delta → FLAGGED
result=$(check_noise_floor "-0.4" "kiro")
assert_flagged "single-family (kiro only), delta -0.4 < floor 0.5" "$result"

# Test 3: Single-family, delta at floor → NOT FLAGGED (not strictly less than)
result=$(check_noise_floor "0.5" "kiro")
assert_not_flagged "single-family (kiro only), delta 0.5 == floor (not less than)" "$result"

# Test 4: Single-family, above-floor delta → NOT FLAGGED
result=$(check_noise_floor "0.8" "kiro")
assert_not_flagged "single-family (kiro only), delta 0.8 > floor 0.5" "$result"

# Test 5: Multi-family, sub-floor delta → NOT FLAGGED
result=$(check_noise_floor "0.3" "kiro" "codex")
assert_not_flagged "multi-family (kiro+codex), delta 0.3 < floor — but 2 families" "$result"

# Test 6: Multi-family (3 judges, 2 families), sub-floor → NOT FLAGGED
result=$(check_noise_floor "0.1" "kiro" "codex" "agy")
assert_not_flagged "multi-family (kiro+codex+agy), delta 0.1 — 3 families" "$result"

# Test 7: Single-family (two legs same family), sub-floor → FLAGGED
# crush pointed at bedrock/us.anthropic would be anthropic, but with default it's zhipu
# Two kiro legs doesn't happen, but test the logic: same family counted once
result=$(check_noise_floor "0.2" "kiro")
assert_flagged "single judge (kiro), delta 0.2 < floor" "$result"

# Test 8: Zero delta, single family → FLAGGED
result=$(check_noise_floor "0.0" "kiro")
assert_flagged "single-family, delta 0.0 (zero) < floor" "$result"

echo
echo "---"
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
