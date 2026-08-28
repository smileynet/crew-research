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

## Research-backed findings (2026-08-28, `.scratch/research/t130/`)

### Pre-validation fixes REQUIRED (matrix.sh bugs an e2e run will hit)

A code review of matrix.sh + the skill/contract found 3 blocking issues — fix these BEFORE the live run, or the first real run fails:

- **B1 (HIGH — contract contradiction):** matrix.sh's `REVIEW_PROMPT` says "Use review-new-work…" but review-new-work MANDATES creating+pushing an aggregate ticket, while matrix.sh's model is "reviewers emit inline findings, the PARENT creates the one ticket." The reviewer is told to do both → it may try to push a ticket (fails without git auth, burns the run) and omit the inline JSON the fan-in needs. **Fix:** give matrix.sh a findings-ONLY prompt that explicitly says "do NOT create a ticket; emit findings as JSONL + one REVIEW_RESULT line." Inline the minimal output contract (schema + example + closed enums) rather than relying on review-new-work activating (cross-model activation is unproven).
- **B3 (MEDIUM — extraction):** artifact writer does `[inputs|select(.type=="text")|.part.text]|join("")` (no separator) then `grep -m1 '^REVIEW_RESULT '` (first match). Risks welding the result line off line-start (false indeterminate) or catching an echoed example line. **Fix:** `join("\n")` + fence-tolerant last-match (`grep -Eo 'REVIEW_RESULT \{.*\}$' | tail -1`).
- **B9 (MEDIUM — isolation):** matrix.sh cd's into `--dir` (default repo root) and runs `opencode --auto` in the LIVE tree, not a mktemp workdir as the skill claims. Combined with B1, a ticket-creating reviewer leaves commits/dirty files. **Fix:** run each reviewer in a throwaway clone/workdir; `git status` check after.

Also fold in prompt hardening: closed severity/category enums (free-form breaks agreement tiering), inline example, anti-markdown-fence instruction, "emit all keys use null" (research review-prompt-quality.md).

### opencode tool-using JSONL schema — EMPIRICALLY CONFIRMED

Live capture (opencode 1.18.21, real `read`-tool run): tool runs add top-level `type:"tool_use"` (`part.type:"tool"`, with tool/callID/state{status,input,output}). Each tool call opens its own step → MULTIPLE step_finish events, the first `reason:"tool-calls"`, only the last `reason:"stop"`. **The t127 extraction (`last(... step_finish ...)` + `[text|join]`) STILL WORKS** — tool events filter out cleanly and `last()` correctly skips the "tool-calls" step_finish. ⚠️ New risk: `tool_use.part.state.output` carries FULL file content read → events.jsonl is as sensitive as the repo; extract only the REVIEW_RESULT line, don't ship/log raw JSONL.

### Fixture methodology (measure catch-rate honestly)

- Use a **planted-bug fixture** with a manifest (location, defect class, severity) + a small **real** hold-out. Synthetic-only massively overstates capability (research: synthetic F1 0.847 vs real 0.066).
- **Difficulty taxonomy** matters more than count: Type1_Direct (in diff), Type2_Contextual (same-file), Type3_Latent (cross-file). Type3 resists memorization.
- Measure **precision AND recall AND hallucination-rate** separately — catch-rate alone misleads. 3-way finding labels: CONFIRMED / PLAUSIBLE (not penalized) / FABRICATED.
- If the fixture yields 90%+ catch, it's too easy/memorized. Expect 15-47% honest recall from frontier tools.

## Execution sequence (de-risked ordering)

Live model calls are slow/non-deterministic/can hang → wrap every `opencode run` in `Start-Job`+`Wait-Job -Timeout` (proven this session), one model at a time, under Git Bash (not WSL).

| Phase | What | Why this order |
|-------|------|----------------|
| 0 | **Fix matrix.sh B1/B3/B9 + prompt hardening** | Blocking — the first real run fails without these |
| 1 | Build planted-bug fixture (Type1/2/3 mix, manifest) | Ground truth to measure against |
| 2 | Single-model real review (Kimi, cheapest) on the fixture | Prove full path before 3× token spend; capture tool-using JSONL |
| 3 | Codex-default regression check | Confirm old path unchanged before trusting matrix |
| 4 | Full 3-model matrix on the fixture | Fan-out + summary + per-model artifacts |
| 5 | Fan-in (main context): dedup/tier/aggregate ticket | Needs all 3 artifacts |
| 6 | Degradation (opportunistic — force/observe a 429) | Hardest to force; document code-verified if not live-observed |

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

- [ ] matrix.sh B1 fixed: findings-only prompt (no ticket creation), inline output contract with closed severity/category enums + example
- [ ] matrix.sh B3 fixed: text join with separator + fence-tolerant last-match REVIEW_RESULT extraction
- [ ] matrix.sh B9 fixed: reviewers run in throwaway workdir (not live tree); git status clean after
- [ ] events.jsonl sensitivity handled: only REVIEW_RESULT line surfaced, raw tool output not logged/shipped
- [ ] Planted-bug fixture built with manifest (Type1/2/3 mix, location/class/severity)
- [ ] matrix.sh run against the fixture with all 3 models; per-model artifacts + summary produced
- [ ] Each model's review-new-work activation observed (or non-activation documented)
- [ ] Tool-using run JSONL parsed correctly (confirmed: last() step_finish + text join works; verify on the real run)
- [ ] Quota/degradation on one model → indeterminate, run continues (observed or forced; document if code-verified only)
- [ ] Fan-in produces ONE aggregate ticket with two-layer provenance + agreement tiers, no ID race
- [ ] Recall/precision/hallucination measured against the fixture manifest (not catch-rate alone)
- [ ] Fail-closed confirmed: indeterminate/missing reviewer reported as gap, not clean
- [ ] Codex default path regression-checked (unchanged behavior)
- [ ] Findings/gaps recorded; follow-up tickets filed for anything discovered
