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

## Context

- Reviewer table + fail-closed verify loop: `atomics/skills/dispatch-review/SKILL.md`.
  Contract is reviewer-agnostic — coordinator owns the gate; a reviewer only emits
  the `REVIEW_RESULT ` line and pushes the aggregate ticket.
- Matrix roster: `tools/proofs/adapters/opencode.yaml` → `dispatch_review.models`.
  A Claude leg needs its own headless invocation + auto-approve/bypass flag.
- Claude Code headless: `claude -p "<prompt>"` (print mode) with a permission mode
  that allows tool use without prompts (e.g. `--permission-mode` / `--dangerously-skip-permissions`).
  Confirm the exact flag + output-validation contract during the ticket.
- `matrix.sh --health` (ticket 134) must gain a Claude probe leg too.

## Unknowns to resolve first

1. Claude Code non-interactive invocation + the skip-permissions/auto-approve flag
   (equivalent of codex `--dangerously-bypass-approvals-and-sandbox` / opencode `--auto`)
   so the reviewer can run tests/linters and push.
2. Headless output contract — validate by OUTPUT content, not exit code
   (`--output-format stream-json` / json; confirm the clean-stop signal).
3. Auth surface (Claude subscription vs API key) + quota behavior → `coding-plan-limits`.

## What to build

1. Determine + document Claude Code's headless auto-approve invocation + output contract.
2. Add Claude to the § Reviewers table and as a matrix leg (roster + `matrix.sh`
   fan-out), gated on `claude` present on PATH ("when available").
3. Extend `matrix.sh --health` to probe the Claude leg (readiness, not liveness).
4. Regression: run the Claude reviewer against `tools/review/fixtures/planted-review/`
   and confirm a contract-compliant findings run (real findings + REVIEW_RESULT,
   pushed aggregate ticket, provenance tag `Reviewer: claude/<model>`).

## Acceptance criteria

- [ ] Claude Code non-interactive auto-approve invocation + output-validation contract documented
- [ ] dispatch-review § Reviewers lists Claude with its invocation + required permission flag
- [ ] Claude appears as a matrix leg when `claude` is on PATH; absent → skipped as a reported coverage gap, never a hard failure
- [ ] `matrix.sh --health` probes the Claude leg (validate by output content, classify auth/quota/timeout)
- [ ] Live regression against planted-review fixture: Claude produces a contract-compliant REVIEW_RESULT + pushed aggregate ticket tagged `Reviewer: claude/<model>`

## Relationship to other tickets

- Sibling: **142** (same work for agy/Gemini).
- **Superseded-by 144** (per-job harness enable/disable config): if 144 lands a
  general reviewer/harness registry with per-job toggles, Claude becomes a registry
  entry rather than a hard-coded leg. Build the adapter here so 144 can absorb it
  (declarative entry, not bespoke branching).

## Out of scope

- Confirming/triaging the findings Claude produces (that's `review-new-work` + frontier consumption)
- The general per-job harness toggle framework (ticket 144)
