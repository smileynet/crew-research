#!/bin/bash
# tools/proofs/harness/inspect-session.sh
# Inspects the most recent session log for structural assertions
# Usage: ./inspect-session.sh --adapter <kiro-cli|codex> --session-id <id> --check <assertion>
#
# Assertions:
#   file_read:<path>       — tool read this file path during the session
#   no_file_read:<path>    — tool did NOT read this file path
#   tool_used:<name>       — a tool with this name was invoked
#   no_tool_used:<name>    — no tool with this name was invoked
#   context_contains:<str> — raw session log contains this string
#   context_absent:<str>   — raw session log does NOT contain this string
set -uo pipefail

ADAPTER=""
SESSION_ID=""
SESSION_FILE=""
CHECKS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    --adapter) ADAPTER="$2"; shift 2 ;;
    --session-id) SESSION_ID="$2"; shift 2 ;;
    --check) CHECKS+=("$2"); shift 2 ;;
    --session-file) SESSION_FILE="$2"; shift 2 ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done

# Locate session file
find_session_file() {
  case "$ADAPTER" in
    kiro-cli)
      if [[ -n "${SESSION_ID:-}" ]]; then
        echo "$HOME/.kiro/sessions/cli/$SESSION_ID.jsonl"
      else
        # Most recent by mtime
        find "$HOME/.kiro/sessions/cli/" -name "*.jsonl" 2>/dev/null | xargs ls -t 2>/dev/null | head -1
      fi
      ;;
    codex)
      if [[ -n "${SESSION_FILE:-}" ]]; then
        echo "$SESSION_FILE"
      elif [[ -n "${SESSION_ID:-}" ]]; then
        find "$HOME/.codex/sessions/" -name "*$SESSION_ID*" 2>/dev/null | head -1
      else
        find "$HOME/.codex/sessions/" -name "rollout-*.jsonl" 2>/dev/null | xargs ls -t 2>/dev/null | head -1
      fi
      ;;
  esac
}

SESSION_LOG="${SESSION_FILE:-$(find_session_file)}"

if [[ -z "$SESSION_LOG" || ! -f "$SESSION_LOG" ]]; then
  echo "SKIP: session log not found" >&2
  exit 2
fi

PASS=0
FAIL=0

for check in "${CHECKS[@]}"; do
  type="${check%%:*}"
  value="${check#*:}"

  case "$type" in
    file_read)
      if grep -q "$value" "$SESSION_LOG"; then
        PASS=$((PASS + 1))
      else
        echo "FAIL: expected file_read '$value' not found in session log" >&2
        FAIL=$((FAIL + 1))
      fi
      ;;
    no_file_read)
      if grep -q "$value" "$SESSION_LOG"; then
        echo "FAIL: unexpected file_read '$value' found in session log" >&2
        FAIL=$((FAIL + 1))
      else
        PASS=$((PASS + 1))
      fi
      ;;
    tool_used)
      if grep -q "\"name\":\"$value\"" "$SESSION_LOG" || grep -q "\"$value\"" "$SESSION_LOG"; then
        PASS=$((PASS + 1))
      else
        echo "FAIL: expected tool '$value' not found in session log" >&2
        FAIL=$((FAIL + 1))
      fi
      ;;
    no_tool_used)
      if grep -q "\"name\":\"$value\"" "$SESSION_LOG"; then
        echo "FAIL: unexpected tool '$value' found in session log" >&2
        FAIL=$((FAIL + 1))
      else
        PASS=$((PASS + 1))
      fi
      ;;
    context_contains)
      if grep -q "$value" "$SESSION_LOG"; then
        PASS=$((PASS + 1))
      else
        echo "FAIL: expected '$value' not in session log" >&2
        FAIL=$((FAIL + 1))
      fi
      ;;
    context_absent)
      if grep -q "$value" "$SESSION_LOG"; then
        echo "FAIL: unexpected '$value' found in session log" >&2
        FAIL=$((FAIL + 1))
      else
        PASS=$((PASS + 1))
      fi
      ;;
    *)
      echo "SKIP: unknown check type '$type'" >&2
      ;;
  esac
done

echo "{\"log_checks\": $((PASS + FAIL)), \"log_passed\": $PASS, \"log_failed\": $FAIL}"
exit $FAIL
