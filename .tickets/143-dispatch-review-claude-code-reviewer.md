---
id: "143"
title: "Add Claude Code as a dispatch-review reviewer (matrix leg when available)"
status: in_progress
blocked_by: []
validation_criteria:
  - "dispatch-review can dispatch a Claude Code reviewer that produces a contract-compliant REVIEW_RESULT run against the planted-review fixture, and the matrix includes a Claude leg when the claude CLI is on PATH"
tags: ["kiro-v3"]
---

# Add Claude Code as a dispatch-review reviewer (matrix leg when available)

## Intent source

Session review 2026-08-30, alongside ticket 142 (agy reviewer): dispatch-review
currently recognizes only **codex** and **opencode/<model>** reviewers. Claude Code
(`claude` CLI, headless mode) is a distinct model family (Anthropic) not represented
in the matrix. The skill's "family diversity is the lever" rationale — different
families catch different bug categories — makes a Claude leg valuable, especially
since much of crew-research's own tooling assumes Claude behavior (cross-model gap
noted in AGENTS.md: skills tested on Claude may behave differently on GPT-5.x/Gemini).

## Verified findings (2026-08-31) — L1, live-probed on this machine

Sibling 142 (agy reviewer) already landed the reusable seam in `matrix.sh`
(per-model tool resolution, tool-aware `invoke_reviewer`/`validate_stream`/
`extract_text`/`classify_error` wrappers, need-based PATH gate, CREW_ENV floor,
working-tree-centric prompt). 143 adds a third tool branch — small, mechanical.

1. **Invocation + auto-approve flag** (Claude Code 2.1.223):
   `claude --dangerously-skip-permissions --model <alias> --output-format json -p "<prompt>"`.
   `--dangerously-skip-permissions` = the bypass/auto-approve flag (codex/agy/opencode equivalent).
2. **Output contract — simpler than agy** (single JSON object, not NDJSON):
   `{type:"result", subtype:"success", is_error:bool, result:"<text>", stop_reason, num_turns, modelUsage}`.
   **Clean-stop = `type=="result" && is_error==false && subtype=="success"` + non-empty `result`.**
   Validate by content, NOT exit code (it exits 1 on the auth-error path).
3. **Models:** `opus` → `claude-opus-5`, `sonnet` → `claude-sonnet-5` (both live-verified).
   Pin **`opus`** as the review-grade default — the high-recall accuracy anchor
   (SWE-bench 80–88%) complementing Gemini Pro's high-SNR/lower-recall voice.
4. **UNRESTRICTED — no CREW_ENV policy gate.** Unlike agy (corp-forbidden per ticket
   36), Claude Code is allowed in all environments. The claude leg is PATH-gated only.
5. **Auth:** Claude subscription OAuth. An expired session surfaces as
   `is_error:true, result:"Failed to authenticate: OAuth session expired…"`, exit 1
   (was blocking; re-authed 2026-08-31, now `is_error:false`). Classify auth/api_error
   via `coding-plan-limits` (Claude carries `is_error` + `result` msg + `api_error_status`).

## What to build

1. `tools/proofs/adapters/claude-code.yaml` (exists) — add a `dispatch_review` block:
   invocation (`--output-format json -p`), roster default `opus`, `is_error==false` contract.
2. `matrix.sh` — add `claude` branches: `resolve_entry` (`claude:` prefix + roster),
   `invoke_reviewer`, `validate_claude` (`is_error==false`), `extract_text` (`.result`),
   `classify_error` (auth/api_error), `NEED_CLAUDE` PATH gate. **No policy gate.**
3. `matrix.sh --health` — Claude probe leg via `validate_claude`.
4. Skill docs — Reviewers row, result-contract fallback, model-matrix Claude leg +
   json-parsing recipe, activation keywords.
5. Live regression against `tools/review/fixtures/planted-review/`.

## Acceptance criteria

- [ ] `claude-code.yaml` has a dispatch_review block (invocation + `is_error==false` validation + opus roster)
- [ ] dispatch-review § Reviewers lists Claude with `claude --dangerously-skip-permissions … --output-format json -p`
- [ ] Claude appears as a matrix leg when `claude` is on PATH; absent → skipped as a reported coverage gap, never a hard failure; NOT policy-gated (unrestricted in all CREW_ENVs)
- [ ] `matrix.sh --health` probes the Claude leg (validate by `is_error==false`, classify auth/quota/timeout)
- [ ] Live regression against planted-review fixture: Claude opus produces a contract-compliant REVIEW_RESULT line (with `reviewer:"..."`) + inline findings covering the planted bugs. (Aggregate-ticket creation is the parent's fan-in step, not matrix.sh's.)

## Relationship to other tickets

- Sibling: **142** (same work for agy/Gemini).
- **Superseded-by 144** (per-job harness enable/disable config): if 144 lands a
  general reviewer/harness registry with per-job toggles, Claude becomes a registry
  entry rather than a hard-coded leg. Build the adapter here so 144 can absorb it
  (declarative entry, not bespoke branching).

## Out of scope

- Confirming/triaging the findings Claude produces (that's `review-new-work` + frontier consumption)
- The general per-job harness toggle framework (ticket 144)
