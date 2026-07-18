---
id: "23"
title: "recall-check steering gate raises field compliance above 21%"
status: open
blocked_by: []
spec: "t09-baseline-followups"
---

# recall-check steering gate raises field compliance above 21%

## What to build

Strengthen the `recall-check` steering so agents actually run `recall search` before answering history questions, and stand up the steering-side field-compliance measurement that replaced the retired activation eval (ticket 19).

## Context

- **Evidence:** field compliance 21% (60/284 history-question sessions, `docs/development/session-skill-usage-2026-07-17.md`); t09 baseline rec #1
- **Ownership settled by ticket 19:** recall-check steering owns the memory-question trigger space (causally verified — the skill is structurally shadowed). Fixes go steering-side; `activation-recall` is retired.
- **Eval-proven pattern:** gates > suggestions (AGENTS.md) — the current steering says "run recall search BEFORE answering" but has no gate structure; compare verification-protocol's numbered gate workflow
- **Files:** `atomics/skills/recall-check/SKILL.md` (steering source), `tools/session-analyzer/` (compliance measurement), `docs/development/session-skill-usage-2026-07-17.md` (baseline method)
- **Measurement plan:** `mise run session:skills` classifies history-question sessions and checks for recall CLI invocation; re-run over a post-fix window and compare against the 21% baseline

## Acceptance criteria

- [x] recall-check steering restructured as a gate (mandatory check + explicit skip conditions), staying compact (it's always-on — every line costs) — 2026-07-18, 47-line SKILL.md: GATE header, 3-step workflow, skip conditions marked "the ONLY exemptions", violations section
- [x] Compliance measurement runs from a mise task and reports the history-question compliance rate with session counts — `mise run session:skills <days>` now emits `recall_check_compliance` with rate + baseline (detection regex unchanged for comparability)
- [ ] Post-fix compliance measured over ≥1 week of sessions and recorded; target >50% (2.4× baseline), threshold documented if adjusted
- [x] Global deploy updated — 2026-07-18, all three tools, idempotency verified (second run 0 updated, 0 pruned)

## Measurement window

- **Gate deployed:** 2026-07-18 — window opens here; measure no earlier than 2026-07-25 with `mise run session:skills 7`
- **Pre-fix reference:** 7-day window ending 2026-07-18 = 78/271 (29%); 30-day baseline = 60/284 (21%)
- Compare like windows (7d vs 7d) per session-analysis skill rules

## Out of scope

- Reviving the activation-recall def (retired with rationale, ticket 19)
- recall CLI changes
