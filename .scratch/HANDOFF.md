---
created_at: 2026-07-21T21:16:00+00:00
base_commit: 5f54275
handoff_key: tkt-rollout
---

# Handoff

## Objective
tkt (git-native ticket CLI) shipped this session — ticket 40 done. Remaining workstream: 41 (rollout: steering, archwright adoption, renumber/edit/sync-plan) and 44 (black-box acceptance layer). Then general frontier.

## Constraints
- CREW_ENV=corp (agy forbidden; deploys = kiro-cli + codex)
- tkt interim invocation: `PYTHONPATH=tools/tkt python3 -m tkt.cli ...` (AGENTS.md Commands block has the full recipe incl. cross-repo form and birth-flow notes). `tk` on PATH is UNRELATED — never use it
- Parallel Windows session active: fetch before allocating; use `tkt new` (it handles the race). Crew max id = 44, archwright max = 042
- R17 (ticket-cli spec): every tkt command needs black-box coverage; white-box seams must be justified

## Prior Decisions
- Ticket 38 verdict: BUILD tkt; contract/requirements in `.memory/specs/ticket-cli-spec.md`
- Archwright resolve 2026-07-20: D1a bounded renumber-retry, D2a stage-only-ticket-file, D3a distribution deferred to 41. Design artifacts: `design/patterns/` (6), `design/models/tkt-actors.*`, `design/specs/` (13) — checks GATE all tkt changes
- Design Gate in AGENTS.md: tension/invariant/rejected-alternative questions route build tickets to archwright pipeline (calibration: 40 = 3×yes; 39/42/43 = 3×no)
- Guidance-sync applied ×2: AGENTS.md tkt block, glossary `tkt` term, archwright reflections R11/R12, agents-md-authoring native-tests rule

## Current State
Clean boundary — tree clean (minus this handoff), all pushed both repos (crew 5f54275; archwright c499981+body). Nothing mid-flight. docs/plan.md is authoritative for ticket status.

## Next Steps
1. Ticket 44 (black-box layer) or 41 (rollout) — both frontier, no priority flags. 44 is fresher context (test suite); 41 has cross-repo momentum (archwright#042 filed as receiving end, birth-run AC already ✅ both repos)
2. Working tkt: run `archwright-check --static design/specs/` after any tools/tkt change — 12 checks gate it (currently 12/12 PASS)
3. Ticket 23 measurement window opens ~2026-07-25 (`mise run session:skills 7` vs 78/271 baseline)
4. Upstream (archwright repo sessions): #039 frontmatter split, #040 exclude unimplemented, #042 adoption — workarounds in reflections R11/R12 meanwhile

## Fog
- Ticket 41's extension-registration decision (tier extension vs documented install) — deliberately deferred, decide with rollout evidence
- Python stack adapter (trace-mode checking of tkt behavior specs) — archwright-repo Extension Protocol work, not ours

## Recommended Updates
- [ ] Redeploy tier (`mise run init -- --global ...`) so the agents-md-authoring skill edit reaches deployed machines
- [ ] `.scratch/archwright-digest-tkt.md` — span digest presented + accepted; delete on next cleanup (design/ + tensions yaml carry the durable record)

## Evidence
- tkt: `tools/tkt/` — `mise run test:tkt` = 13 passed; archwright-check 12/12 PASS; both corpora validate pass
- Ticket 40 Resolution has full AC evidence; two impl bugs caught by tests pre-commit (soft-reset, self-counting rescan)
- Tried & failed: tk adoption (contract mismatches, `.scratch/research/tk-capabilities.md`); size-proxy design-gate trigger (superseded by native-tests form)
- Spike research corpus `.scratch/research/*.md` — gitignored, patterns cite with "regenerate if pruned" (deliberate)
