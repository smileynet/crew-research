---
id: "125"
title: "Run stream-json schema discovery proof"
status: open
blocked_by: []
tags: [kiro-v3]
---

> **Plan-sync note (2026-08-28):** ticket 130's live e2e work independently
> characterized the full stream-json / ACP v1 schema (tool-using runs included)
> and it's now documented in `atomics/skills/dispatch-review/references/model-matrix.md`,
> the opencode adapter `output.json` block, and `.scratch/research/t127|t130/`. So
> the *knowledge* half of this ticket is DONE. Remaining discrete work: (a) test 5
> `--wrap never` interaction, (b) produce the canonical `tools/proofs/docs/stream-json-schema.md`
> deliverable, (c) save raw captures. Reduced scope, not superseded — do NOT re-run
> discovery from scratch. Blocks 124 (proof-harness event grading).

# Run stream-json schema discovery proof

## Purpose

Empirically document kiro-cli's `--output-format stream-json` event schema before building harness integration (ticket 124). The flag is officially documented at kiro.dev/docs/cli/headless/ but the **event schema is not documented anywhere** — only that it emits "run events as JSON Lines."

## Key findings (EMPIRICALLY CONFIRMED, tests 1-3 run 2026-08-26)

The schema is **ACP v1** — Zed Industries' Agent Client Protocol (open standard, Apache-2.0, machine-readable JSON Schema at `agentclientprotocol.com/protocol/v1/schema`). kiro-cli's `payloadSchema:acp, acpProtocolVersion:1` speaks ACP's `session/update` vocabulary verbatim. This is NOT the Cursor/Claude Code schema researched earlier.

### Actual event schema (confirmed)

| Event `type` | Purpose | Key fields |
|-------------|---------|-----------|
| `runStarted` | Session start (kiro envelope, not ACP) | `data.payloadSchema:acp`, `data.acpProtocolVersion:1`, `data.engine` |
| `metadata` | Progress ticks | `data.sessionId`, `data.contextUsagePercentage`, `data.turnDurationMs` (last one) |
| `sessionUpdate` | Content wrapper (ACP notification) | `data.update.sessionUpdate` = discriminator |
| → `agent_message_chunk` | Streamed text | `data.update.content.text` |
| → `tool_call` | Tool started | `toolCallId`, `kind`, `rawInput`, `_meta.kiro.toolName` |
| → `tool_call_update` | Tool completed (upsert by toolCallId) | adds `status`, `rawOutput` |
| `runFinished` | Terminal (kiro envelope, not ACP) | `data.status`, `data.stopReason`, `data.finalText`, `data.finalTextTruncated` |

Confirmed facts:
- **Default engine is v1, which REJECTS stream-json** — must always pass `--agent-engine v2`
- `runFinished.data.finalText` = complete concatenated response (no chunk assembly needed)
- Tool name at `data.update._meta.kiro.toolName`; full input at `rawInput`, output at `rawOutput`
- `--agent` works but `runStarted` carries NO agent metadata (can't detect which agent loaded)
- No stderr on success; JSON stream is stdout-only
- Consumers should ignore unknown `sessionUpdate` subtypes (ACP allows additive subtypes within v1)

### jq extraction patterns (for ticket 124)

```bash
# Final response text
jq -rn 'last(inputs | select(.type=="runFinished") | .data.finalText) // ""' events.jsonl

# Did the agent call a specific tool? (exit 0 = yes)
jq -ne 'any(inputs; .type=="sessionUpdate" and .data.update.sessionUpdate=="tool_call" and .data.update._meta.kiro.toolName=="read")' events.jsonl

# Count tool calls
jq -n 'reduce (inputs | select(.type=="sessionUpdate" and .data.update.sessionUpdate=="tool_call")) as $e (0; .+1)' events.jsonl

# Skip malformed lines
jq -R 'fromjson? | select(...)' events.jsonl
```

## Disruption analysis: will proofs interfere with active v2 sessions?

**Verdict: No — and the stream-json approach REMOVES an existing cross-session hazard.**

| Fact | Source |
|------|--------|
| Each `kiro-cli chat` invocation is an independent OS process with its own session UUID (confirmed: tests 1/2/3 got distinct UUIDs) | [L1:verified] empirical |
| Only hard lock is per-session-UUID; fresh sessions never collide. `kiro-cli acp` daemon has a singleton limit (#6640) but ordinary `chat` subprocesses do not | [L4:established] |
| Sessions stored per-file keyed by UUID (v2: `~/.kiro/sessions/cli/<id>.jsonl`); a new session writes a new file, never touches this session's log | [L1:verified] repo + empirical |
| stream-json output is stdout-only — we consume it directly, never read the shared session tree | [L1:verified] empirical |
| Eval harness already runs kiro-cli subprocesses safely (sequential, `KIRO_HOME=$workdir/.kiro`, `mktemp -d`, delete-after) | [L1:verified] run.sh |

**The hazard stream-json removes:** the OLD `inspect-session.sh` finds the session to grade via `find ~/.kiro/sessions/cli/ | xargs ls -t | head -1` ("most recent by mtime") — a concurrent session (including this one) writing its log during a proof run could cause the WRONG session to be graded. Consuming the trial's own stdout stream eliminates this read-side race entirely (this is ticket 124's core value).

**The one real disruption risk — AVOID:** v3's trust model replaces `-a` with a **user-global** `~/.kiro/settings/permissions.yaml`. The documented v3 CI recipe (`{capability: all, effect: allow}`) is user-scoped and WOULD weaken trust prompts for interactive sessions too. Do NOT adopt it. Pin proofs to **v2 + `-a`** (workdir-scoped, mutates no global config).

### Recommendation: pin proofs to v2, not v3

- v2 supports `-a` (workdir-scoped tool trust) — no global config mutation
- v3 requires user-global `permissions.yaml` — the only part of this effort that could affect live sessions
- stream-json works identically on both (confirmed on v2)
- v3 is early-access, TUI-required, not resumable in v2 — wrong fit for a headless proof harness
- Test 4 (v3) is document-only — capture the trust-model difference, then standardize on v2

### Isolation checklist for the discovery script and ticket 124

1. `mktemp -d` workdir per invocation + `cd` into it (fixture discovery via cwd walk-up)
2. `--agent-engine v2 -a` (never change global engine or trust config)
3. Separate stdout/stderr: `> events.jsonl 2>err.log` (NOT `2>&1` — merging corrupts JSON)
4. `git status` clean-check after runs (containment regression guard — precedent: ticket 11 README overwrite)
5. Open question to verify: does the throwaway session get written to the real `~/.kiro/sessions/cli/`? (repo has no evidence KIRO_HOME redirects the session-WRITE path, only config read). Harmless if so, but document it.

## What to build

A discovery script (`tools/proofs/harness/discover-stream-json.sh`) that runs test cases and writes schema documentation.

### Test matrix (tests 1-3 ✅ done, 4-5 pending)

| # | Command | Status / finding |
|---|---------|----------------|
| 1 | `-a --agent-engine v2 --output-format stream-json "Reply with exactly: OK"` | ✅ 6 events, clean ACP output |
| 2 | `-a --agent-engine v2 --output-format stream-json "Read ./test.txt and quote its contents"` | ✅ 23 events, tool_call/tool_call_update shapes captured |
| 3 | `-a --agent-engine v2 --output-format stream-json --agent test-agent "Quote the canary"` | ✅ 14 events, agent works but no agent metadata in stream |
| 4 | `--agent-engine v3 --output-format stream-json "Reply OK"` (NO `-a` — v3 rejects it) | ⏳ document-only: v3 rejects `-a`, uses permissions.yaml |
| 5 | `-a --agent-engine v2 --output-format stream-json --wrap never "Reply OK"` | ⏳ flag interaction check |

CONFIRMED: `--agent-engine v2` is MANDATORY — default is v1, which errors: "not supported on the v1 engine." Tests 4 (v3) is run without `-a` because v3 rejects trust-all-tools (capability model). Proofs will standardize on **v2 + -a** (see disruption analysis).

### Implementation

```bash
#!/bin/bash
# tools/proofs/harness/discover-stream-json.sh
set -euo pipefail

WORKDIR=$(mktemp -d -t "stream-json-discovery-XXXX")
trap "rm -rf $WORKDIR" EXIT

# Verify version
VERSION=$(kiro-cli --version 2>&1 | grep -oP '\d+\.\d+\.\d+')
echo "kiro-cli version: $VERSION"

# Create fixture for test 2
echo "CANARY_DISCOVERY_8K3M7" > "$WORKDIR/test.txt"

# Create agent for test 3
mkdir -p "$WORKDIR/.kiro/agents"
cat > "$WORKDIR/.kiro/agents/test-agent.json" << 'EOF'
{"name":"test-agent","description":"Test agent","tools":["*"],"allowedTools":["*"],"resources":[],"prompt":"Quote any canary values you find."}
EOF

# Run tests — stdout (events) separate from stderr (diagnostics)
for i in 1 2 3 4 5; do
  case $i in
    1) (cd "$WORKDIR" && kiro-cli chat -a --output-format stream-json "Reply with exactly: OK") > "$WORKDIR/test$i.jsonl" 2>"$WORKDIR/test$i.err" || true ;;
    2) (cd "$WORKDIR" && kiro-cli chat -a --output-format stream-json "Read the file ./test.txt and quote its contents") > "$WORKDIR/test$i.jsonl" 2>"$WORKDIR/test$i.err" || true ;;
    3) (cd "$WORKDIR" && kiro-cli chat -a --output-format stream-json --agent test-agent "Quote the canary phrase from test.txt") > "$WORKDIR/test$i.jsonl" 2>"$WORKDIR/test$i.err" || true ;;
    4) (cd "$WORKDIR" && kiro-cli chat -a --output-format stream-json --agent-engine v3 "Reply with exactly: OK") > "$WORKDIR/test$i.jsonl" 2>"$WORKDIR/test$i.err" || true ;;
    5) (cd "$WORKDIR" && kiro-cli chat -a --output-format stream-json --wrap never "Reply with exactly: OK") > "$WORKDIR/test$i.jsonl" 2>"$WORKDIR/test$i.err" || true ;;
  esac

  # Validate JSONL and extract schema
  echo "=== Test $i ==="
  echo "Lines: $(wc -l < "$WORKDIR/test$i.jsonl")"
  echo "Event types: $(jq -r '.type // "NO_TYPE"' "$WORKDIR/test$i.jsonl" 2>/dev/null | sort -u)"
  echo "Fields per type:"
  jq -c '[.type, (keys | sort)]' "$WORKDIR/test$i.jsonl" 2>/dev/null | sort -u
  echo ""
done

# Copy raw outputs for documentation
cp -r "$WORKDIR"/test*.jsonl "$WORKDIR"/test*.err tools/proofs/docs/discovery-raw/
```

### Critical design notes (from research)

1. **Separate stdout from stderr** — use `> file.jsonl 2>file.err`, NOT `2>&1`. The current harness merges them which would corrupt the JSON stream.
2. **Don't pass `--no-interactive`** — it's implied by `--output-format stream-json` (confirmed in kiro-cli --help).
3. **Always pass `-a`** — without it, untrusted tool calls stall with no way to approve.
4. **cd into workdir** — so kiro-cli finds `.kiro/` fixtures via cwd walk-up.
5. **jq is sufficient** — no need for genson/quicktype at discovery stage; infer schema visually from samples.

### Deliverable

Create `tools/proofs/docs/stream-json-schema.md`:
- Event type table (type → subtypes → fields → example JSON)
- Mapping: `log_checks` assertion → equivalent jq pattern
- Gaps: what `inspect-session.sh` can do that stream-json can't
- Flag interaction matrix
- Comparison with Cursor CLI schema (deltas highlighted)

## Session findings (2026-08-26/27)

### Tests 1-3: DONE ✅ (v2 engine)

Schema fully captured on `--agent-engine v2` (see "Key findings" above and `.scratch/research/t125/`). ACP v1 confirmed. Raw captures in `.scratch/stream-json-discovery/test{1,2,3}.jsonl`.

### Test 4 (v3): BLOCKED — v3 cannot run headless on this build

Empirically confirmed (kiro-cli 2.19.2, bounded via PowerShell `Start-Job` + `Wait-Job -Timeout`):

1. `--agent-engine v3 -a` → **fails fast**: `error: the following arguments are not supported with --agent-engine=v3: --trust-all-tools`, then `runError` at init stage `"server shut down unexpectedly"`, then `ACP initialize failed`. v3 rejects the trust flag (capability model).
2. `--agent-engine v3` (no `-a`) → **hangs**. The `--help` text confirms why: v3/KAS session lifecycle (`session/new`) is "Forwarded to the TUI." kiro.dev v3 "Known Gaps" states verbatim: *"The legacy non-TUI mode (kiro-cli chat without the TUI) does not support the v3 engine. Use the TUI."*

**Conclusion: v3 has no non-TUI/headless code path on this build.** Proofs and the eval harness MUST use `--agent-engine v2`. This is not a flag-tweaking problem — the non-TUI path does not exist for v3. Docs contradict themselves (headless page couples v3+`--no-interactive`; v3 Known Gaps forbids it) — the installed build follows Known Gaps.

**Flag spelling confirmed:** installed binary uses `--agent-engine <v1|v2|v3>` (NOT `--engine`, which appears only in kiro.dev docs). `--v3` is a separate interactive-only flag.

### Testing technique that works (recorded for resume)

To test a potentially-hanging kiro-cli invocation without wedging the session, wrap it in a PowerShell job with a timeout:
```powershell
$j = Start-Job -ScriptBlock { & kiro-cli chat --no-interactive --agent-engine v3 --output-format stream-json "PROMPT" 2>&1 }
if (Wait-Job $j -Timeout 20) { "COMPLETED"; Receive-Job $j } else { "TIMED OUT"; Stop-Job $j }
Remove-Job $j -Force
```

### Remaining work (on resume)

- Test 5 (`--wrap never` on v2) — quick flag-interaction check
- Write `tools/proofs/docs/stream-json-schema.md` from tests 1-3 (schema is already fully known — this is documentation, not more testing)
- Save raw captures to `tools/proofs/docs/discovery-raw/`
- Clean up hung v3 processes from failed headless attempts (12+ leftover kiro-cli PIDs from testing — do NOT kill PID of the active interactive session; identify via lock-holder, not start time)

## Acceptance criteria

- [x] Tests 1-3 run; event schema captured (ACP v1: runStarted/metadata/sessionUpdate/runFinished)
- [x] Event type vocabulary documented with field names (in ticket + research files)
- [x] `runFinished.data.finalText` extraction jq pattern confirmed (ticket 124 needs this)
- [x] `tool_call`/`tool_call_update` shape documented (_meta.kiro.toolName, rawInput, rawOutput)
- [x] v3 engine finding documented (cannot run headless — pin to v2)
- [ ] Test 5 (`--wrap never`) flag interaction — DEFERRED to resume
- [ ] Findings written to `tools/proofs/docs/stream-json-schema.md` — DEFERRED to resume
- [ ] Raw captured JSONL saved to `tools/proofs/docs/discovery-raw/` — DEFERRED to resume
