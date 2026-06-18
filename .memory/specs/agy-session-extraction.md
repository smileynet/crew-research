# Spec: Antigravity CLI Session Extraction via Local RPC

**Status:** Ready for implementation  
**Date:** 2026-06-18 (updated from 2026-06-14)  
**Depends on:** ADR 0006 (multi-tool deployment), spike results (RPC verified on Windows)

## Problem

agy `--print` drops stdout in non-TTY contexts (Issue #76). We cannot capture agent output for:
- Eval harness judge scoring
- Session log inspection (`inspect-session.sh`)
- Proof automation beyond "write to file" workaround

## Solution

A single Python script (`tools/evals/harness/extract_agy_session.py`) that calls the local language_server RPC post-run to retrieve the full session transcript, tool calls, and metadata.

## Design Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| 1 | Separate script called by `extract-session-summary.sh` | RPC complexity doesn't belong in a grep-based bash case block |
| 2 | Parse cascade_id from `--log-file` output | Exact match, no ambiguity with concurrent sessions |
| 3 | Persistent server preferred, log-file fallback | Ephemeral CLI server unreliable; IDE server persistent and holds CLI sessions |
| 4 | Try IDE server first, CLI server second, log-file third | Priority by reliability |
| 5 | Python for the extraction script | Native HTTPS/JSON/cross-platform; precedent in session-analyzer |
| 6 | RPC primary, file-write fallback | Clean prompt for eval (no mutation); richer data from RPC |
| 7 | `tools/evals/harness/extract_agy_session.py` | Collocated with callers |
| 8 | Stdlib only (zero dependencies) | Works immediately after clone; proven in spike |

## Architecture

```
agy --print "prompt" --log-file $tmplog     ← runs the task (output to TUI only)
       │
       ▼
language_server (IDE persistent OR CLI ephemeral)
       │
       ▼
extract_agy_session.py                      ← discovers port/token, calls RPC
  --log-file $tmplog                        ← parses cascade_id from log
  --format summary|json                     ← output mode
       │
       ├─→ extract-session-summary.sh  (agy case delegates here)
       └─→ inspect-session.sh          (agy case delegates here)
```

## Script: `tools/evals/harness/extract_agy_session.py`

### Interface

```
python extract_agy_session.py [--cascade-id ID] [--log-file PATH] [--format summary|json]
```

| Arg | Required | Description |
|-----|----------|-------------|
| `--cascade-id` | No | Specific session. Overrides log-file parsing. |
| `--log-file` | No | Parse cascade_id from agy log. Pattern: `Created conversation <uuid>` |
| `--format` | No | `summary` (default, text for eval judge) or `json` (structured for assertions) |

If neither `--cascade-id` nor `--log-file` provided, uses most recent session from RPC.

### Server Discovery (priority order)

1. **IDE persistent server** (`language_server_windows_x64.exe` / macOS `Antigravity.app`) — longest-running, holds all sessions
2. **CLI ephemeral server** (`language_server.exe` with `--app_data_dir antigravity`) — may be alive briefly after `--print`
3. **Fallback: exit with error JSON** — caller handles degraded mode

#### Windows
```python
# Get-CimInstance Win32_Process → parse --csrf_token from CommandLine
# Get-NetTCPConnection -OwningProcess PID -State Listen → port
```

#### macOS/Linux
```python
# ps -axo pid=,command= | grep language_server.*--csrf_token
# lsof -Pan -p PID -iTCP -sTCP:LISTEN → port
```

### RPC Protocol

```
POST https://127.0.0.1:{port}/exa.language_server_pb.LanguageServerService/{method}
Headers:
  Content-Type: application/json
  x-codeium-csrf-token: {token}
SSL: skip verification (self-signed localhost cert)
```

Methods:
- `GetAllCascadeTrajectories` → `{}` → list all sessions (for "most recent" fallback)
- `GetCascadeTrajectorySteps` → `{"cascadeId": "...", "startIndex": 0, "endIndex": 100}` → full steps

### Cascade ID from Log File

```python
# Log line pattern:
# I0614 17:33:36.765707 83796 server.go:755] Created conversation f266be93-...
re.search(r"Created conversation ([0-9a-f-]{36})", log_content)
```

### Output: Summary Format (for eval judge)

```
--- Session Behavioral Summary ---
Total tool invocations: 3
Errors encountered: 0
Retry patterns detected: 0

Tool usage breakdown:
  2 ViewFile
  1 EditFile

Files accessed:
  .agents/skills/canary-proof/skill.md
  answer.txt

Skills activated (from ephemeral messages):
  canary-proof

Model response (first 500 chars):
  AGY_SKILL_7M3K9

Thinking duration: 1.99s
--- End Summary ---
```

### Output: JSON Format (for assertions)

```json
{
  "cascade_id": "555c79eb-...",
  "steps": [
    {"type": "USER_INPUT", "text": "..."},
    {"type": "EPHEMERAL_MESSAGE", "text": "..."},
    {"type": "PLANNER_RESPONSE", "response": "...", "thinking": "...", "duration_s": 1.99},
    {"type": "TOOL_CALL", "tool": "EditFile", "path": "answer.txt"}
  ],
  "summary": {
    "tool_calls": 3,
    "errors": 0,
    "files_read": ["..."],
    "files_written": ["..."],
    "skills_activated": ["canary-proof"],
    "response_text": "AGY_SKILL_7M3K9",
    "thinking_duration_ms": 1995
  }
}
```

### Error Output (no server available)

```json
{"error": "no language_server found", "fallback": "log-file-only"}
```

Exit code 0 always — caller decides severity.

## Integration Points

### 1. `extract-session-summary.sh` (eval harness)

```bash
agy)
  python "$SCRIPT_DIR/extract_agy_session.py" --format summary
  ;;
```

### 2. `inspect-session.sh` (proof harness)

```bash
agy)
  local json=$(python "$SCRIPT_DIR/../evals/harness/extract_agy_session.py" --format json)
  # Run assertions against JSON
  ;;
```

### 3. Eval harness `invoke_agent` (agy case)

```bash
local logfile=$(mktemp "$workdir/.agy-log-XXXX")
agy --print "$input" --dangerously-skip-permissions --log-file "$logfile"
sleep 2  # grace period for server to register trajectory
local response=$(python "$SCRIPT_DIR/extract_agy_session.py" --log-file "$logfile" --format json | jq -r '.summary.response_text')
rm -f "$logfile"
```

## Step Types to Parse

| RPC step type | Our mapping | Field |
|--------------|-------------|-------|
| `CORTEX_STEP_TYPE_USER_INPUT` | user_input | `userInput.userResponse` |
| `CORTEX_STEP_TYPE_PLANNER_RESPONSE` | model_response | `plannerResponse.response`, `.thinking`, `.thinkingDuration` |
| `CORTEX_STEP_TYPE_EPHEMERAL_MESSAGE` | system_prompt | `ephemeralMessage.content` |
| `CORTEX_STEP_TYPE_VIEW_FILE` | file_read | Path from step payload |
| `CORTEX_STEP_TYPE_EDIT_FILE` | file_write | Path from step payload |
| `CORTEX_STEP_TYPE_SHELL_COMMAND` | shell | Command from step payload |
| `CORTEX_STEP_TYPE_CHECKPOINT` | checkpoint | `checkpoint.userIntent` |

## Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| IDE not running | Fall back to error JSON; eval harness skips log analysis for this trial |
| CSRF token changes between runs | Re-discover each invocation (process args are stable per process lifetime) |
| Multiple language_server processes | Filter by `--app_data_dir`; prefer longest-running (IDE) |
| RPC schema changes in agy updates | Log unknown step types as warnings; don't crash |
| Port varies per launch | Always discover dynamically from process TCP connections |
| Cascade_id not in log | Fall back to most-recent from `GetAllCascadeTrajectories` |

## Implementation Tasks

1. [ ] Create `tools/evals/harness/extract_agy_session.py` (discovery + RPC + formatting)
2. [ ] Add `agy)` case to `extract-session-summary.sh`
3. [ ] Add `agy)` case to `inspect-session.sh`
4. [ ] Test: run `agy --print` with `--log-file`, extract via script, verify response text matches
5. [ ] Test: run proof G1 with log inspection enabled

## Non-Goals

- Real-time streaming of agy output (wait for Issue #76 fix)
- Modifying agy behavior (read-only observer)
- Supporting Antigravity IDE-only sessions (we extract CLI sessions via the shared harness)
- External dependencies (stdlib only)
