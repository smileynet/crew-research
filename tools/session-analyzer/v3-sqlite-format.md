# kiro-cli v3 SQLite session format (`conversations_v2.value`)

_Characterized read-only from a live 2.27.0 DB, 2026-10-02 (ticket 169). Shared with
recall ticket 074 and the session-analyzer dead-path replacement. Characterize ONCE —
both readers use this map._

## Storage

- **Path:** Linux `~/.local/share/kiro-cli/data.sqlite3` (honor `$XDG_DATA_HOME`);
  macOS `~/Library/Application Support/kiro-cli/data.sqlite3`.
- **Open read-only** (`sqlite3 -readonly` / `OpenFlags::SQLITE_OPEN_READ_ONLY` /
  `sqlite3.connect("file:...?mode=ro", uri=True)`) — kiro-cli writes it live; never take a write lock.
- **Table `conversations_v2`:** `key TEXT` (= session cwd / project dir),
  `conversation_id TEXT`, `value TEXT` (conversation as JSON), `created_at`/`updated_at`
  (unix **ms**), PK `(key, conversation_id)`, index on `(key, updated_at DESC)`.
- One row = one conversation (not one message). The old `conversations` table is empty.

## `value` JSON (top-level dict)

Keys: `conversation_id, next_message, history, valid_history_range, transcript, tools,
context_manager, context_message_length, latest_summary, model_info, file_line_tracker,
mcp_*, user_turn_metadata`. The two that matter for analysis: **`history`** and **`transcript`**.

### `history` — list of turn objects

Each turn: `{ user: {...}, assistant: {...}, request_metadata: {...} }`.

**`user.content`** is a tagged union (one key present):
- `Prompt.prompt` → the user's prompt text  **(P1 correction scan source)**
- `ToolUseResults.tool_use_results[]` → `{ tool_use_id, content:[{Text: "..."}], status: "Success"|... }`
  **(P2 friction scan source; non-"Success" status / error text = failure)**

Also on `user`: `env_context.env_state.current_working_directory` (per-turn cwd),
`timestamp`, `images`, `additional_context`.

**`assistant`** is a tagged union:
- `Response.content` → assistant text
- `ToolUse.tool_uses[]` → `{ id, name, orig_name, args }` — **`name` is populated here**
  (unlike the stream-json `_meta.kiro.toolName` which is null). Use `name` for the
  FETCH_TOOLS filter + tool-id→name map.

### `transcript` — list of pre-rendered strings

Human-readable per-turn render, e.g. `"OK\n[Tool uses: none]"` or `"\n[Tool uses: thinking]"`.
Convenient for a coarse text scan but `history` is authoritative.

## Mapping to the JSONL message model (session_review.py)

| JSONL (v2) | v3 SQLite `history` |
|------------|---------------------|
| line `kind:Prompt` → `data` text | `turn.user.content.Prompt.prompt` |
| `AssistantMessage` toolUse `{toolUseId,name}` | `turn.assistant.ToolUse.tool_uses[].{id,name}` |
| `toolResult {toolUseId, ...}` | `turn.user.content.ToolUseResults.tool_use_results[].{tool_use_id, content[].Text, status}` |
| `.json` sidecar `cwd` | row `key` (or `turn.user.env_context.env_state.current_working_directory`) |
| file mtime (window filter) | `updated_at` (unix ms → /1000) |

## Dead path to replace (review 06)

`tools/session-analyzer/parse.py` / `extract_batches.py` glob
`~/.kiro/sessions/<hash>/sess_*/messages.jsonl` as a presumed "v3" layout — that layout
**never populated** (0 files). The real v3 store is this SQLite DB. Replace that glob,
don't leave it beside the SQLite reader.
