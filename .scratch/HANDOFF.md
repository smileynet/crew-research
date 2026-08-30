---
created_at: 2026-08-29T22:24:00-07:00
base_commit: d70b4b6
handoff_key: dispatch-review-kiro-v3
---

# Handoff

## Objective
Multi-model independent code review (dispatch-review), from a kiro-cli 2.19.2 feature review.
Capability is BUILT, VALIDATED, and now DEPLOYED. Remaining = follow-up hardening + doc edits.

## Constraints
- Reviewer permissions: **yolo is the default in all cases** (opencode `--auto`, codex
  `--dangerously-bypass-approvals-and-sandbox`); contained by throwaway git-worktree isolation.
- Run matrix.sh under **Git Bash, not WSL** (opencode is native-Windows). Bound hang-prone CLIs
  with `Start-Job`+`Wait-Job -Timeout`. Validate by output content, never exit code.
- kiro-cli v3 CANNOT run headless (hangs) — pin `--agent-engine v2` for scripted work.
- **Committing skill/steering source ≠ deploying it** — run `init.sh` + doctor after skill work.

## Prior Decisions (durable — also in recall/decisions)
- Parent-aggregates single-writer fan-in over per-model tickets (ID-race).
- Multi-JUDGE panel grades (agents grade, not a matcher, not self-grade).
- Dedup findings on location+fault; category advisory. Two-layer provenance.

## Current State
Status lives in docs/plan.md (new "kiro-v3 / dispatch-review workstream" section, tickets 123-135)
and tkt. This session-arc: deployed the skill (pruned old dispatch-codex-review), built+closed 134
(`matrix.sh --health` readiness preflight), reconciled the plan (`sync-plan --fix` cleared 9 status
drifts + added the kiro-v3 section). Nothing half-done in-head — all committed at d70b4b6.

## Next Steps
- Frontier (open): 125 (write stream-json-schema.md + test-5), 132 (image-handling steering edits),
  124 (blocked_by 125). Backlog: 128/129/131/133/135, 126.
- Two USER DECISIONS still pending: (1) scratch cleanup — ~141 gitignored files in .scratch/research|review,
  findings distilled to tickets, safe to delete (irreversible); (2) 17 pre-existing missing-plan-rows
  (old spikes 69,92-122 — not this workstream's; adopt or accept as backlog-not-in-plan).

## Fog
- Codex reviewer leg (131): env-blocked — codex 0.147.0 can't serve a usable model
  (gpt-5.6-sol needs newer CLI; gpt-5.1-codex rejected on ChatGPT auth). Can't confirm codex leg live.
- `--health` failure taxonomy (135): only 1 of 5 reason-classes (`server_error`) verified live;
  model_unavailable/auth/quota/empty_or_timeout are regex-only, unproven.
- Cross-model skill activation unreliable (only GLM read review-new-work) — neutralized by the
  inline findings-only prompt, not solved.

## Evidence
- Validated matrix run: `.scratch/review/t130-p4/` (3-model + aggregate-ticket.md + judge-*.out).
- 3-judge unanimous: recall 10/10, precision 10/12, FDR 0/12 (ticket 130 Phase 6).
- Health: `matrix.sh --health` → 3/3 healthy exit 0; bogus → server_error exit 1.
- Code: `tools/review/matrix.sh` (+ `--health`), `tools/review/fixtures/planted-review/`,
  `atomics/skills/dispatch-review/`, `atomics/skills/coding-plan-limits/`.

## Recommended Updates
- [ ] Decide + execute .scratch cleanup (deferred twice).
- [ ] Verify --health failure taxonomy or label best-effort (ticket 135).
- [ ] Resolve 17 pre-existing missing-plan-rows (spikes) — separate /plan-ticket-sync pass.
