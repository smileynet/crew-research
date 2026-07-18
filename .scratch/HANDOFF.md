---
created_at: 2026-07-18T14:40:00+00:00
base_commit: d02d080
handoff_key: post-baseline-frontier
---

# Handoff

## Objective
Baseline arc CLOSED (ticket 09 done, v0.2.0 released, deploy-safety hardened). Work the frontier: tickets 13 (architecture-deepening), 14 (feedback-loop pair), 15 (harness resume), 16 (steering-references ADR), 19 (recall activation).

## Constraints
- No live eval runs — all edit freezes lifted
- `~/.kiro/skills/` prune is manifest-based (`~/.kiro/.crew-skills`) + `compositions/deprecated.yaml` kill-list; symlinks always kept. Retiring a skill = delete + deprecated.yaml entry in the SAME commit (lint enforces no resurrection)
- archwright skills in `~/.kiro/skills/` are SYMLINKS to its repo (its deploy-skills.sh, commit 5d450bf) — do not convert to copies
- `~/.kiro/steering/references/environment-gotchas.md` is user-maintained — never prune references
- Ticket creation: `git fetch` + rescan before allocating IDs; push promptly (frontier-work § Creating Tickets)

## Prior Decisions
- Baseline: `docs/development/eval-baseline-2026-07-17.md` — 26/35 judged, 19/20 live activation @ 24d9691. Regression rule: any NEW failure outside the 8 known gaps
- recall activation: description flatten RULED OUT (TPR 0/5 after fix) — ticket 19's hypothesis 3 (recall-check steering owns the trigger space) may mean retiring the def instead
- steering-pointer-effectiveness = flaky (restraint-control task's baseline at ceiling); trials 3→5
- Eval defs carry immutable `id:` (longitudinal key) + optional `known_gap:` (3 codex-family defs)
- v0.2.0 released; release-protocol skill + `mise run release` govern cuts; [Unreleased] already has 2 entries toward v0.2.1/0.3.0
- Ticket 12/13 upstream ID collision renumbered to 17/18 (both since done)

## Current State
Clean boundary — nothing mid-flight. `docs/plan.md` is authoritative (01-12, 17, 18, 20, 21 done; frontier 13/14/15/16/19). Global deploy current incl. today's skill edits. Working tree clean, all pushed (crew-research d02d080, archwright 5d450bf).

## Next Steps
1. Ticket 13 (lowest frontier): rewrite architecture-deepening description with review/approval trigger vocabulary + add mandatory rubber-stamp rejection gate; verify via `run-activation.sh --definition activation-architecture-deepening` + judged eval; keep ≤100 lines
2. Ticket 14: read failing trial outputs (`tools/evals/results/2026-07-17T10-41-09Z/outputs/`, feedback-loop*), test merge-dilution hypothesis against pre-merge content (`git show 5cd6bb5^:atomics/skills/troubleshooting-protocol/SKILL.md`)
3. Ticket 15: harness resume (retired-def exclusion already landed in d02d080's parent)
4. Ticket 16: ADR for steering-reference deploy semantics (3 options in ticket)
5. Ticket 19: recall activation hypotheses (see Prior Decisions)

## Fog
- Ticket 16's decision deliberately open — needs the ADR, options a/b/c in ticket
- Ticket 19 h3 could flip fix from skill-side to def-retirement + field-compliance measurement (21% baseline, `session-skill-usage-2026-07-17.md`)

## Evidence
- Results: judged `tools/evals/results/2026-07-17T10-41-09Z/` · activation `activation-2026-07-17T22-18-29Z/` · recall verify `activation-2026-07-18T13-30-42Z/`
- Tried & failed: recall folded-scalar hypothesis (flatten changed nothing); tier-based skill prune (deleted 13 archwright skills — incident in ticket 20)
- /tmp logs deleted; numbers preserved in the baseline record
