---
id: "142"
title: "Add agy/Gemini as a dispatch-review reviewer (matrix leg when available)"
status: open
blocked_by: []
validation_criteria:
  - "dispatch-review can dispatch an agy (Google Antigravity CLI) reviewer that produces a contract-compliant REVIEW_RESULT run against the planted-review fixture, and the matrix includes an agy/Gemini leg when agy is on PATH"
tags: ["kiro-v3"]
---

# Add agy/Gemini as a dispatch-review reviewer (matrix leg when available)

## Intent source

Session review 2026-08-30: "Does the dispatch review skill include agy (when
available)?" Audit of `atomics/skills/dispatch-review/SKILL.md` +
`references/model-matrix.md` found it supports exactly two reviewers — **codex**
(default) and **opencode/<provider>/<model>** (single or matrix). agy (Google
Antigravity CLI) is deployed as a full tool on personal machines but is NOT a
recognized reviewer, even when installed. The skill's own rationale —
"family diversity is the lever" (a model tends to miss the bug categories it
itself would introduce) — argues for a Gemini-family leg alongside the Kimi/Qwen/GLM
matrix.

## Context

- Reviewer table lives in `atomics/skills/dispatch-review/SKILL.md` (§ Reviewers):
  codex = `codex exec --dangerously-bypass-approvals-and-sandbox`; opencode =
  `opencode run --auto -m <id>`. Both require the sandbox/permission bypass or the
  reviewer's gate blocks subprocess execution + git push (false results).
- Matrix roster: `tools/proofs/adapters/opencode.yaml` → `dispatch_review.models`.
  An agy leg needs the analogous non-interactive, auto-approve invocation for agy.
- The result contract (`references/result-contract.md`) and fail-closed verify loop
  are reviewer-agnostic by design — the coordinator owns the gate; a new reviewer
  only has to emit the `REVIEW_RESULT ` line and push the aggregate ticket.
- agy binary present on this machine: `/home/sam/.local/bin/agy`.
- The `matrix.sh --health` preflight (ticket 134) must learn to probe the agy leg too.

## Unknowns to resolve first

1. agy's non-interactive invocation + the auto-approve/sandbox-bypass flag
   (equivalent of codex `--dangerously-bypass-approvals-and-sandbox` / opencode
   `--auto`). Without it the reviewer can't run tests/linters or push.
2. agy headless output contract — how to validate by OUTPUT content (not exit code),
   mirroring the opencode `step_finish reason:"stop"` + non-empty-text rule.
   (See eval-execution steering: kiro-cli/opencode/codex all exit unreliably.)
3. Quota/capacity behavior (fold into `coding-plan-limits` degrade-not-fail).

## What to build

1. Determine + document agy's headless auto-approve invocation and output contract.
2. Add agy to the § Reviewers table and (as a Gemini-family leg) to the matrix
   roster + `matrix.sh` fan-out, gated on `agy` present on PATH ("when available").
3. Extend `matrix.sh --health` to probe the agy leg (readiness, not liveness).
4. Regression: run the agy reviewer against `tools/review/fixtures/planted-review/`
   and confirm a contract-compliant findings run (real findings + REVIEW_RESULT,
   pushed aggregate ticket, correct provenance tag `Reviewer: agy/<model>`).

## Acceptance criteria

- [ ] agy's non-interactive auto-approve invocation + output-validation contract documented (in the skill or opencode.yaml-analogous adapter)
- [ ] dispatch-review § Reviewers lists agy with its invocation + required bypass flag
- [ ] agy appears as a matrix leg when `agy` is on PATH; absent → skipped as a reported coverage gap, never a hard failure
- [ ] `matrix.sh --health` probes the agy leg (validate by output content, classify auth/quota/timeout)
- [ ] Live regression against planted-review fixture: agy produces a contract-compliant REVIEW_RESULT + pushed aggregate ticket tagged `Reviewer: agy/<model>`

## Relationship to other tickets

- Sibling: **143** (same work for Claude Code).
- **Superseded-by 144** (per-job harness enable/disable config): if 144 lands a
  general reviewer/harness registry with per-job toggles, agy becomes a registry
  entry rather than a hard-coded leg. Coordinate — build the reviewer adapter here
  in a way 144 can absorb (declarative entry, not bespoke branching).

## Out of scope

- Confirming/triaging the findings agy produces (that's `review-new-work` + frontier consumption)
- The general per-job harness toggle framework (ticket 144)
