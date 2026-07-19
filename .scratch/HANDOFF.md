---
created_at: 2026-07-19T17:43:00+00:00
base_commit: 1d7ffae
handoff_key: post-baseline-frontier
---

# Handoff

## Objective
Work the frontier (see docs/plan.md ticket table): 29 is the dependency root (30/32/33 blocked on it; judge changes blocked on it per grill Q04). 27/28/31/36 are parallel-friendly. 23 reopens ~2026-07-25.

## Constraints
- **agy is FORBIDDEN on this machine (company policy)** — artifacts removed 2026-07-19; deploys here = `--tool kiro-cli --tool codex` ONLY; enforcement lands in ticket 36. `CREW_ENV=corp` in gitignored `.mise.local.toml`
- Eval-run liveness = artifacts (log growth, results-dir mtimes, `ps aux | grep "[r]un.sh"`), NEVER the setsid launcher PID (updated in eval-execution steering after near-double-launch)
- No live judge-set changes before ticket 29 (recording gap); consensus scores on this machine are ~2-judge medians (opus+codex) — don't compare across machines
- A kiro `run.sh --all` today blind-runs the 3 upstream image-* defs (no adapter scoping until 29) — avoid full suite runs or discount those rows
- Parallel sessions are ACTIVE on this repo (5 upstream rebases today): fetch+rescan before ticket allocation (36 is max); divergence default = rebase when possible (now in project-conventions)

## Prior Decisions
- Grill `ticket-open-questions` complete (Q1–Q5): access map + CREW_ENV; session-review = manual task first, daily-collect/weekly-synthesize pairing later, digest-only artifact; judge swap = <5% median-shift + ±0.1 bias cap, shadow→augment(post-29)→drop; G0 invocation-model gate added to skill-authoring. Files: `.memory/grill/ticket-open-questions/`
- crush on corp = Bedrock, Anthropic-only, caching disabled (crush docs; account pool verified — haiku-4.5 is the cheap-judge candidate)
- Eval results schema target (spec `.memory/specs/eval-harness.md` gaps table): rows get id/adapter/judges (29), re-judge + interchange (32), identity hashes + --changed-only (33)
- guidance-sync skill = manually-invoked in-session probe (`/guidance-sync`, user-only); first probe applied 3 fixes; automated variant = ticket 34
- New baseline 2026-07-19: 28/35 judged @ 28ed513, known gaps 8→5 (`docs/development/eval-baseline-2026-07-19.md`); +2 defs (mcp-partitioning) pass at birth

## Current State
Clean boundary — grill closed, tree clean, all pushed (1d7ffae). Nothing mid-flight. Ticket 29 proposed as next but NOT started; user hasn't confirmed.

## Next Steps
1. Ticket 29 (deferred eval protocol) — dependency root; schema decisions pre-made (grill pre-resolved table + Q04); include hash-field placeholders in the row schema so 33 doesn't churn it (recall note 2026-07-19)
2. Ticket 23 measurement ≥2026-07-25: `mise run session:skills 7` vs pre-fix 78/271 (29%)
3. Personal-env owed work when there: image-def birth runs (30), agy/GLM judge legs (35 shadow candidates)
4. Tickets 27/28/31/36 — small, parallel-friendly, env-appropriate

## Fog
- crush-Bedrock live behavior on corp unverified (ticket 31 probes; docs' Claude-only limit is as-of Mar 2026)
- Ticket 28: flaky vs genuine (incl. a03798e confound on handoff-decaying) unknown until solo re-runs
- Ticket 34/35 spike-gated: detection precision; direct-invoke Bedrock judge leg feasibility
- Personal-env specifics assumed (tool versions, kiro presence) — verify on first session there

## Recommended Updates
- [ ] user steering references/environment-gotchas.md (user-owned): add "setsid $! is the wrapper PID" + "kiro cancellation doesn't kill spawned processes" gotchas
- [ ] skill(tool-installation): 223 lines — split if it bothers anyone (carried from last handoff)

## Evidence
- Session commits: 6ec4890..1d7ffae (~14, all pushed); tickets 23–36 in `.tickets/`; grill: `.memory/grill/ticket-open-questions/`
- Runs: activation 19/20 `results/activation-2026-07-18T21-56-19Z`; judged 28/35 `results/2026-07-19T00-29-50Z`; mcp-partitioning `2026-07-19T13-32-32Z` + `activation-2026-07-19T13-13-30Z`
- Tried & failed: `kill -0 $!` liveness after setsid (misdiagnosed healthy 10h run — fixed in steering); attempt-1 log-missing mystery unexplained but harmless now; git-protocol FP forensics via session-DB marker grep WORKED (reusable method, see ticket 27)
