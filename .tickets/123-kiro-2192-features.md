---
id: "123"
title: "Review kiro-cli 2.19.2 features for project use"
status: done
blocked_by: []
spec: "Evaluate stream-json output and local image attachment for eval harness, proofs, and workflows"
priority: high
tags: [kiro-v3]
---

# Review kiro-cli 2.19.2 features for project use

> **Plan-sync note (2026-08-28):** the **stream-json half is DONE** — this review
> spawned tickets 124-131 and the feature was BUILT + LIVE-VALIDATED in 127 (done)
> and 130 (done): dispatch-review multi-model matrix, coding-plan-limits skill,
> opencode adapter, matrix.sh, judge-panel grading. The **image-attachment half was
> NOT acted on** — spun out to ticket 132 (update image-handling steering: remove
> the 5 "field-proven/workaround" caveats now that 2.19.2 makes local image
> attachment official). Once 132 is filed, this umbrella can close as "explored +
> decomposed." Keeping open only until 132 exists.

## New Features (kiro-cli 2.19.2)

### 1. `--output-format stream-json` (non-interactive mode)

Emits run events as JSON Lines on stdout. Requires v2 or v3 engine.

### 2. Image path attachment in local sessions

Image paths referenced in prompts now attach images locally (matching cloud behavior).

---

## Research-Backed Proposal

Research: `.scratch/research/t123/` (8 subagent reports, 2026-08-26).

### Stream-JSON: Expected Schema

Based on Cursor CLI and Claude Code (same lineage as kiro-cli), the event schema is a **discriminated union via `type` field** [L5:established — two independent sources agree]:

| Event type | Subtypes | Contains |
|------------|----------|----------|
| `system` | `init` | model, cwd, tools, session metadata |
| `assistant` | — | message content, model, usage stats |
| `tool_call` | `started`, `completed` | tool name, input, output, call_id |
| `user` | — | tool_result content blocks |
| `result` | `success` | duration_ms, num_turns, aggregated text |

**Terminal event:** `result` is always last. Absence = error (check stderr + exit code).
**Forward-compatible:** consumers MUST ignore unknown fields/types.

⚠️ No public docs exist for kiro-cli's specific schema — **empirical verification is prerequisite step 1.**

### Stream-JSON Integration: Impact Assessment

| System | Impact | Mechanism |
|--------|--------|-----------|
| **Proof harness** | 🔴 High | Replace grep-on-text + inspect-session.sh race condition with event-type assertions. Enables `event_present`, `event_absent`, `event_count` assertion types. |
| **Eval harness** | 🟠 Medium-High | Capture structured events alongside raw text. Feed tool_call counts + error events into behavioral scoring section. Judges still score text (backwards-compatible). |
| **Session analysis** | ⚪ None | Scripts parse historical interactive session logs (v2 JSONL). Stream-json is for live non-interactive runs only — different data source entirely. |

### Stream-JSON: Implementation Plan

**Phase 0: Schema Discovery** (prerequisite, 30 min)
```bash
kiro-cli chat --no-interactive --output-format stream-json --agent-engine v3 "Reply with exactly: OK"
```
Document actual event types, field names, and terminal behavior. Compare against Cursor/Claude Code schemas.

Questions to answer empirically:
1. Does `--output-format stream-json` suppress normal text? (output ONLY events, or interleaved?)
2. Exact `type` field vocabulary — matches Cursor (system/assistant/tool_call/result)?
3. Do tool_call events include full input/output or just metadata?
4. Is there a `context_loaded` event that replaces `context_contains` log_checks?
5. Works with `--agent` flag? (proofs use custom agents)
6. Does `--wrap never` conflict or get ignored with stream-json?
7. Does v2 engine default suffice, or must v3 be explicit?

**Phase 1: Proof Harness — Event-Level Assertions** (highest value, 2-3 hr)

The current proof system has a race condition: `inspect-session.sh` finds the session log via `find ... | xargs ls -t | head -1` (most recent by mtime). This can pick up a judge session, concurrent proof, or user session instead of the trial. Stream-json eliminates this — the event stream captured from stdout IS the session data.

Implementation:
- Add `output_format: stream-json` field to `adapters/kiro-cli.yaml`
- In `run.sh` invoke path: when adapter declares stream-json, capture events to `$workdir/events.jsonl`, extract final text via `jq 'select(.type=="result") | .result'` for existing `expect.present/absent` grading
- New `events:` section in proof definition YAML (additive, not replacing):
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
- Existing `expect.present/absent` unchanged (text from result event)
- Existing `log_checks` unchanged (fallback for codex/agy adapters without stream-json)
- Gate: `kiro-cli --version` ≥ 2.19.2; older versions use existing raw-text path
- Proof definitions can declare BOTH `log_checks` and `events:` — harness picks the appropriate mechanism per adapter

**Phase 2: Eval Harness — Dual Capture** (medium value, 1-2 hr)
- In `invoke_agent()`, when engine is v2/v3: add `--output-format stream-json`
- Capture events to `$workdir/events.jsonl`; extract final assistant text via `jq 'select(.type=="result") | .result'` for judge input
- Parse `tool_call` events → inject structured behavioral summary into judge's `{{BEHAVIORAL_SECTION}}` (replaces fragile `extract-session-summary.sh` grep heuristics)
- Keep raw text fallback for adapters that don't support stream-json (codex, crush, agy)

**Phase 3: Enhanced Scoring Metadata** (low effort addition to Phase 2)
- Extract from events: total tool calls, error count, duration_ms, token usage
- Write to `scores.jsonl` as additional fields (non-breaking schema addition)
- Enables trend analysis: "did this skill change make the agent more efficient?"

### Image Attachment: Impact Assessment

| System | Impact | Change needed |
|--------|--------|---------------|
| **image-handling steering** | 🟠 Medium | 5 text updates (remove field-proven caveats) |
| **multi-agent-validation skill** | 🟢 Low | Remove cloud-recommended hedge |
| **eval/proof harness** | ⚪ None | No visual tests currently; separate scope |

### Image Attachment: Updates Required

| # | File | Change | Priority |
|---|------|--------|----------|
| 1 | `image-handling.md` (steering) | Remove "NOT explicitly documented" / "field-proven, re-validate on major CLI upgrades" → "Officially supported since kiro-cli 2.19.2" | High |
| 2 | `image-handling.md` | Verify if `--trust-tools=read` still needed or if native attachment replaces it | Medium |
| 3 | `image-handling.md` limits table | Re-check kiro.dev docs for newly documented pixel/resize values | Medium |
| 4 | `references/tool-dispatch.md` | Reframe kiro-cli section: official support, fresh-session is for compaction only (model limit, not tool limit) | Low |
| 5 | `image-handling.md` frontmatter | Remove "workaround" framing from description | Low |

**Unchanged:** Token cost formula, sizing rule, practice notes, multi-tool dispatch logic, fallback section (all model-level, unaffected by CLI version).

### Execution Order

| Step | Effort | Prereqs | Value |
|------|--------|---------|-------|
| 0. Empirical schema discovery | 30 min | kiro-cli ≥ 2.19.2 | Unblocks all stream-json work |
| 1. Proof harness event assertions | 2-3 hr | Step 0 | Eliminates race conditions, enables structural proofs |
| 2. Eval harness dual capture | 1-2 hr | Step 0 | Better behavioral scoring, structured metadata |
| 3. Image steering updates | 30 min | Read 2.19.2 docs | Quick win, removes stale caveats |
| 4. Scoring metadata enrichment | 30 min | Step 2 | Trend analysis capability |

### Design Gate

- **Tension?** No — stream-json is additive (dual capture preserves backwards compatibility).
- **Durable invariants?** No — consumption is opportunistic with version-gated fallback.
- **Rejected alternatives?** No.

All NO → build directly.

### Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| kiro-cli schema differs from Cursor/Claude Code | Step 0 discovers actual schema; abstractions only after empirical data |
| Schema evolves in future versions | Ignore unknown fields; version-gate; keep raw text fallback |
| `--output-format` and `--wrap never` interact unexpectedly | Test both together in Step 0 |
| v2 engine required but harness defaults to v1? | Verify default; `--agent-engine` flag already exists in harness |

---

## Acceptance criteria

- [ ] Stream-json schema empirically documented (Step 0)
- [ ] Proof harness supports event-level assertions with version-gated fallback
- [ ] Eval harness captures structured events alongside raw text
- [ ] image-handling steering updated (5 items above)
- [ ] All changes gated on kiro-cli ≥ 2.19.2 (graceful fallback for older)

## Resolution (2026-08-28)

Umbrella review complete + decomposed. Stream-json feature fully realized: dispatch-review multi-model matrix (Kimi/Qwen/GLM), coding-plan-limits skill, opencode adapter, matrix.sh, live e2e judge-panel validation (130). Image-attachment feature spun out to ticket 132 (image-handling steering doc updates). Follow-ups: 124/125 (proof-harness stream-json, schema known), 126/128/129/131 (backlog), 132 (image), tkt#161 (frontier-work provenance).
