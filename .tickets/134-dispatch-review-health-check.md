---
id: "134"
title: "matrix.sh --health preflight: live-probe each reviewer model before a run"
status: open
blocked_by: []
validation_criteria:
  - "a health command pings all dispatch_review models + codex, reports per-model up/down, catches authenticated-but-model-unavailable (the 131 failure mode) before token spend"
tags: ["kiro-v3"]
---

# matrix.sh --health preflight: live-probe each reviewer model before a run

## Intent source

Session review 2026-08-29: "do we have a health check to confirm all tools are
working?" Audit found tool *presence* is checked (doctor.sh) but no check confirms
the reviewer MODELS actually respond. The eval harness already has the right
pattern (`probe_tool`/`ensure_agent_probed` in `tools/evals/harness/run.sh` — a
live "Reply with exactly: OK" probe, added 2026-07-19 because "PATH presence !=
model access"). matrix.sh doesn't reuse it. The codex-131 blocker
(authenticated but no usable model) is exactly the failure this would catch — today
it only surfaces when a real review marks a model `indeterminate` after spending tokens.

## Context

- Models to probe: `dispatch_review.models` in `tools/proofs/adapters/opencode.yaml`
  (kimi-for-coding/k3, alibaba-token-plan/qwen3.8-max, zai-coding-plan/glm-5.3),
  plus the codex default reviewer.
- Reuse the eval `probe_tool` contract: trivial bounded prompt, validate by OUTPUT
  content (not exit code — opencode/codex both exit unreliably), classify quota/auth
  errors via `coding-plan-limits`.
- Windows: bound each probe with Start-Job + Wait-Job -Timeout (project-conventions
  references/windows.md); run under Git Bash.

## What to build

`tools/review/matrix.sh --health` (or a sibling `tools/review/health.sh`):
1. For each model in `dispatch_review.models` (+ codex): send `Reply with exactly: OK`
   via the same invocation the real run uses (`opencode run --auto -m <id> --format json`),
   bounded (~60s).
2. Validate the reply (step_finish reason:"stop" + non-empty text containing OK).
3. Classify failures: auth / model-unavailable / quota / timeout (per coding-plan-limits codes).
4. Emit a per-model ✅/❌ table + machine-readable JSON `{model, status, reason}`; exit
   0 all-healthy / 1 any-down / 2 usage.
5. Optionally auto-run at the start of a real matrix run (skip a down model as a
   reported coverage gap rather than discovering it mid-run).

## Acceptance criteria

- [ ] `matrix.sh --health` probes every dispatch_review model + codex, live
- [ ] Validates by output content, not exit code; bounded per probe (no hang)
- [ ] Detects authenticated-but-model-unavailable (the 131 case) and reports it distinctly from auth/quota/timeout
- [ ] Emits per-model ✅/❌ + JSON summary; exit 0/1/2
- [ ] Reuses the eval `probe_tool` contract + `coding-plan-limits` classification (no parallel mechanism)
- [ ] Documented in tools/review/README.md

## Out of scope

- Grading/review logic (that's the existing matrix run)
- Auto-remediation (just report; fixing codex env is ticket 131)

TBD

## Acceptance criteria

- [ ] TBD
