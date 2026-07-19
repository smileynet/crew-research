---
id: "38"
title: "Explore: custom tk-like ticket CLI fitting both crew-research and archwright shapes"
status: open
blocked_by: []
env: either
spec: ""
priority: high
---

# Explore: custom tk-like ticket CLI fitting both crew-research and archwright shapes

## What to build

Evaluate (and if the evaluation says yes, build) a purpose-built ticket CLI that both crew-research and archwright projects use, so agents exhibit consistent work behaviors across repos: same frontier computation, same claim protocol, same status transitions, same frontmatter contract.

Today `tk` is referenced as optional in frontier-work steering, and each repo hand-rolls the conventions: `.tickets/NN-slug.md` scanning via awk, manual claim-before-allocate (fetch + rescan + push promptly), manual status edits, and per-repo frontmatter dialects (crew-research: `env`/`spec`/`priority`; archwright adds lane/span concepts per ADR 0007 checkpoints). Divergence has already cost reconciliation merges twice (archwright 005 pair, crew-research 12/13 collision).

Candidate behaviors the tool would own:

- `ready` — frontier computation (status open + all blocked_by done), respecting env designation (CREW_ENV vs ticket `env:`)
- `new` — collision-safe allocation: fetch, scan local + origin for true max ID, create, commit, push (the claim) in one step
- `close` / status transitions — with plan-table sync or a check that flags plan drift
- schema validation — one frontmatter contract with per-repo extension fields, so both shapes fit without forking the tool

## Spike questions (answer before committing to build)

1. Does existing `tk` (or another off-the-shelf tool) already cover the claim protocol and frontier semantics? (Research gate: 2+ sources / a real trial before building custom.)
2. What is the minimal shared frontmatter contract that satisfies both repos without breaking existing tickets?
3. Where does it live — crew-research `tools/` (deployed like recall) or its own repo (hydrated like archwright, ticket 37)?
4. Is a CLI the right enforcement layer, or is steering + a validation script enough? (enforcement-hierarchy skill applies)

## Acceptance criteria (explore phase)

- [ ] Spike verdict recorded: build / adopt existing / steering-only, with evidence
- [ ] If build: follow-up ticket(s) with the design decisions pre-made; if not: frontier-work steering updated with whatever was learned
- [ ] Existing tickets in both repos remain valid under whatever contract is chosen

## Out of scope

- Migrating GitHub/GitLab issue sources (frontier-work steering already covers those)
- Multi-agent task orchestration (taskboard skill territory)
