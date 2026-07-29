#!/usr/bin/env bash
# test-panel.sh — panel accounting tests (ADR 0010 amendment).
# Extracts model_family / judge_family_for / panel_json from run.sh and exercises
# them directly, so the tests run against the SHIPPING source rather than a copy.
# Usage: bash tools/evals/harness/test-panel.sh
set -uo pipefail

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_SH="$HARNESS_DIR/run.sh"
[[ -f "$RUN_SH" ]] || { echo "run.sh not found: $RUN_SH" >&2; exit 2; }

# Pull just the three pure functions plus the floor constants out of run.sh.
# Each function is extracted from its header to the first column-0 '}' — extracting
# the constants as a RANGE would swallow the first function body with them.
extract_fn() { sed -n "/^$1()/,/^}/p" "$RUN_SH"; }
FUNCS=$(grep -E '^PANEL_MIN_(JUDGES|FAMILIES)=' "$RUN_SH"
        extract_fn model_family
        extract_fn judge_family_for
        extract_fn panel_json)
grep -q 'panel_json()' <<< "$FUNCS" || { echo "extraction failed — run.sh structure changed" >&2; exit 2; }
grep -q 'PANEL_MIN_FAMILIES=' <<< "$FUNCS" || { echo "extraction lost the panel floor constants" >&2; exit 2; }

FAIL=0
check() {  # check <label> <expected> <actual>
  if [[ "$2" == "$3" ]]; then
    echo "  ok   $1"
  else
    echo "  FAIL $1: expected [$2] got [$3]"; FAIL=$((FAIL + 1))
  fi
}
# run_case <kiro-model> <codex-model> <crush-model> <agy-model> <expr>
run_case() {
  local km="$1" cm="$2" rm="$3" am="$4" expr="$5"
  bash -c "
    JUDGE_MODEL='$km'; JUDGE_MODEL_CODEX='$cm'; JUDGE_MODEL_CRUSH='$rm'; JUDGE_MODEL_AGY='$am'
    $FUNCS
    $expr
  " 2>&1
}

echo "model_family"
check "claude -> anthropic"     anthropic $(run_case '' '' '' '' 'model_family claude-opus-5 x')
check "bedrock claude -> anthropic" anthropic $(run_case '' '' '' '' 'model_family bedrock/us.anthropic.claude-haiku-4-5-20251001-v1:0 x')
check "gpt -> openai"           openai    $(run_case '' '' '' '' 'model_family gpt-5.6-sol x')
check "glm -> zhipu"            zhipu     $(run_case '' '' '' '' 'model_family glm-5.2 x')
check "null -> fallback"        google    $(run_case '' '' '' '' 'model_family null google')
check "unknown -> fallback"     openai    $(run_case '' '' '' '' 'model_family some-new-model openai')

echo "judge_family_for (model id wins over tool identity)"
check "crush on bedrock claude is anthropic, not zhipu" anthropic \
  "$(run_case 'claude-opus-5' 'null' 'bedrock/us.anthropic.claude-opus-5' 'null' 'judge_family_for crush')"
check "codex null falls back to openai" openai \
  "$(run_case 'claude-opus-5' 'null' 'glm-5.2' 'null' 'judge_family_for codex')"

echo "panel_json — degraded verdicts"
p_empty=$(run_case 'claude-opus-5' 'null' 'glm-5.2' 'null' 'panel_json')
check "n=0 degraded"    true "$(grep -o '"degraded":[a-z]*' <<< "$p_empty" | cut -d: -f2)"
check "n=0 count"       0    "$(grep -o '"n":[0-9]*' <<< "$p_empty" | cut -d: -f2)"

p_one=$(run_case 'claude-opus-5' 'null' 'glm-5.2' 'null' 'panel_json kiro')
check "n=1 degraded"    true "$(grep -o '"degraded":[a-z]*' <<< "$p_one" | cut -d: -f2)"
check "n=1 reason names single judge" 1 "$(grep -c 'single judge' <<< "$p_one")"

p_two=$(run_case 'claude-opus-5' 'null' 'glm-5.2' 'null' 'panel_json kiro crush')
check "n=2 degraded even with 2 families" true "$(grep -o '"degraded":[a-z]*' <<< "$p_two" | cut -d: -f2)"
check "n=2 families counted"  2 "$(grep -o '"families":[0-9]*' <<< "$p_two" | cut -d: -f2)"
check "n=2 reason is not-a-panel" 1 "$(grep -c 'not a panel' <<< "$p_two")"

# Three legs, but crush pointed at Bedrock Claude => 2 real families (anthropic, openai)
p_three_ok=$(run_case 'claude-opus-5' 'gpt-5.6-sol' 'bedrock/us.anthropic.claude-opus-5' 'null' 'panel_json kiro codex crush')
check "n=3 across 2 families passes" false "$(grep -o '"degraded":[a-z]*' <<< "$p_three_ok" | cut -d: -f2)"
check "duplicate family collapses to 2" 2 "$(grep -o '"families":[0-9]*' <<< "$p_three_ok" | cut -d: -f2)"

# Three legs ALL Anthropic => single-family, must be degraded even though n>=3
p_three_same=$(run_case 'claude-opus-5' 'null' 'bedrock/us.anthropic.claude-opus-5' 'null' 'JUDGE_MODEL_CODEX=bedrock/us.anthropic.claude-sonnet-5; panel_json kiro codex crush')
check "single-family n=3 degraded" true "$(grep -o '"degraded":[a-z]*' <<< "$p_three_same" | cut -d: -f2)"
check "single-family reason"       1    "$(grep -c 'single-family' <<< "$p_three_same")"
check "single-family count"        1    "$(grep -o '"families":[0-9]*' <<< "$p_three_same" | cut -d: -f2)"

p_four=$(run_case 'claude-opus-5' 'gpt-5.6-sol' 'glm-5.2' 'null' 'panel_json kiro codex crush agy')
check "n=4 four families passes" false "$(grep -o '"degraded":[a-z]*' <<< "$p_four" | cut -d: -f2)"
check "n=4 family list"  "anthropic+openai+zhipu+google" "$(sed -n 's/.*"family_list":"\([^"]*\)".*/\1/p' <<< "$p_four")"

echo "emitted JSON is parseable"
if command -v jq &>/dev/null; then
  for p in "$p_empty" "$p_one" "$p_two" "$p_three_ok" "$p_three_same" "$p_four"; do
    jq -e . >/dev/null 2>&1 <<< "$p" || { echo "  FAIL invalid JSON: $p"; FAIL=$((FAIL + 1)); }
  done
  [[ $FAIL -eq 0 ]] && echo "  ok   all panel objects valid JSON"
else
  echo "  skip jq not installed"
fi

echo
if [[ $FAIL -eq 0 ]]; then echo "ALL PANEL TESTS PASSED"; exit 0; else echo "$FAIL test(s) failed"; exit 1; fi
