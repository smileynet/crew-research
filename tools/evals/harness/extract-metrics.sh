#!/bin/bash
# tools/evals/harness/extract-metrics.sh — Extract token usage and tool calls from kiro-cli session data
# Usage: ./extract-metrics.sh <workspace_path> [--json]
# Extracts: input_tokens, output_tokens, tool_calls, tool_sequence, duration
set -euo pipefail

WORKSPACE="${1:-}"
JSON_OUTPUT=false
[[ "${2:-}" == "--json" ]] && JSON_OUTPUT=true
DB="$HOME/.local/share/kiro-cli/data.sqlite3"

if [[ -z "$WORKSPACE" ]]; then
  echo "Usage: $0 <workspace_path> [--json]" >&2
  exit 2
fi

[[ -f "$DB" ]] || { echo "error: database not found" >&2; exit 2; }

# Extract metrics from conversation data
sqlite3 "$DB" "SELECT value FROM conversations_v2 WHERE key='$WORKSPACE' ORDER BY created_at DESC LIMIT 1" 2>/dev/null | python3 -c "
import sys, json, re

data = sys.stdin.read().strip()
if not data:
    print(json.dumps({'error': 'no conversation found', 'workspace': '$WORKSPACE'}))
    sys.exit(0)

try:
    conv = json.loads(data)
except json.JSONDecodeError:
    print(json.dumps({'error': 'invalid json', 'workspace': '$WORKSPACE'}))
    sys.exit(0)

# Extract from user_turn_metadata.requests
utm = conv.get('user_turn_metadata', {})
if isinstance(utm, str):
    try: utm = json.loads(utm)
    except: utm = {}

requests = utm.get('requests', [])

# Aggregate metrics from requests
total_prompt_tokens = sum(r.get('user_prompt_length', 0) for r in requests)
total_response_tokens = sum(r.get('response_size', 0) for r in requests)
context_usage = max((r.get('context_usage_percentage', 0) for r in requests), default=0)
llm_calls = len(requests)

# Timing
timestamps = [r.get('request_start_timestamp_ms', 0) for r in requests if r.get('request_start_timestamp_ms')]
end_timestamps = [r.get('stream_end_timestamp_ms', 0) for r in requests if r.get('stream_end_timestamp_ms')]
duration_ms = (max(end_timestamps) - min(timestamps)) if timestamps and end_timestamps else 0

# Extract tool calls from requests
tool_sequence = []
for r in requests:
    tools = r.get('tool_use_ids_and_names', [])
    if isinstance(tools, list):
        for t in tools:
            if isinstance(t, dict):
                tool_sequence.append(t.get('name', '?'))
            elif isinstance(t, str):
                tool_sequence.append(t)

tool_use_count = len(tool_sequence)

# Classify into phases
phase_map = {
    'fs_read': 'E', 'read': 'E', 'glob': 'E', 'grep': 'E', 'code': 'E',
    'web_search': 'E', 'web_fetch': 'E', 'knowledge': 'E',
    'fs_write': 'I', 'write': 'I',
    'execute_bash': 'V', 'shell': 'V',
    'todo_list': 'O', 'subagent': 'O',
}
phases = []
for tool in tool_sequence:
    phase = phase_map.get(tool, '?')
    phases.append(phase)

# Phase coherence
forward = 0; total_trans = 0
order = {'E': 0, 'I': 1, 'V': 2}
for i in range(len(phases) - 1):
    if phases[i] in order and phases[i+1] in order:
        total_trans += 1
        if order[phases[i+1]] >= order[phases[i]]:
            forward += 1

phase_coherence = forward / total_trans if total_trans > 0 else 0

# Read-before-write heuristic
has_read_before_write = False
first_write = next((i for i, p in enumerate(phases) if p == 'I'), len(phases))
first_read = next((i for i, p in enumerate(phases) if p == 'E'), len(phases))
has_read_before_write = first_read < first_write

# Verify-after-change heuristic
has_verify_after_change = False
last_write = max((i for i, p in enumerate(phases) if p == 'I'), default=-1)
has_verify_after_change = any(p == 'V' for p in phases[last_write+1:]) if last_write >= 0 else False

result = {
    'workspace': '$WORKSPACE',
    'input_tokens': total_prompt_tokens,
    'output_tokens': total_response_tokens,
    'total_tokens': total_prompt_tokens + total_response_tokens,
    'context_usage_pct': round(context_usage, 2),
    'llm_calls': llm_calls,
    'tool_use_count': tool_use_count,
    'tool_sequence': tool_sequence[:50],
    'phase_sequence': ''.join(phases[:50]),
    'phase_coherence': round(phase_coherence, 2),
    'read_before_write': has_read_before_write,
    'verify_after_change': has_verify_after_change,
    'duration_ms': duration_ms,
}

print(json.dumps(result))
"
