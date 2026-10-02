# kiro-cli v3 Headless Engine Notes (spike 168, empirical)

_Probed 2026-10-02 on **kiro-cli 2.27.0**, Linux, GNU timeout 8.32. Auth:
IamIdentityCenter (no KIRO_API_KEY). All runs `timeout -k 5s`, isolated
`mktemp -d` + `KIRO_HOME=$W/.kiro`, stdout/stderr separated. Raw captures:
`.scratch/research/t168/test{1,2,3,5,6,7v2,7v3}.jsonl`._

## Headline results

| Question | Verdict | Evidence |
|----------|---------|----------|
| Does v3 run headless on 2.27.0? | **YES** (old Known Gap is dead) | test1: `--agent-engine v3 --no-interactive` → `engine:"v3"`, `finalText:"OK"`, exit 0 |
| v3 stream-json schema vs v2? | **Same wrapper + ACP v1; v3 adds 3 info subtypes; tool-name field MOVED** | see schema delta below |
| Does `--trust-all-tools` work on v3 headless (#7398)? | **YES, no hang, no prompt** | test3: exit 0, clean `OK`. Contradicts 2.19.2 "v3 rejects -a" |
| `--trust-tools=read` on v3? | **Works** | test2: read tool ran, canary quoted, exit 0 |
| KIRO_API_KEY required for headless v3? | **NO on this account** — IdC session serves it | `whoami` → `IamIdentityCenter`; no key set; all v3 runs succeeded |
| Default engine for unflagged `--no-interactive`? | **v2** (NOT v3, despite `--help` wording) | test5: `engine:"v2"`; no `chat.agentEngine` setting exists |
| v2 regression? | **None** | test6: `engine:"v2"`, exit 0, `OK` |
| 🔴 v3 non-interactive skill-discovery bug (internal 2026-09-22)? | **DOES NOT REPRODUCE on 2.27.0** | test7 A/B: v2 AND v3 both activated the fixture skill (`SKILL_ACTIVATED_ZXQ9`) with identical fixtures |
| Untrusted fresh workdir, v3 headless? | **Ran fine, exit 0** | test8: no trust-gate block observed for a simple reply |

## Stream-json schema delta (v3 vs v2)

**Wrapper unchanged:** `runStarted` → N× `sessionUpdate` → `runFinished`.
`runStarted.data` = `{engine, payloadSchema:"acp", acpProtocolVersion:1}`.
`runFinished.data` = `{status:"success", stopReason:"end_turn", finalText}`.
Terminal event = `runFinished`. **ACP protocol version is still 1** → no v1→v2 flip.

**v3 adds sessionUpdate subtypes not seen in the v2 capture:**
`session_info_update` (many — the bulk of the event count), `available_commands_update`,
`config_option_update`. Content/tool subtypes unchanged: `agent_message_chunk`,
`tool_call`, `tool_call_update`. Consumers must **ignore unknown subtypes** (ACP is
additive) — a trivial "OK" reply emitted 25 events (15 `session_info_update`).

**🔴 Breaking delta for grading — tool name moved:**
In v3 a `tool_call` event is:
```json
{"sessionUpdate":"tool_call","toolCallId":"toolu_...","title":"Read File",
 "kind":"read","locations":[{"path":"..."}],"rawInput":{"path":"..."},
 "_meta":{"kiro":{"toolOrigin":"default"}}}
```
`_meta.kiro.toolName` is **null** in v3 (`_meta.kiro` carries only `toolOrigin`).
The v2 extraction path `.data.update._meta.kiro.toolName` returns null on v3.
**Use `kind` (e.g. `"read"`) or `title` (`"Read File"`) instead.** `tool_call` +
`tool_call_update` (status `in_progress`→`completed`, upsert by `toolCallId`) both
present — match BOTH.

jq (v3-safe):
```bash
# tool invocations by kind
jq -c 'select(.type=="sessionUpdate" and .data.update.sessionUpdate=="tool_call")
       | {id:.data.update.toolCallId, kind:.data.update.kind, title:.data.update.title}' events.jsonl
# final text
jq -r 'select(.type=="runFinished")|.data.finalText' events.jsonl
```

## Containment (verified)

- `~/.kiro/settings/` sha256 before==after (10 files) ✓
- No `~/.kiro/settings/permissions.yaml` created ✓
- `git status` clean ✓
- No orphan/hung probe PIDs (all `timeout`-wrapped runs exited 0; the long-running
  `-a -r` kiro-cli PIDs on the host are OTHER interactive sessions — not touched) ✓
- **KIRO_HOME does NOT redirect the session WRITE path** (ticket-125 item 5 answered):
  probe sessions landed in the real `~/.kiro/sessions/cli/*.jsonl` with fresh
  timestamps. Benign (unique UUIDs) but note for cleanup — sweep by UUID if needed.

## Per-ticket unblock mapping

- **126 (harness v3 path):** UNBLOCKED. v3 headless works; `-a`/`--trust-all-tools`
  AND `--trust-tools=read` both work on v3 (no permissions.yaml needed, no #7398
  hang). The adapter engine selector can add a v3 option that keeps `-a` — the
  2.19.2 "v3 rejects -a, needs permissions.yaml" constraint is GONE. One required
  code change: any event grading must read tool identity from `kind`/`title`, NOT
  `_meta.kiro.toolName` (null on v3). `extract-session-summary.sh:49-73` needs the
  same fix if used on v3 streams.
- **169 (session-analyzer SQLite) / recall-74:** engine-independent — unaffected by
  these findings. The SQLite cutover risk stands on its own; proceed as written.
- **124 (proof-harness event grading):** the `_meta.kiro.toolName` assumption in its
  design is v2-only — grade on `kind`/`title` for v3 compatibility.
- **Skill-activation evals on v3 headless:** SAFE — the 2026-09-22 skill-discovery
  bug does not reproduce on 2.27.0, so eval/activation harnesses can run v3 headless
  without false-negative skill loading. (Keep the A/B control for future versions.)

## Harness integration (ticket 126, 2026-10-02)

The proof harness now has an optional engine selector:
`invoke.engine` in `adapters/kiro-cli.yaml` (default unset = binary default v2),
overridable per-run with `PROOF_ENGINE=v3`. `run.sh` injects `--agent-engine <e>`
after `kiro-cli chat` when set.

E2e on proof A4 (2.27.0):
- **Default (v2):** PASS (text grading + log_check).
- **`PROOF_ENGINE=v3`:** the **text-grading stage PASSES** (agent ran on v3, reported
  the canary) — the engine injection works end-to-end. The **`log_checks` stage
  FAILS** because `inspect-session.sh` cannot locate/parse the v3 session store
  (v3 writes SQLite `conversations_v2` + a different `sessions/` layout than the v2
  inspector greps). This is **ticket 124's domain** (replace session-log inspection
  with stream-json event grading), NOT a defect in the engine selector.

**Takeaway:** v3 proofs that rely only on `expect.present/absent` (stdout text) work
today via `PROOF_ENGINE=v3`. v3 proofs that rely on `log_checks` need ticket 124's
stream-json event grading first. Until then, keep `log_checks`-based proofs on the
default (v2) engine.

## Caveats / residual unknowns

- Default headless engine is **v2** on this 2.27.0 build — so to exercise v3 you MUST
  pass `--agent-engine v3` explicitly. The staged default flip hasn't reached headless
  here. Re-check on future versions; always DETECT via `runStarted.data.engine`.
- #7398 (trust-all prompt hang) not reproduced here, but it's version/path-specific
  per the issue — keep the `timeout -k` guard in any CI path.
- Did NOT test MCP-dependent runs (`--require-mcp-startup` exit-3 / 30s window) or
  Midway-gated builder-mcp tools headless — out of scope for this spike; the
  two-plane model (KIRO_API_KEY=inference, Midway=internal tools) is documented in
  `.scratch/research/t168/02-trust-apikey.md`.
