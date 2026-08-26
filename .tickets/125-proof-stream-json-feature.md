---
id: "125"
title: "Run stream-json schema discovery proof"
status: open
blocked_by: []
---

# Run stream-json schema discovery proof

## Purpose

Empirically document kiro-cli's `--output-format stream-json` event schema before building harness integration (ticket 124). No public docs exist for kiro-cli's specific schema — Cursor CLI and Claude Code use similar patterns but field names may differ.

## What to build

A discovery script that exercises stream-json in multiple configurations and documents the actual schema.

### Test matrix

| # | Command | What it reveals |
|---|---------|----------------|
| 1 | `--output-format stream-json "Reply with exactly: OK"` | Minimal event set, result event shape |
| 2 | `--output-format stream-json "Read the file ./test.txt and quote its contents"` (with fixture) | tool_call event shape, input/output fields |
| 3 | `--output-format stream-json --agent test-agent "..."` (with agent) | Agent compatibility, system/init event |
| 4 | `--output-format stream-json --agent-engine v2 "OK"` | v2 vs v3 differences |
| 5 | `--output-format stream-json --wrap never "OK"` | Flag interaction |

### For each test, capture and document

- Full raw JSONL output
- Event `type` vocabulary (list all unique types)
- Field names per event type
- Whether normal text is suppressed or interleaved
- Terminal event behavior (is `result` always last?)
- Error behavior (what happens on tool failure?)

### Deliverable

Write `tools/proofs/docs/stream-json-schema.md`:
- Event type table (type → fields → example)
- Mapping to existing `log_checks` assertions
- Gaps (anything `inspect-session.sh` can do that stream-json can't)
- Recommended jq patterns for each assertion type

## Acceptance criteria

- [ ] All 5 test cases run successfully (or failure modes documented)
- [ ] Event type vocabulary documented with field names
- [ ] `result` event text extraction pattern confirmed (needed by ticket 124)
- [ ] `tool_call` event shape documented (tool name, input, output fields)
- [ ] Flag interactions documented (--agent, --wrap never, --agent-engine)
- [ ] Schema comparison with Cursor/Claude Code noted (deltas highlighted)
- [ ] Findings written to `tools/proofs/docs/stream-json-schema.md`
