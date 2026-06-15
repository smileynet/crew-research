# Spec: Antigravity CLI Session Extraction via Local RPC

**Status:** Proposed  
**Date:** 2026-06-14  
**Depends on:** ADR 0006 (multi-tool deployment), spike results (RPC verified on Windows)

## Problem

agy `--print` drops stdout in non-TTY contexts (Issue #76). We cannot capture agent output for:
- Eval harness judge scoring
- Session log inspection (`inspect-session.sh`)
- Proof automation beyond "write to file" workaround

## Solution

A lightweight extraction script that calls the local language_server RPC post-run to retrieve the full session transcript, tool calls, and metadata.

## Architecture

```
agy --print "prompt"          ← runs the task (output to TUI only)
       │
       ▼
language_server.exe           ← stays alive, stores trajectory
       │
       ▼
extract-agy-session.sh        ← discovers port/token, calls RPC, outputs JSON
       │
       ├─→ extract-session-summary.sh  (behavioral summary for eval judge)
       └─→ inspect-session.sh          (structural assertions for proofs)
```

## Script: `tools/evals/harness/extract-agy-session.sh`

### Inputs

| Arg | Required | Description |
|-----|----------|-------------|
| `--cascade-id <id>` | No | Specific session. If omitted, uses most recent. |
| `--format summary` | No | Output behavioral summary (default). `json` for raw steps. |
| `--after <timestamp>` | No | Find first session created after this time. |

### Discovery (Windows)

```bash
# 1. Find language_server.exe PID and CSRF token
PID=$(powershell -c "(Get-CimInstance Win32_Process -Filter \"Name='language_server.exe'\").ProcessId")
CSRF=$(powershell -c "(Get-CimInstance Win32_Process -Filter \"Name='language_server.exe'\").CommandLine" \
  | grep -o '\-\-csrf_token [^ ]*' | awk '{print $2}')

# 2. Find HTTPS port
PORT=$(powershell -c "(Get-NetTCPConnection -OwningProcess $PID -State Listen)[0].LocalPort")

# 3. Get most recent cascade_id
CASCADES=$(curl -sk -X POST "https://127.0.0.1:$PORT/exa.language_server_pb.LanguageServerService/GetAllCascadeTrajectories" \
  -H "Content-Type: application/json" -H "x-codeium-csrf-token: $CSRF" -d "{}")
CASCADE_ID=$(echo "$CASCADES" | python -c "import sys,json; d=json.load(sys.stdin); print(max(d['trajectorySummaries'], key=lambda k: d['trajectorySummaries'][k].get('lastModifiedTime','')))")

# 4. Get steps
STEPS=$(curl -sk -X POST "https://127.0.0.1:$PORT/exa.language_server_pb.LanguageServerService/GetCascadeTrajectorySteps" \
  -H "Content-Type: application/json" -H "x-codeium-csrf-token: $CSRF" \
  -d "{\"cascadeId\":\"$CASCADE_ID\",\"startIndex\":0,\"endIndex\":100}")
```

### Discovery (macOS/Linux)

```bash
# 1. Find process via ps
PROC=$(ps -axo pid=,command= | grep "language_server.*--csrf_token" | grep -v grep | head -1)
PID=$(echo "$PROC" | awk '{print $1}')
CSRF=$(echo "$PROC" | grep -o '\-\-csrf_token [^ ]*' | awk '{print $2}')

# 2. Find port via lsof
PORT=$(lsof -Pan -p $PID -iTCP -sTCP:LISTEN | grep -o ':\([0-9]*\)' | head -1 | tr -d ':')
```

### Output: Summary Format

```
--- Session Behavioral Summary ---
Total tool invocations: 3
Errors encountered: 0
Retry patterns detected: 0

Tool usage breakdown:
  2 file_read (ViewFile)
  1 file_write (EditFile)

Files accessed:
  .agents/skills/canary-proof/skill.md
  /tmp/agy-proof-g1/answer.txt

Skills activated (from ephemeral messages):
  canary-proof

Model response:
  AGY_SKILL_7M3K9

Thinking duration: 1.99s
--- End Summary ---
```

### Output: JSON Format

```json
{
  "cascade_id": "555c79eb-...",
  "steps": [
    {"type": "USER_INPUT", "text": "Use the canary-proof skill..."},
    {"type": "EPHEMERAL_MESSAGE", "text": "...skill content injected..."},
    {"type": "PLANNER_RESPONSE", "response": "AGY_SKILL_7M3K9", "thinking": "...", "duration": "1.99s"},
    {"type": "TOOL_CALL", "tool": "EditFile", "path": "answer.txt"}
  ],
  "summary": {
    "tool_calls": 3,
    "errors": 0,
    "files_read": [".agents/skills/canary-proof/skill.md"],
    "files_written": ["answer.txt"],
    "skills_activated": ["canary-proof"],
    "response_text": "AGY_SKILL_7M3K9",
    "thinking_duration_ms": 1995
  }
}
```

## Integration Points

### 1. `extract-session-summary.sh` (eval harness)

Add `agy)` case that calls `extract-agy-session.sh --format summary`. The judge receives the behavioral context just like kiro-cli and Codex.

### 2. `inspect-session.sh` (proof harness)

Add `agy)` case that calls `extract-agy-session.sh --format json` and runs assertions against the structured output. Same `log_checks` assertions apply:
- `file_read:path` → check `files_read` array
- `context_contains:str` → grep across all step text
- `tool_used:name` → check tool call steps

### 3. Eval harness `invoke_agent` (future)

Once we can extract response text, unblock agy as an eval subject:
```bash
# Run agy
agy --print "$input" --dangerously-skip-permissions
# Extract response for judge
response=$(extract-agy-session.sh --after "$start_time" --format json | jq -r '.summary.response_text')
```

## Step Types to Parse

| RPC step type | Our mapping | Contains |
|--------------|-------------|----------|
| `CORTEX_STEP_TYPE_USER_INPUT` | user_input | `userInput.userResponse` |
| `CORTEX_STEP_TYPE_PLANNER_RESPONSE` | model_response | `plannerResponse.response`, `.thinking`, `.thinkingDuration` |
| `CORTEX_STEP_TYPE_EPHEMERAL_MESSAGE` | system_prompt | `ephemeralMessage.content` (skills, rules injected here) |
| `CORTEX_STEP_TYPE_TOOL_CALL` | tool_call | Tool name, args, result |
| `CORTEX_STEP_TYPE_VIEW_FILE` | file_read | Path read |
| `CORTEX_STEP_TYPE_EDIT_FILE` | file_write | Path written |
| `CORTEX_STEP_TYPE_SHELL_COMMAND` | shell | Command, output |
| `CORTEX_STEP_TYPE_CHECKPOINT` | checkpoint | `checkpoint.userIntent` (session summary) |

## Risks

| Risk | Mitigation |
|------|-----------|
| language_server not running after `--print` exits | Check within 5s of agy exit; the process persists independently |
| CSRF token changes between runs | Re-discover each time (process args are stable per session) |
| Multiple language_server processes | Filter for `--app_data_dir antigravity` (CLI) vs `antigravity-ide` |
| RPC schema changes in agy updates | Pin to known step types; log unknown types as warnings |
| Port varies per launch | Always discover dynamically |

## Validation Criteria

- [ ] Extract response text from a `--print` run within 5s of completion
- [ ] Identify which files were read/written during the session
- [ ] Detect skill activation from ephemeral message content
- [ ] Works cross-platform (Windows discovery via PowerShell, Unix via ps/lsof)
- [ ] Integrates with existing `inspect-session.sh` assertion format

## Non-Goals

- Real-time streaming of agy output (wait for Issue #76 fix)
- Modifying agy behavior (we're read-only observers)
- Supporting Antigravity IDE sessions (different app_data_dir, different use case)
