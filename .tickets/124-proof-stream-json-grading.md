---
id: "124"
title: "Add stream-json event grading to proof harness"
status: open
blocked_by: ["125"]
tags: [kiro-v3]
---

# Add stream-json event grading to proof harness

> **v3 gating note (2026-10-02, from spikes 168 + 126):** this ticket is now ALSO
> the v3-headless blocker for `log_checks`-based proofs. Ticket 126 added a proof
> engine selector (`PROOF_ENGINE=v3`); with it, v3 proofs that use `expect.present/
> absent` (stdout text) PASS, but proofs using `log_checks` FAIL because
> `inspect-session.sh` can't parse v3's session store (SQLite `conversations_v2` +
> changed `sessions/` layout). Stream-json event grading (this ticket) removes the
> session-log dependency entirely and is the fix. Two concrete facts for the
> implementer (verified on 2.27.0, see `tools/proofs/docs/v3-engine-notes.md`):
> (1) terminal event is `runFinished`, final text at `.data.finalText` — NOT
> `.type=="result"`/`.result` as the draft below assumes (that was the Cursor/Claude
> schema guess; the real kiro schema is ACP v1). (2) **tool identity is `kind`/
> `title`, NOT `_meta.kiro.toolName`** (null in v3). Update the `events:` grading
> and the jq patterns below accordingly.

## Problem

`inspect-session.sh` has a race condition: it finds the session log via `find ~/.kiro/sessions/cli/ -name "*.jsonl" | xargs ls -t | head -1` — picking the most recent file by mtime. This can grab a judge session, concurrent proof, or user session instead of the trial under test. The `--session-id` flag exists but kiro-cli doesn't expose session IDs in stdout, so it's never populated.

## Solution

When the adapter supports `--output-format stream-json` (kiro-cli ≥ 2.19.2), capture the event stream directly from stdout. The stream IS the session — no file discovery, no race.

## What to build

1. **Adapter YAML extension** — add `output_format: stream-json` field to `adapters/kiro-cli.yaml`
2. **run.sh invoke path** — when adapter declares stream-json:
   - Capture stdout to `$workdir/events.jsonl`
   - Extract final text via `jq 'select(.type=="result") | .result'` for existing `expect.present/absent` grading
   - Skip `inspect-session.sh` entirely (events file replaces session log)
3. **New `events:` section in proof definitions** (additive):
   ```yaml
   events:
     present:
       - type: tool_call
         tool: read
         input_contains: "canary.md"
     absent:
       - type: tool_call
         tool: shell
     count:
       - type: tool_call
         min: 1
         max: 5
   ```
4. **grade_events() function** — parse events.jsonl with jq, evaluate event assertions
5. **Version gate** — check `kiro-cli --version` ≥ 2.19.2; older versions fall back to existing raw-text path
6. **Backwards compatibility** — `expect.present/absent` and `log_checks` unchanged; definitions can declare both

## Design constraints

- Additive, not replacing — codex/agy adapters don't support stream-json, keep existing paths
- `log_checks` remains as fallback — harness picks mechanism per adapter capability
- Event schema fields may vary from Cursor/Claude Code — depend on ticket 125's findings
- jq is already a harness dependency (used by eval scoring)

## Acceptance criteria

- [ ] `adapters/kiro-cli.yaml` declares `output_format: stream-json`
- [ ] `run.sh` captures events.jsonl when adapter supports stream-json
- [ ] Final text extracted from result event feeds into existing `expect.present/absent`
- [ ] `grade_events()` evaluates `events.present`, `events.absent`, `events.count`
- [ ] Existing proofs (A1-A5) pass with stream-json path (no regression)
- [ ] Version gate: graceful fallback when kiro-cli < 2.19.2
- [ ] `inspect-session.sh` race condition bypassed for stream-json-capable adapters
