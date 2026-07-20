---
id: "40"
title: "Build tkt: minimal ticket CLI honoring the shared crew/archwright contract"
status: open
blocked_by: ["38"]
env: either
spec: "ticket-cli"
priority: high
---

# Build tkt: minimal ticket CLI honoring the shared crew/archwright contract

## What to build

The custom ticket CLI that ticket 38's spike verdict selected (build > adopt/wrap tk >
steering-only). All design decisions are pre-made in `.memory/specs/ticket-cli-spec.md` —
read it first; do not re-litigate the contract or the verdict.

**Pre-made decisions (from the spec):**
- Home: `tools/tkt/`, Python, `uv tool install ./tools/tkt` (recall pattern, not known-tool)
- Name: `tkt` (must not shadow the existing `tk` binary on PATH)
- Frontmatter parsed as ordered key→raw-string lines — ids are TEXT (archwright's are
  unquoted; YAML 1.1 octal hazard), unknown fields preserved verbatim, no YAML dumper
  round-trip
- Status vocabulary: `open | in_progress | done`; frontier = open only
- Zero-padding inferred from existing filenames per repo (crew 2, arch 3; default 2)

**MVP commands (MUSTs R1–R7 + SHOULDs R8/R10/R11):**
- `tkt ready` — frontier: open + all blocked_by done, env-filtered vs $CREW_ENV,
  `priority: high` jumps lowest-number-first order
- `tkt new <slug> [--title ...] [--spec ...] [--env ...] [--priority high] [--blocked-by NN,NN]`
  — the claim: fetch, true-max scan (local + origin/main `.tickets/`), create, commit, push
- `tkt claim <id>` — status → in_progress, commit + push
- `tkt close <id>` — status → done, append dated Resolution stub, warn on unchecked ACs
- `tkt validate` — dangling/cyclic blocked_by, id↔filename mismatch, unchecked ACs on
  done tickets, unparseable files (hard error), boolean-key YAML casualties
- `tkt query` — JSON lines, all fields including extensions
- Any unparseable `.tickets/*.md` = loud named error in every command, never omission (R6)

## Context

- Spec (contract, verdict, requirements): `.memory/specs/ticket-cli-spec.md`
- Evidence base: `.scratch/research/{crew,archwright}-ticket-needs.md`, `tk-capabilities.md`
- Incidents motivating R2/R8: crew 12/13 + 37↔39 collisions, archwright 005
  double-implementation + 009/010 id collision — one collision occurred AFTER the manual
  claim protocol existed
- Steal from tk (trialed 2026-07-19): surgical rewrites preserving unknown fields;
  dry-run-by-default destructive ops. Avoid from tk: silent omission of unparseable tickets

## Acceptance criteria

- [ ] `tkt ready` output matches the hand-rolled awk frontier on BOTH repos' current
      `.tickets/` (crew: respects env + priority; arch: 3-digit unquoted ids handled)
- [ ] `tkt new` allocates past origin's max even when local is stale (test: local checkout
      missing the newest origin ticket)
- [ ] Round-trip proof: `tkt claim` + `tkt close` on a copy of archwright ticket 001
      preserves `created:` and all prose byte-for-byte outside the edited lines
- [ ] `tkt validate` exits 0 on both repos' current tickets as-is; a fixture with a
      dangling blocked_by / duplicate id / unquoted-boolean key fails loudly
- [ ] Tests wired into `mise run validate` or a `tkt`-local test task; validation-contract
      JSON output per project conventions
- [ ] No migration: zero edits to existing tickets in either repo

## Out of scope

- Steering/docs rollout, archwright adoption, plan drift-check (R9), renumber (R12),
  batch create (R13) — follow-up ticket 41
- Cross-repo blocked_by, board view, ledger integration (COULDs R14–R16)
