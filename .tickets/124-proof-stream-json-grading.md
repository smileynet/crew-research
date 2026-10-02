---
id: "124"
title: "Add stream-json event grading to proof harness"
status: done
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

- [x] `adapters/kiro-cli.yaml` declares `output_format: stream-json` (opt-in; `PROOF_OUTPUT_FORMAT` override)
- [x] `run.sh` captures events.jsonl when adapter supports stream-json (stdout separate from stderr)
- [x] Final text extracted from `runFinished.data.finalText` feeds into existing `expect.present/absent`
- [x] `grade_events()` evaluates `events.present`, `events.absent`, `events.count` (by `kind`/`title`)
- [x] Existing proofs pass with stream-json path (A4 v2+stream-json: deterministic PASS 3/3; log_check graded from events)
- [x] Version gate: graceful fallback when kiro-cli < 2.19.2
- [x] `inspect-session.sh` race condition bypassed for stream-json-capable adapters

## Outcome (2026-10-02)

Implemented + verified. The stream-json path grades `log_checks` (file_read/no_file_read/
tool_used/no_tool_used/context_contains/context_absent) and a new `events:` section from
the trial's own stdout event stream — **no `inspect-session.sh`, no mtime race, v3-safe**.
Decisive evidence: A4 with `PROOF_OUTPUT_FORMAT=stream-json` passed **3/3 deterministically**,
while the legacy session-log path is flaky on a busy host (the exact race this ticket
removes). Legacy path unchanged (wrapped in an else-branch; opt-in, default off).

jq idiom gotcha fixed: `any(inputs; …)` requires `jq -n`; used slurp (`-es 'any(.[]; …)'`)
and `-s '[.[]|select]|length'` instead. Tool identity graded on `kind`/`title`
(spike 168: `_meta.kiro.toolName` is null on v3). Schema ref: tools/proofs/docs/stream-json-schema.md.

**Out of scope, filed as ticket 170:** agent-based proofs (A4/A5) fail their *text*
grading on `--agent-engine v3` because v3 won't load v2-format agent-config `resources`
(falls back to default agent, "needs upgrading"). That's an agent-config format gap, not
a grading issue — stream-json grading itself works on both engines.

## Resolution (2026-10-02)

Added opt-in stream-json event grading to the proof harness. When invoke.output_format=stream-json (or PROOF_OUTPUT_FORMAT=stream-json) on kiro-cli>=2.19.2, the harness captures the trial's ACP event stream to events.jsonl and grades expect.present/absent (from runFinished.data.finalText), log_checks (file_read/tool_used/context_contains/etc via kind/title), and a new events: section (present/absent/count) directly from it — bypassing inspect-session.sh and its most-recent-by-mtime race, and working on v3 where inspect-session.sh cannot parse the session store. Legacy text+inspect-session path retained as default (no regression). Deterministic: A4 v2+stream-json passed 3/3 vs flaky legacy. Discovered + filed 170: v3 ignores v2-format agent-config resources (agent-config gap, separate from grading).
