---
name: subagent-reliability
description: Subagent dispatch reliability patterns. Expect failures, design around prompt size limits, use write-then-read for synthesis tasks.
metadata:
  type: reference
  invocation: agent-only
  practice: null
  tools: [kiro-cli, codex]
---

# Subagent Reliability

Subagent calls are unreliable. Expect failures and design around them.

## Failure Modes (observed)

| Mode | Symptom | Frequency |
|------|---------|-----------|
| Empty response | Stage completes but returns no content | Common (~50%) |
| Timeout | ConnectorError / Connection timed out | Occasional |
| Partial response | Starts output then cuts off | Rare |
| Silent success | Returns but missed key content (no way to detect) | Unknown |

**Root cause (validated):** failures correlate with **prompt size**, not task complexity. Dispatch prompts under ~1K tokens with work happening via tool calls succeed (~93%); prompts with 5-10K+ tokens of inlined data fail (~90%).

## The Core Rule: Write-Then-Read

Never put large data inline in a subagent prompt. If the subagent needs data that's in your context:

1. Write it to a temp file: `.scratch/subagent-input/{stage-name}.md`
2. Dispatch with: "Read `.scratch/subagent-input/{stage-name}.md` and [task]"

Similarly, preserve subagent output for later phases: save raw results to `.scratch/subagent-raw/` and have later phases read the files rather than re-dispatching.

## Rules

1. **Never silently absorb a failure.** When a stage returns empty or errors, report it immediately ("[N] of [M] stages failed"), state what coverage was lost, and recommend remediation (retry, read directly, or skip with documented gap). Do NOT quietly fall back to reading everything in main context.
2. **Design for partial failure.** Keep stages small (one logical unit each), idempotent (retry produces same output), and tracked ("5/11 succeeded, 6/11 need retry").
3. **Retry before fallback.** First retry: re-dispatch failed stages only. Second retry: split large stages further. Only after 2 retries, read directly in main context — and say so.
4. **Validate output.** Non-empty ≠ complete. Check: covers all files in the prompt? Expected structure? Volume proportional to input? Flag thin output explicitly.
5. **Report coverage gaps in deliverables.** The final artifact declares its own completeness: ✅ fully extracted / ⚠️ partial / ❌ not extracted, per area.

## Anti-Patterns

- **Cowboy fallback:** fail → silently read everything → present as if systematic extraction occurred
- **Quiet partial coverage:** 5/11 areas extracted → proceed as if all 11 covered
- **Retry storm:** same oversized prompt 5 times — two failures with the same shape means the shape is wrong
- **Context exhaustion:** reading 100+ files directly after failure, degrading all subsequent work

## Sizing Guidance

| Corpus size | Strategy |
|-------------|----------|
| 1-5 files, < 500 lines total | Read directly. NEVER subagent. |
| 6-15 files | One subagent per logical group |
| 16-50 files | Multiple stages, 5-8 files each |
| 50+ files | Multiple stages + structured output format + validation |
| Data already in context | Do directly. NEVER re-dispatch. |

## Task Shape (what to subagent vs do directly)

| Task type | Subagent? | Why |
|-----------|-----------|-----|
| Read files → extract structured data | ✅ Yes | Small prompt + tool-mediated work |
| Transform provided text → new structure | ❌ No | Violates the core rule (inline data) |
| Cross-area dedup/merge | ❌ No | Requires seeing all areas together |
| Validate/check existing output | ⚠️ Maybe | Only if the data is in FILES, not inline |
| Multi-step reasoning | ❌ No | Better sequential in main context |
| Research (web search + synthesis) | ⚠️ Unreliable | ~40% success rate; have a fallback plan |

## Batching Strategy

Batches sized by the tool's concurrency limit ([references/tool-limitations.md](references/tool-limitations.md)); each batch completes and is validated before the next starts. Order by dependency: independent stages first.

If 2+ stages in a batch fail or return empty: STOP dispatching, report "N/M stages returned empty, switching strategy", then read directly (remaining corpus < 500 lines) or use write-then-read with smaller batches (2 stages at a time).
