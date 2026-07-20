---
id: "38"
title: "Explore: custom tk-like ticket CLI fitting both crew-research and archwright shapes"
status: done
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

- [x] Spike verdict recorded: build / adopt existing / steering-only, with evidence
- [x] If build: follow-up ticket(s) with the design decisions pre-made; if not: frontier-work steering updated with whatever was learned
- [x] Existing tickets in both repos remain valid under whatever contract is chosen

## Out of scope

- Migrating GitHub/GitLab issue sources (frontier-work steering already covers those)
- Multi-agent task orchestration (taskboard skill territory)

## Resolution (2026-07-20)

**Verdict: BUILD** — minimal custom Python CLI (`tkt`), hybrid enforcement. Full spec
with contract, requirements yardstick, and rejected-alternative evidence:
`.memory/specs/ticket-cli-spec.md`. Follow-ups: ticket 40 (build, priority: high),
ticket 41 (rollout), spec: ticket-cli.

Spike answers:
1. **Adopt tk? No.** Hands-on trial (temp dir, 2026-07-19): reads `deps` not
   `blocked_by` (dependency-blind on all 77 existing tickets), hardcoded random `t-xxxx`
   ids, int priorities, `closed` not `done`, zero git integration — and silently omits
   tickets it can't parse (`priority: high` → invisible, exit 0). Wrap/fork also
   rejected: mismatches are core data-model with no config surface; the one asset
   (surgical field-preserving rewrites) is replicable. Raw trial:
   `.scratch/research/tk-capabilities.md`.
2. **Minimal shared contract:** crew's dialect (id/title/status/blocked_by) + optional
   extensions (env/spec/priority) + new `in_progress` status; ids parsed as TEXT
   (archwright's unquoted `id: 010` = YAML octal hazard); unknown fields preserved.
   Verified against full field inventory of both repos — all 77 tickets valid unchanged.
3. **Home:** crew-research `tools/tkt/` via `uv tool install` (recall pattern). Not a
   known tool — no skills/steering of its own to self-deploy.
4. **Enforcement layer:** hybrid. Mechanical rules (frontier, claim-allocation,
   validation) → tool; steering-only rejected on direct evidence — 5 collisions across
   both repos, one AFTER the manual protocol existed. Selection behavior and prose
   conventions stay in steering; AC/evidence quality stays judgment (Level 3).
