---
id: "142"
title: "Add agy/Gemini as a dispatch-review reviewer (matrix leg when available)"
status: done
blocked_by: []
validation_criteria:
  - "dispatch-review can dispatch an agy (Google Antigravity CLI) reviewer that produces a contract-compliant REVIEW_RESULT run against the planted-review fixture, and the matrix includes an agy/Gemini leg when agy is on PATH"
tags: ["kiro-v3"]
---

# Add agy/Gemini as a dispatch-review reviewer (matrix leg when available)

## Intent source

Session review 2026-08-30: "Does the dispatch review skill include agy (when
available)?" Audit found dispatch-review supports exactly two reviewers — **codex**
(default) and **opencode/<model>** (single or matrix). agy (Google Antigravity CLI)
is deployed as a full tool on personal machines but is NOT a recognized reviewer.
The skill's own rationale — "family diversity is the lever" — argues for a
Gemini-family leg alongside the Kimi/Qwen/GLM matrix.

## Verified findings (2026-08-30) — L1 unless noted

Research subagents (`.scratch/research/t142/`) + code-review subagents
(`.scratch/review/t142/`) + LIVE probing of the installed binary:

1. **agy headless works end-to-end — the stored blocker is STALE.** `agy.yaml`
   marks agy `eval_harness_status: blocked` on Issue #76 ("`--print` drops stdout
   in non-TTY", "no `--json`/`--output` flag exists"). All false on the installed
   build. Live test (`agy 1.1.22`, piped, stdin `</dev/null`, stdout→file):
   **2030 bytes stdout, 0 stderr, exit 0**, terminal
   `{"event":"result","result":{"status":"SUCCESS","response":"OK\n"}}`. Issue #76
   is fixed as of ≥1.1.22. → **Correcting `agy.yaml` is a prerequisite folded into
   this ticket.**
2. **Invocation + auto-approve flag:**
   `agy --dangerously-skip-permissions --model <id> --output-format stream-json --print="<prompt>"`.
   `--dangerously-skip-permissions` = the codex `--dangerously-bypass-approvals-and-sandbox`
   / opencode `--auto` equivalent (init event shows `permission_mode:"always-proceed"`).
3. **`--print` is a GREEDY value flag** — the prompt MUST be attached as
   `--print="<prompt>"` with `--dangerously-skip-permissions` elsewhere on the line,
   or agy swallows the flag as the prompt and errors. The stored adapter example
   (`--print "{query}" --dangerously-skip-permissions`) is the broken form.
4. **Validation predicate is agy-specific** (NOT opencode's `step_finish reason:"stop"`):
   terminal `event:"result"` + `result.status=="SUCCESS"` + non-empty `result.response`.
   Status enum: `SUCCESS|ERROR|CANCELED|INTERRUPTED|INVALID|WAITING|RUNNING`. Validate
   by OUTPUT content, never exit code (eval-execution steering). [research: agy-headless-docs, L4]
5. **Integration is CODE-BRANCHING, not config-only.** `matrix.sh` does NOT expand
   the adapter `command` template — it hard-codes the opencode invocation and reads
   only `dispatch_review.models[]` from a hard-coded `opencode.yaml` path. The roster
   is a flat model list with no "which tool hosts this model" field. Adding a
   `dispatch_review:` block to `agy.yaml` alone changes nothing. Real work: a
   tool-resolution seam + `invoke_agy`/`parse_agy` that NORMALIZE agy's `result`
   event into the shared JSONL contract so `validate_output` stays unchanged.
   [review: matrix-sh, adapter-config]
6. **matrix.sh has NO CREW_ENV policy check** (only init/run/run-proof/doctor carry
   `policy-blocked`). Harmless today (opencode models aren't gated) but an agy leg
   would RUN AGY ON CORP — breaking the ticket-36 floor + ticket-144 invariant. The
   agy leg must gate policy→PATH→probe at fan-out AND `--health`, using the judge-leg
   degrade-as-gap pattern (distinct reason `policy-blocked (CREW_ENV=corp)`), NOT
   init's hard-exit (a matrix has other legs). [review: env-policy-health]
7. **Model: pin `gemini-3.1-pro-high`.** All controlled review benchmarks test Pro,
   not Flash ("Flash for review" is unvalidated; Flash only wins on generation).
   Gemini Pro is the high-SNR/high-precision, lower-recall diversity voice (60.9%
   vs 65.2% coverage vs a Claude+GPT blend; SNR 3.5 vs 2.6), with a documented
   concurrency-race weakness and an overreach tic (labels minors "Critical"). A
   diversity voice, not a solo reviewer — which matches the matrix design.
   [research: gemini-as-reviewer, CodeRabbit Mar-2026 25-PR benchmark, L4]
8. **Aggregation guardrail (reinforce, don't rebuild):** cross-family diversity
   lifts detection, but consensus ≠ verification (80+ agents unanimously endorsed a
   nonexistent vuln). The skill already handles this (advisory-not-blocking, keep
   single-model findings low-confidence-labeled, tier by agreement). Adding a Gemini
   family leg strengthens de-correlation; do NOT add consensus-as-gate logic.
   [research: multimodel-review-priorart]

## What to build

1. **Fix `tools/proofs/adapters/agy.yaml`** — remove `eval_harness_status: blocked`
   + Issue-#76 blocker; add a `dispatch_review:` block (invocation in `--print=`
   form, roster default `gemini-3.1-pro-high`, `result.status` validation, timeout
   via `--print-timeout`). Note #76 fixed as of 1.1.22 (verified).
2. **Generalize `matrix.sh`** — tool-resolution seam; `invoke_agy`/`parse_agy`
   normalizing agy's `result` event into the shared contract so `validate_output`
   is unchanged; fix the `for tool in opencode yq jq` PATH gate so an agy-only run
   doesn't hard-fail on missing opencode. Keep MINIMAL (144 owns the general registry).
3. **CREW_ENV floor in matrix.sh** — policy→PATH→probe ordering at fan-out +
   `--health`; agy on corp = reported `policy-blocked` gap, distinct from
   unavailable/quota.
4. **`--health` agy probe** — cannot reuse `probe_model()` (opencode-coupled);
   validate via `result.status=="SUCCESS"` (stdout capture works on ≥1.1.22; keep
   the file-canary as a documented fallback for older builds).
5. **Skill doc edits** (additive; contract unchanged) — Reviewers-table row (agy
   invocation + bypass flag), a `# agy` line in `result-contract.md`, an agy
   terminal-signal recipe in `model-matrix.md`, extend frontmatter `description` for
   agy-review activation. Provenance tag `Reviewer: agy/gemini-3.1-pro-high`.
6. **Live regression** against `tools/review/fixtures/planted-review/` — contract-
   compliant `REVIEW_RESULT` + pushed aggregate ticket.

## Acceptance criteria

- [x] `agy.yaml` corrected (blocked status removed; dispatch_review block with `--print=` invocation + result.status validation added; #76-fixed noted)
- [x] dispatch-review § Reviewers lists agy with its invocation + `--dangerously-skip-permissions`
- [x] agy appears as a matrix leg when `agy` is on PATH; absent → skipped as a reported coverage gap, never a hard failure; opencode-only PATH gate no longer hard-fails an agy-only run
- [x] matrix.sh gates the agy leg by CREW_ENV policy (corp → `policy-blocked` gap, distinct reason) at fan-out AND `--health`, before `command -v agy`
- [x] `matrix.sh --health` probes the agy leg (validate by `result.status`, classify auth/quota/timeout)
- [x] Live regression against planted-review fixture: agy produces a contract-compliant REVIEW_RESULT line (with `reviewer:"gemini-31-pro-high"`) + inline findings covering the planted bugs. (Aggregate-ticket creation is the parent's fan-in step in main context, not matrix.sh's — see Out of scope / README "Fan-in is NOT here".)

## Relationship to other tickets

- Sibling: **143** (same work for Claude Code).
- **Superseded-by 144**: agy is built as a declarative adapter entry (agy.yaml
  dispatch_review block) so 144's shared reader can absorb it; the matrix.sh
  generalization stays minimal (a tool-resolution branch), leaving the general
  per-job registry to 144. The CREW_ENV floor added here is the hard floor 144
  layers under (distinct reasons: disabled / unavailable / policy-blocked).

## Out of scope

- Confirming/triaging the findings agy produces (that's `review-new-work` + frontier consumption)
- The general per-job harness toggle framework (ticket 144)
- The broader per-tool adapter-interface refactor (minimal branch here; 144 owns it)

## Resolution (2026-09-01)

Added agy/Gemini as a dispatch-review matrix leg. matrix.sh generalized with per-model tool resolution (opencode+agy), tool-aware invoke/validate/extract wrappers, need-based PATH gate, CREW_ENV policy floor (corp degrades agy as distinct policy-blocked gap) at fan-out and --health, and an agy --health probe validating via result.status. Corrected stale agy.yaml (Issue #76 fixed as of 1.1.22, verified live; dispatch_review block; --print= greedy-flag gotcha). Skill docs updated (Reviewers table, result-contract fallback, model-matrix Gemini leg + stream-json recipe, activation keywords). Kept minimal per ticket 144 supersession; matrix.sh stays fan-out only. Commit 9214578.

### Verification
1. ✓ dispatch-review can dispatch an agy (Google Antigravity CLI) reviewer that produces a contract-compliant REVIEW_RESULT run against the planted-review fixture, and the matrix includes an agy/Gemini leg when agy is on PATH — "Live regression on planted-review fixture: agy gemini-3.1-pro-high reviewed in 127s, result.status SUCCESS, matrix-summary status:pass produced 1/1; contract-compliant REVIEW_RESULT line (reviewer:gemini-31-pro-high); 11 findings matched all 10 planted bugs (B1-B10 incl Type-3 cross-file B2/TOCTOU B7/over-mock B9); 14x view_file zero filesystem-hunting. Matrix leg present when agy on PATH (personal dry-run: 3x[opencode]+1x[agy]); CREW_ENV=corp degrades agy as policy-blocked gap at fan-out AND --health (verified). shellcheck clean, mise run validate passes. Commit 9214578 on origin/main."
