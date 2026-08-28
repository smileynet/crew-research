---
created_at: 2026-08-28T12:37:38-07:00
base_commit: 25f28f1
handoff_key: dispatch-review-kiro-v3
---

# Handoff

## Objective
Deliver + validate a multi-model independent code-review capability (generalized from
Codex-only `dispatch-codex-review`). Spawned from a kiro-cli 2.19.2 feature review.

## Constraints
- Reviewer permissions: **yolo is the default in all cases** (opencode `--auto`, codex
  `--dangerously-bypass-approvals-and-sandbox`); contained by throwaway git-worktree isolation.
  Scoping is opt-in hardening (ticket 128), not now.
- opencode is native-Windows: run matrix.sh under **Git Bash, not WSL**. Bound hang-prone
  CLIs with `Start-Job`+`Wait-Job -Timeout`. Validate by output content, never exit code.
- kiro-cli v3 CANNOT run headless (hangs) — pin `--agent-engine v2` for scripted work.

## Prior Decisions
- Parent-aggregates fan-in (single-writer ticket) over per-model tickets — avoids ID race.
- Grade with a multi-JUDGE panel (agents grade, not a deterministic matcher, not self-grade).
- Dedup findings on location+fault; category is advisory, never a match gate.
- Two-layer provenance: `Reporter: aggregate(...)` + per-finding `Reviewers:`/`Agreement:`.

## Current State
Ticket status lives in the plan/tkt (123/127/130 done; 124/125/132 open; 126/128/129/131/133
backlog; tkt#161 cross-repo). Not in a file yet: nothing — this session's work is all
committed through 25f28f1. The 3 target models (kimi-for-coding/k3, alibaba-token-plan/
qwen3.8-max, zai-coding-plan/glm-5.3) are live-authed and validated end-to-end.

## Next Steps
- Decide scratch cleanup (134 gitignored files under .scratch/research|review — findings
  distilled to tickets; safe to delete, awaiting user call).
- Decide docs/plan.md drift (stale "Deep Dive Review" plan, 34-line drift, kiro-v3 not in it).
- Frontier: 125 (write stream-json-schema.md + test 5), 132 (image-handling steering), 124 (blocked by 125).

## Fog
- Codex reviewer path (ticket 131): env-blocked — codex 0.147.0 can't serve a usable model
  (gpt-5.6-sol needs newer CLI; gpt-5.1-codex rejected on ChatGPT auth). Phase 3 regression
  incomplete until resolved; can't yet confirm the codex leg live.
- Cross-model skill activation is unreliable (only GLM read review-new-work; Kimi/Qwen didn't)
  — neutralized by the inline findings-only contract, but not a solved problem.

## Evidence
- Validated run: `.scratch/review/t130-p4/` (3-model matrix + aggregate-ticket.md + judge-*.out).
- 3-judge unanimous: recall 10/10, precision 10/12, FDR 0/12 (ticket 130 Phase 6 body).
- Fixture: `tools/review/fixtures/planted-review/` (10 planted bugs, manifest.yaml).
- Runner: `tools/review/matrix.sh` + README; skill: `atomics/skills/dispatch-review/`.

## Recommended Updates
- [ ] Decide + execute .scratch cleanup (project-cleanup Phase 2 deferred to user).
- [ ] docs/plan.md: reconcile/supersede the stale Deep Dive Review plan (systemic drift).
- [ ] ticket 133: CONTEXT.md trim + AGENTS.md over-budget (197>150) restructure.
