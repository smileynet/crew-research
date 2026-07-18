---
created_at: 2026-07-18T14:05:00+00:00
base_commit: bea4bfd
handoff_key: post-baseline-frontier
---

# Handoff

## Objective
t09 baseline arc CLOSED (ticket 09 done, v0.2.0 released). Work the frontier: tickets 13 (architecture-deepening), 14 (feedback-loop pair), 15 (harness resume), 16 (steering references ADR), 19 (recall activation).

## Constraints
- No live eval runs — all edit freezes lifted
- Global `~/.kiro/skills/` prune is now manifest-based (`~/.kiro/.crew-skills`); archwright skills are symlinks and survive deploys
- `~/.kiro/steering/references/environment-gotchas.md` remains unmanaged/user-maintained — never prune references
- Ticket creation: `git fetch` + rescan before allocating IDs; push promptly (frontier-work Creating Tickets section)

## Prior Decisions
- Baseline record: `docs/development/eval-baseline-2026-07-17.md` — 26/35 judged (74.3%), 19/20 live activation; regression rule: any new failure outside the 8 known gaps
- steering-pointer-effectiveness triaged flaky (restraint-control ceiling), trials 3→5
- recall activation: description flatten RULED OUT (TPR 0/5 post-fix) — ticket 19 has 3 hypotheses; hypothesis 3 (recall-check steering owns trigger space) may argue for retiring the def
- known_gap frontmatter documents the 3 codex-family defs; immutable id: on all 111 defs
- v0.2.0 released 2026-07-18 (tag + GH release); release-protocol skill governs future cuts
- init.sh skill prune is manifest-based (ticket 20, incident-driven); archwright deploys symlinks (its commit 5d450bf)

## Current State
Tickets 01-12, 17, 18, 20 done. Frontier: 13, 14, 15, 16, 19. Plan: `docs/plan.md` (authoritative). Global deploy current (frontier-work guard, recall flatten, windows.md live in ~/.kiro).

## Next Steps
1. Ticket 13: architecture-deepening — description trigger vocabulary + rubber-stamp gate; verify with activation run + judged eval
2. Ticket 14: feedback-loop pair — read failing trial outputs in `results/2026-07-17T10-41-09Z/outputs/`, diagnose merge-dilution hypothesis first
3. Ticket 15: harness resume (retired-def exclusion already landed separately)
4. Ticket 16: steering-references ADR (options in ticket)
5. Ticket 19: recall activation hypotheses

## Fog
- Ticket 16's deployment decision deliberately open (ADR needed)
- Ticket 19 hypothesis 3 could flip the fix from skill-side to def-retirement + steering measurement

## Evidence
- Baseline: `docs/development/eval-baseline-2026-07-17.md` · judged `tools/evals/results/2026-07-17T10-41-09Z/` · activation `results/activation-2026-07-17T22-18-29Z/` + verify `activation-2026-07-18T13-30-42Z/`
- Tried & failed: recall description flatten (folded-scalar hypothesis dead); tier-based skill prune (ate 13 archwright skills — manifest fix in bea4bfd)
