---
created_at: 2026-07-19T21:12:30+00:00
base_commit: 072d64d
handoff_key: post-baseline-frontier
---

# Handoff

## Objective
Work the frontier (docs/plan.md ticket table). Ticket 38 (tk-like CLI explore) is the remaining user-flagged HIGH PRIORITY; 30/32/33 unblocked by 29 this session.

## Constraints
- agy FORBIDDEN on this machine (corp policy); deploys = `--tool kiro-cli --tool codex` only
- **Judge-set boundary 2026-07-19:** all results before commit 69547a8 are OPUS-ONLY single-judge (codex leg was silently dead — untrusted temp dir). Post-fix runs are kiro+codex consensus. Never compare scores across that boundary; next full run will move for judge reasons, not skill reasons
- Full `--all` runs now emit 3 SKIPs (image-* defs scoped to crush) — expected, not failures
- Parallel sessions ACTIVE (2 rebases today, incl. a 37↔39 ticket collision resolved by renumber): fetch+rescan before allocating; 39 is max

## Prior Decisions
- Ticket 29 landed: `adapters:` SKIP rows, live access probes (`EVAL_PROBE_TIMEOUT` 30s), per-trial judge recording, id/adapter row keys + null hash placeholders (33's seat), owed-run ledger `docs/development/deferred-runs.md`
- Ticket 37 landed: archwright = KNOWN TOOL not extension (self-deploys symlinks; crew never copies). Registry `compositions/known-tools.yaml`; doctor/catalog consume; 5 conditional seams (arch-deepening, sdd, planning-cycles, grill, adr). Half of ticket 30 pre-done (ids+adapters+ledger) — see its Context note
- `priority: high` frontmatter jumps frontier number order (in frontier-work skill now)
- Archwright ticket 037 created (its repo, NEXT UP in its PLAN.md): deploy-skills.sh must stop overwriting crew's subagent-reliability.md (crew's copy authoritative meanwhile)
- Guidance-sync applied: known-tool glossary term, deploy-toolkit doctor rows, 4 gotchas → user environment-gotchas.md (queue cleared)

## Current State
Clean boundary — tree clean, all pushed (crew 072d64d; archwright f5f57c1). Nothing mid-flight. Ticket 38 not started.

## Next Steps
1. Ticket 38 (tk-like CLI explore, HIGH PRIORITY) — spike-first: does existing tk cover claim protocol + frontier? 4 spike questions in the ticket; today's 37↔39 collision is fresh motivating evidence
2. Ticket 32 (re-judge + interchange) — value UP: `--judge-only` can upgrade the entire opus-only backlog to real consensus without re-running agents; outputs retained, row keys landed
3. Tickets 27/28/31/33/36 — parallel-friendly; 39 (WSL HOME doctor fix) belongs to the other session
4. Ticket 23 measurement ≥2026-07-25: `mise run session:skills 7` vs pre-fix 78/271 (29%)

## Fog
- Ticket 38 spike outcomes unknown (build vs adopt vs steering-only); its "where does it live" question leans on 37's known-tool pattern
- crush-Bedrock live behavior on corp unverified (ticket 31 probes it; crush probe currently fails with default glm-5.2 model — Bedrock config may change that)
- Ticket 28 flaky-vs-genuine still needs solo re-runs; NOTE: re-runs now judge with kiro+codex, so compare against the boundary caveat above
- Personal-env owed work: image-def birth runs (30, ledger-tracked), agy/GLM judge legs (35)

## Evidence
- Session commits: crew f98cd88..072d64d (~4); archwright f5f57c1
- Ticket 29 verification: SKIP conformance + resume dedupe in `results/2026-07-19T18-24-55Z`; judge recording in `results/2026-07-19T18-55-08Z` (meta judges.live [kiro,codex]); dry-run 39-row schema check `2026-07-19T18-25-20Z`
- codex-dead proof: zero codex sessions in `~/.codex/sessions/` for any judged-run window; 0-byte result replication before fix
- Tried & failed: codex judge probe without `--skip-git-repo-check` (root cause); `ensure_judges_probed` inside `$(...)` (subshell state loss — both now in environment-gotchas)
