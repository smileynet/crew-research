---
id: "125"
title: "Run stream-json schema discovery proof"
status: open
blocked_by: []
---

# Run stream-json schema discovery proof

## Purpose

Empirically document kiro-cli's `--output-format stream-json` event schema before building harness integration (ticket 124). The flag is officially documented at kiro.dev/docs/cli/headless/ but the **event schema is not documented anywhere** — only that it emits "run events as JSON Lines."

## Key findings from research

- `--output-format stream-json` implies `--no-interactive` (don't need both)
- Does NOT imply `-a` (trust-all-tools) — must add explicitly or tool calls stall
- Requires `--agent-engine v2` or `v3` (v2 is the current default)
- Cursor CLI uses: system/init → user → assistant → tool_call(started/completed) → result
- kiro-cli version installed: 2.19.2 ✅
- Current harness uses `> "$tmpfile" 2>&1` (merged stdout+stderr) — stream-json requires separate capture

## What to build

A discovery script (`tools/proofs/harness/discover-stream-json.sh`) that runs test cases and writes schema documentation.

### Test matrix

| # | Command | What it reveals |
|---|---------|----------------|
| 1 | `-a --output-format stream-json "Reply with exactly: OK"` | Minimal event set, result shape, whether text is suppressed |
| 2 | `-a --output-format stream-json "Read ./test.txt and quote its contents"` | tool_call event shape |
| 3 | `-a --output-format stream-json --agent test-agent "Quote the canary"` | Agent compat, system/init event |
| 4 | `-a --output-format stream-json --agent-engine v3 "Reply OK"` | v3 differences |
| 5 | `-a --output-format stream-json --wrap never "Reply OK"` | Flag interaction (redundant?) |

Note: `-a` is needed in all cases (research confirmed `stream-json` implies `--no-interactive` but NOT tool trust).

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

## Acceptance criteria

- [ ] All 5 test cases run (or failure modes documented with stderr output)
- [ ] Event type vocabulary documented with field names and types
- [ ] `result` event text extraction jq pattern confirmed (ticket 124 needs this)
- [ ] `tool_call` event shape documented (tool name field, input/output presence)
- [ ] Flag interactions documented (--agent, --wrap never, --agent-engine v2 vs v3)
- [ ] Schema comparison with Cursor CLI noted (field name deltas)
- [ ] Findings written to `tools/proofs/docs/stream-json-schema.md`
- [ ] Raw captured JSONL saved to `tools/proofs/docs/discovery-raw/` for reference
