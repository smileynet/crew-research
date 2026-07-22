---
created_at: 2026-07-22T18:33:00+00:00
base_commit: f71bdeb
handoff_key: tkt-rollout
---

# Handoff

## Objective
tkt workstream COMPLETE — 44 (black-box layer), 45 (hardening), 41 (rollout) all done 2026-07-22. Next: general frontier (`tkt ready`); 27 proposed and accepted in principle, not yet claimed.

## Constraints
- CREW_ENV=corp (deploys = kiro-cli + codex, no agy)
- `tkt` now on PATH (editable install) — use it directly; `tk` is UNRELATED, never use
- Eval tickets (27/28) involve background runs — eval-execution steering rules apply (setsid, artifact-based liveness)

## Prior Decisions
- Id architecture (ticket 41 research, recorded in `.memory/specs/ticket-cli-spec.md` Decision record): sequential ids KEPT; hash ids + dual-id REJECTED with revisit triggers; `external:` typed-ref field reserved for GitHub correlation (alignment impossible by construction); distribution = documented editable install, NOT tier extension
- Push rejection is NOT a sufficient claim CAS — byte-identical-SHA hole found in 45; two-layer defense (pre-flight fetch + push-CAS backstop) is load-bearing. Gotcha promoted to global environment-gotchas
- Multi-file tool commits sanctioned (pattern surgical-git-side-effects scope extension): explicit paths + staged-set verification
- Batch create (R13) spun to ticket 46 — group-renumber loop nontrivial; repeated `tkt new` acceptable
- Guidance-sync ×2 applied: Design Gate "research before recommending" rule (AGENTS.md), fixture-vocabulary grep note (archwright steering), `mise run check:design`, birth-window glossary term

## Current State
Clean boundary — tree clean, all pushed (crew f71bdeb; archwright 9baad02). Nothing mid-flight. docs/plan.md authoritative for ticket status; `tkt sync-plan --check` clean. Tier redeployed to both tools this session (frontier-work tkt-first steering live). Suite: 45 passed; archwright-check 12/12.

## Next Steps
1. Ticket 27 (activation-git-protocol negative-task FPR flake) — proposed as next; read ticket 24's run evidence + the two flaking negative task definitions first
2. Ticket 23 measurement window opens ~2026-07-25 (`mise run session:skills 7` vs 78/271 baseline)
3. Archwright session: adoption prompt handed to operator for archwright#042 (tkt on PATH, validate:tickets task exists at f69f23d, R11/R12 reflections may be obsolete)
4. Windows session catch-up: `git pull` + tier redeploy + optionally `uv tool install -e ./tools/tkt`

## Fog
- Ticket 27 root cause unknown until task definitions are read: reword tasks vs FPR-gate flake allowance — don't pre-commit
- `external:` field interpretation (GitHub sync) deliberately unbuilt — future ticket when a bridge is a real need; one-way local-authoritative when built

## Recommended Updates
- [ ] Delete `.scratch/archwright-digest-tkt.md` on next cleanup (carried from 07-21; design/ holds the durable record)
- [ ] `.scratch/research/*.md` (11 files) are gitignored spike corpus cited by spec/patterns with "regenerate if pruned" — deliberate, keep until a cleanup pass questions them

## Evidence
- Tickets 41/44/45 Resolutions carry full AC evidence; plan rows current (sync-plan pass)
- tkt: `tools/tkt/` — 45 tests; new commands edit/renumber/sync-plan; contract `design/specs/cli-outputs.yaml` (+PlanFinding leg)
- Tried & failed this session: hash-id migration (endorsed then rejected — GitHub alignment impossible, our contention profile doesn't warrant it); title escaping (rejected for round-trip honesty — raw-text engine never interprets escapes)
- sync-plan caught real drift (row 45) on first production run — R9's reason-to-exist demonstrated
