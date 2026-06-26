#!/bin/bash
# tools/evals/harness/extract-session-summary.sh
# Extracts a compact behavioral summary from a session JSONL file
# Usage: ./extract-session-summary.sh --adapter <kiro-cli|codex> [--session-file <path>] [--after <timestamp>]
# Output: JSON summary of tool usage, files accessed, errors, skill activation
set -uo pipefail

ADAPTER="kiro-cli"
SESSION_FILE=""
AFTER_TS=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --adapter) ADAPTER="$2"; shift 2 ;;
    --session-file) SESSION_FILE="$2"; shift 2 ;;
    --after) AFTER_TS="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# Find most recent session if not specified
if [[ -z "$SESSION_FILE" ]]; then
  case "$ADAPTER" in
    kiro-cli)
      # Try v3 first (newer), then v2
      SESSION_FILE=$(find "$HOME/.kiro/sessions/" -path "*/sess_*/messages.jsonl" 2>/dev/null | xargs ls -t 2>/dev/null | head -1)
      [[ -z "$SESSION_FILE" ]] && SESSION_FILE=$(find "$HOME/.kiro/sessions/cli/" -name "*.jsonl" 2>/dev/null | xargs ls -t 2>/dev/null | head -1)
      ;;
    codex)
      SESSION_FILE=$(find "$HOME/.codex/sessions/" -name "rollout-*.jsonl" 2>/dev/null | xargs ls -t 2>/dev/null | head -1)
      ;;
  esac
fi

if [[ -z "$SESSION_FILE" || ! -f "$SESSION_FILE" ]]; then
  echo '{"error": "no session log found"}'
  exit 0
fi

# Extract summary based on adapter format
case "$ADAPTER" in
  kiro-cli)
    # Detect v3 format: first line has "payload" with "type"
    is_v3=false
    if head -1 "$SESSION_FILE" | grep -q '"payload".*"type"'; then
      is_v3=true
    fi

    if [[ "$is_v3" == "true" ]]; then
      # V3 format: {id, timestamp, payload: {type, toolName, content, ...}}
      local_tool_calls=$(grep -o '"toolName":"[^"]*"' "$SESSION_FILE" | sort | uniq -c | sort -rn | head -10)
      local_files_read=$(grep -o '"path":"[^"]*"' "$SESSION_FILE" | sort -u | head -20)
      local_errors=$(grep -c '"status":"error"' "$SESSION_FILE" 2>/dev/null || echo 0)
      local_skill_reads=$(grep -o 'skill://[^"]*' "$SESSION_FILE" | sort -u)
      local_total_tools=$(grep -c '"type":"tool_use"' "$SESSION_FILE" 2>/dev/null || echo 0)
      local_retries=$(grep -o '"toolName":"[^"]*".*"path":"[^"]*"' "$SESSION_FILE" 2>/dev/null | sort | uniq -d | wc -l)
    else
      # V2 format: {"version":"v1","kind":"ToolResults|AssistantMessage|Prompt","data":{...}}
      local_tool_calls=$(grep -o '"name":"[^"]*"' "$SESSION_FILE" | sort | uniq -c | sort -rn | head -10)
      local_files_read=$(grep -o '"path":"[^"]*"' "$SESSION_FILE" | sort -u | head -20)
      local_errors=$(grep -c '"status":"error"' "$SESSION_FILE" 2>/dev/null || echo 0)
      local_skill_reads=$(grep -o 'skill://[^"]*' "$SESSION_FILE" | sort -u)
      local_total_tools=$(grep -c '"toolUseId"' "$SESSION_FILE" 2>/dev/null || echo 0)
      local_retries=$(grep -o '"name":"[^"]*".*"path":"[^"]*"' "$SESSION_FILE" 2>/dev/null | sort | uniq -d | wc -l)
    fi
    ;;
  codex)
    # codex format: {"timestamp":...,"type":"event_msg","payload":{...}}
    local_tool_calls=$(grep -o '"tool_name":"[^"]*"' "$SESSION_FILE" 2>/dev/null | sort | uniq -c | sort -rn | head -10)
    [[ -z "$local_tool_calls" ]] && local_tool_calls=$(grep -o '"type":"[^"]*exec[^"]*"' "$SESSION_FILE" 2>/dev/null | sort | uniq -c | sort -rn | head -10)
    local_files_read=$(grep -o '"path":"[^"]*"' "$SESSION_FILE" 2>/dev/null | sort -u | head -20)
    [[ -z "$local_files_read" ]] && local_files_read=$(grep -o 'Get-Content[^"]*' "$SESSION_FILE" 2>/dev/null | sort -u | head -10)
    local_errors=$(grep -c '"succeeded":false\|"error"' "$SESSION_FILE" 2>/dev/null || echo 0)
    local_skill_reads=$(grep -o '\.agents/skills/[^/"]*' "$SESSION_FILE" 2>/dev/null | sort -u)
    local_total_tools=$(grep -c '"exec"\|"apply_patch"\|"shell"' "$SESSION_FILE" 2>/dev/null || echo 0)
    local_retries=0
    ;;
esac

# Format for judge consumption (human-readable, not JSON)
echo "--- Session Behavioral Summary ---"
echo "Total tool invocations: ${local_total_tools:-0}"
echo "Errors encountered: ${local_errors:-0}"
echo "Retry patterns detected: ${local_retries:-0}"
echo ""
echo "Tool usage breakdown:"
echo "${local_tool_calls:-  (none)}"
echo ""
echo "Files accessed:"
echo "${local_files_read:-  (none)}" | head -10
echo ""
if [[ -n "${local_skill_reads:-}" ]]; then
  echo "Skills activated:"
  echo "$local_skill_reads"
else
  echo "Skills activated: none"
fi
echo "--- End Summary ---"
