---
id: "130"
title: "Live e2e validation of dispatch-review multi-model matrix + fan-in"
status: open
blocked_by: ["127"]
priority: high
---

# Live e2e validation of dispatch-review multi-model matrix + fan-in

## Context

Ticket 127 built the multi-model dispatch-review tooling but only verified it via
dry-run + a single-model Kimi smoke test (PONG). Two things were NEVER exercised
live:
- The matrix flow end-to-end against a real diff with all 3 models
- The fan-in (dedup / agreement tiering / aggregate ticket) — it's skill-guided
  guidance, not executed code, so its correctness rests on the method, untested

This ticket closes that gap with a real run against a known target.

## What to validate (live)

1. **Fan-out per model** — run `tools/review/matrix.sh --run-id <uuid> --target <sha>`
   against a real commit with actual findings (pick a diff with a known planted or
   real issue). Confirm each of kimi-for-coding/k3, alibaba-token-plan/qwen3.8-max,
   zai-coding-plan/glm-5.3:
   - produces a valid result (step_finish reason:"stop" + non-empty text + REVIEW_RESULT)
   - writes `.scratch/review/<RUN_ID>/<slug>.md`
   - loads the review-new-work skill (cross-model activation — untested for Kimi/Qwen/GLM)
   - emits findings as the structured JSON schema
2. **JSONL parsing on a TOOL-USING run** — the schema was only captured on a
   no-tool prompt. Confirm tool event types (file reads, etc.) don't break the
   `text`/`step_finish` extraction. Capture the actual tool-event shape.
3. **Quota/degradation path** — force or observe a quota/429 on one model; confirm
   it's classified indeterminate and the run continues with the others (coding-plan-limits).
4. **Fan-in (main context)** — dedup findings by (file,line,category) across the 3
   models, tier by agreement (Consensus/Majority/Individual), create ONE aggregate
   ticket via tkt new with two-layer provenance (Reporter: aggregate(...), per-finding
   Reviewers:/Agreement:). Confirm no ID race.
5. **Fail-closed verify** — confirm an indeterminate/missing reviewer is reported as
   a coverage gap, never "clean".
6. **Codex path regression** — run dispatch-review with the default (codex) reviewer;
   confirm byte-identical behavior to the pre-127 dispatch-codex-review.
7. **Cross-model skill activation** — measure whether Kimi/Qwen/GLM actually activate
   review-new-work from the prompt (127 flagged this as untested; mitigated by
   indeterminate→deny but worth knowing).

## Deliverables

- A recorded run log + the generated aggregate ticket (or clean result) as evidence
- Notes on any gaps found (feed back into #128/#129 or new tickets)
- Confirmed tool-using JSONL event shape → update result-contract/model-matrix if it differs

## Acceptance criteria

- [ ] matrix.sh run against a real target with all 3 models; per-model artifacts + summary produced
- [ ] Each model's review-new-work activation observed (or non-activation documented)
- [ ] Tool-using run JSONL parsed correctly (tool event shape captured + documented)
- [ ] Quota/degradation on one model → indeterminate, run continues (observed or forced)
- [ ] Fan-in produces ONE aggregate ticket with two-layer provenance + agreement tiers, no ID race
- [ ] Fail-closed confirmed: indeterminate/missing reviewer reported as gap, not clean
- [ ] Codex default path regression-checked (unchanged behavior)
- [ ] Findings/gaps recorded; follow-up tickets filed for anything discovered
