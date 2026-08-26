---
id: "123"
title: "Review kiro-cli 2.19.2 features for project use"
status: open
blocked_by: []
spec: "Evaluate stream-json output and local image attachment for eval harness, proofs, and workflows"
priority: high
---

# Review kiro-cli 2.19.2 features for project use

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

**Phase 1: Proof Harness — Event-Level Assertions** (highest value, 2-3 hr)
- Add `output_format: stream-json` field to `adapters/kiro-cli.yaml`
- Modify `harness/run.sh` proof runner: when adapter declares stream-json, pipe output through `jq` to extract events
- New assertion types in proof definitions:
  - `event_present: {type: "tool_call", tool: "read"}` — did the agent call read?
  - `event_absent: {type: "tool_call", tool: "shell"}` — did it NOT call shell?
  - `event_count: {type: "tool_call", min: 1, max: 5}` — tool call budget
- **Eliminates** `inspect-session.sh`'s "most recent by mtime" race condition (the stream IS the session)
- Gate: `kiro-cli --version` ≥ 2.19.2; fall back to existing grep for older versions

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
