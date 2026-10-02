# kiro-cli stream-json schema (proof/eval grading reference)

_Empirical, kiro-cli 2.27.0, 2026-10-02 (tickets 125 + 168). Raw captures:
`tools/proofs/docs/discovery-raw/*.jsonl`. Engine notes + headless behavior:
`tools/proofs/docs/v3-engine-notes.md`._

`kiro-cli chat --no-interactive --output-format stream-json` emits **JSON Lines** on
stdout (one `{"type":...,"data":{...}}` per line). Works on `--agent-engine v2` and
`v3`; `--wrap never` does not interfere (Test 5: clean, valid JSON). stdout = events;
diagnostics go to stderr — never merge (`2>&1` corrupts the stream).

## Envelope (both engines)

```
runStarted            # first event
  data: {engine: "v2"|"v3", payloadSchema: "acp", acpProtocolVersion: 1}
sessionUpdate ...     # N content/progress events (ACP session/update notifications)
runFinished           # TERMINAL event
  data: {status: "success", stopReason: "end_turn", finalText: "<full reply>", finalTextTruncated: bool}
```

- **Terminal event = `runFinished`.** Final assistant text = `.data.finalText`
  (complete, no chunk reassembly needed). This is the authoritative source for
  `expect.present/absent` text grading — NOT `.type=="result"`/`.result` (that was the
  Cursor/Claude-schema guess; kiro speaks ACP v1).
- Absence of `runFinished` = error → check stderr + exit code.

## sessionUpdate subtypes (`.data.update.sessionUpdate`)

| Subtype | Engine | Meaning |
|---------|--------|---------|
| `agent_message_chunk` | v2 + v3 | streamed assistant text (`.data.update.content.text`) |
| `tool_call` | v2 + v3 | a tool invocation starts |
| `tool_call_update` | v2 + v3 | tool status upsert (`in_progress`→`completed`), keyed by `toolCallId` |
| `metadata` *(top-level `.type`)* | v2 | progress ticks (sessionId, contextUsagePercentage, turnDurationMs) |
| `session_info_update` | **v3 only** | progress/info (replaces v2 `metadata` volume) |
| `available_commands_update` | **v3 only** | slash-command catalog |
| `config_option_update` | **v3 only** | config/option state |

Consumers MUST ignore unknown subtypes (ACP is additive). A trivial "OK" reply is ~7
events on v2, ~25–29 on v3 (the extra v3 info subtypes).

## 🔴 tool identity — the one breaking delta

A v3 `tool_call` event:
```json
{"sessionUpdate":"tool_call","toolCallId":"toolu_...","title":"Read File",
 "kind":"read","locations":[{"path":"..."}],"rawInput":{"path":"..."},
 "_meta":{"kiro":{"toolOrigin":"default"}}}
```
**`_meta.kiro.toolName` is `null` on v3** (`_meta.kiro` only carries `toolOrigin`).
Read the tool from **`kind`** (`"read"`, `"write"`, ...) or **`title`** (`"Read File"`).
Input is on `rawInput`; file paths also appear in `locations[].path`. (v2's older
on-disk session JSONL carried `toolName`; the ACP stream does not.)

## jq grading patterns (for ticket 124 `grade_events()`)

```bash
# Final assistant text (for expect.present/absent)
jq -r 'select(.type=="runFinished") | .data.finalText // ""' events.jsonl

# Terminal status / stop reason
jq -c 'select(.type=="runFinished") | {status:.data.status, stop:.data.stopReason}' events.jsonl

# Did the agent call a tool of a given kind? (exit 0 = yes) — use kind, NOT toolName
jq -e --arg k read 'any(inputs;
  .type=="sessionUpdate" and .data.update.sessionUpdate=="tool_call"
  and .data.update.kind==$k)' events.jsonl

# Count tool calls (match tool_call only; tool_call_update is the status upsert)
jq -n 'reduce (inputs | select(.type=="sessionUpdate"
  and .data.update.sessionUpdate=="tool_call")) as $e (0; .+1)' events.jsonl

# Tool call whose input references a path (input_contains)
jq -e --arg s canary 'any(inputs;
  .type=="sessionUpdate" and .data.update.sessionUpdate=="tool_call"
  and ((.data.update.rawInput|tostring) | contains($s)))' events.jsonl

# Robust: skip malformed lines
jq -R 'fromjson? // empty | ...' events.jsonl
```

Proposed `events:` grammar for proof definitions (ticket 124) maps directly:
`events.present[].type: tool_call` + `kind:` / `input_contains:`; `events.absent[]`;
`events.count[] {min,max}`. Grade `kind`, never `toolName`.

## Why this replaces inspect-session.sh

`inspect-session.sh` finds the session log by mtime (`ls -t | head -1`) — a race that
can grade the wrong session, and on v3 it cannot parse the session store at all (SQLite
`conversations_v2` + changed layout; see v3-engine-notes.md "Harness integration").
Capturing the trial's own stdout event stream removes both the race and the v3
incompatibility. That migration is ticket 124.
