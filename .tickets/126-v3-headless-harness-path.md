---
id: "126"
title: "Add v3-engine invocation path to proof/eval harness when non-TUI v3 ships"
status: done
blocked_by: ["168"]
tags: ["kiro-v3"]
---

# Add v3-engine invocation path to proof/eval harness when non-TUI v3 ships

> **Trigger fired (2026-10-02):** the activation trigger below ("non-TUI/headless
> support for the v3 engine, OR v3 becomes default") has HAPPENED on kiro-cli
> 2.27.0 — v3 is now the default engine and runs headless (research in
> `.scratch/research/kiro-v3-2026-10/`). Moved off backlog → open. Re-gated from
> ticket 125 (v2 schema, done-enough) to **ticket 168** (the v3 headless probe that
> captures the actual v3 stream-json schema + trust behavior this ticket needs).
> Note the ticket-125 disruption analysis still stands: do NOT adopt a user-global
> `permissions.yaml` allow-all for CI (weakens interactive trust) — use a
> workspace-scoped `KIRO_HOME`/permissions or session-scope trust flags.

## Context (CORRECTED by spike 168, 2026-10-02)

Ticket 125 (kiro-cli 2.19.2) concluded the v3 engine couldn't run headless. **Spike
168 falsified this on 2.27.0** (`tools/proofs/docs/v3-engine-notes.md`):

- `--agent-engine v3 --no-interactive` runs clean (`engine:"v3"`, exit 0).
- `--agent-engine v3 --trust-all-tools` AND `--trust-tools=read` **both work** — no
  hang, no #7398 prompt, **no permissions.yaml needed**. The 2.19.2 "v3 rejects -a"
  is gone.
- Default headless engine is **still v2** on 2.27.0 (no `chat.agentEngine` set) — so
  v3 is opt-in-per-invocation via `--agent-engine v3`.
- stream-json schema = **same ACP v1 wrapper** as v2 (`runStarted`/`sessionUpdate`/
  `runFinished`, `acpProtocolVersion:1`) + 3 new info subtypes (`session_info_update`,
  `available_commands_update`, `config_option_update`) that consumers must ignore.
- 🔴 **BREAKING for grading:** in v3 `_meta.kiro.toolName` is **null**; tool identity
  moved to `kind` (e.g. `"read"`) and `title` (`"Read File"`). Any v2 extraction on
  `_meta.kiro.toolName` returns null on v3.

So the original "needs a workspace-scoped permissions.yaml" plan is unnecessary —
the real work is (1) an adapter engine selector and (2) the tool-name field fix.

## What to build (CORRECTED)

- **Adapter engine selector** in `tools/proofs/adapters/kiro-cli.yaml`: an optional
  `invoke.engine` key (default empty = binary default v2; `v3` opt-in). The proof
  harness (`tools/proofs/harness/run.sh:72-73,299-312`) reads the adapter command
  verbatim today and must interpolate an `--agent-engine` flag when set — mirror the
  eval harness idiom already at `tools/evals/harness/run.sh:438-439`
  (`[[ -n "$ENGINE" ]] && engine_flag="--agent-engine $ENGINE"`).
- **Keep `-a` for v3** (168 proved it works) — no permissions.yaml, no KIRO_HOME trust
  fixture. v2 remains the default so existing proofs are unaffected.
- **Tool-name field fix** wherever grading reads the tool name from stream-json or
  session JSONL: use `kind`/`title`, not `_meta.kiro.toolName`. Affects
  `extract-session-summary.sh:49-73` (if run on v3) and ticket 124's planned
  `grade_events()`.
- **Verify no regression to v2 path** (default engine unchanged).

## Acceptance criteria

- [x] v3 non-TUI headless confirmed available in a kiro-cli release (2.27.0 — spike 168)
- [x] `adapters/kiro-cli.yaml` has an optional engine selector (default v2/binary, v3 opt-in)
- [x] proof `run.sh` interpolates `--agent-engine` when the adapter sets it (idiom from eval run.sh:438-439; also `PROOF_ENGINE=v3` override)
- [x] Tool-name extraction uses `kind`/`title` (not null `_meta.kiro.toolName`) for v3 compatibility (extract-session-summary.sh v3 branch)
- [x] v3 stream-json schema documented (tools/proofs/docs/v3-engine-notes.md)
- [x] v2 path unchanged (A4 proof passes on default engine; selector is opt-in, default unset)

## Outcome note (2026-10-02)

Engine selector works end-to-end: with `PROOF_ENGINE=v3`, proof A4's **text grading
passes** (agent runs on v3). The **`log_checks` stage fails on v3** because
`inspect-session.sh` can't parse v3's session store — this is **ticket 124's scope**
(stream-json event grading replaces session-log inspection). So: v3 proofs using
`expect.present/absent` work now; v3 proofs using `log_checks` wait on 124. Recorded
in `tools/proofs/docs/v3-engine-notes.md` → "Harness integration".

## Resolution (2026-10-02)

Added opt-in v3 engine selector to proof harness (adapters/kiro-cli.yaml invoke.engine, PROOF_ENGINE=v3 override, run.sh injects --agent-engine after 'kiro-cli chat'). Fixed v3 tool-name extraction in extract-session-summary.sh (kind/title fallback since _meta.kiro.toolName is null on v3). v2 remains default -> no regression (A4 passes). KNOWN LIMIT: v3 log_checks still fail because inspect-session.sh can't parse v3's session store; that's ticket 124's stream-json event grading (updated 124 with the exact v3 facts: runFinished/.data.finalText, kind/title). So v3 proofs using expect.present/absent work now; log_checks-based proofs stay on v2 until 124.
