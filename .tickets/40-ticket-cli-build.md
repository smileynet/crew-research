---
id: "40"
title: "Build tkt: minimal ticket CLI honoring the shared crew/archwright contract"
status: done
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
- **Archwright design artifacts (pipeline run 2026-07-20 — build against these):**
  `design/patterns/` (6 patterns: git-native-claim ★, intersection-contract ★★,
  preserve-or-fail ★★, layered-selection ★★, automate-or-drop ★★,
  surgical-git-side-effects ★★), `design/models/tkt-actors.{yaml,md}` (actor model,
  FSMs, invariants), `design/specs/` (11 specs: 3 behavior, 2 contract, 6 constraint).
  The 8 PENDING constraint checks (`target: tools/tkt`, CK-06) activate the moment code
  lands — run `python3 ~/code/archwright/tools/archwright-check.py --static design/specs/`
  after every change; NEW AC below makes them gates.
- Evidence base: `.scratch/research/{crew,archwright}-ticket-needs.md`, `tk-capabilities.md`
- Incidents motivating R2/R8: crew 12/13 + 37↔39 collisions, archwright 005
  double-implementation + 009/010 id collision — one collision occurred AFTER the manual
  claim protocol existed
- Steal from tk (trialed 2026-07-19): surgical rewrites preserving unknown fields;
  dry-run-by-default destructive ops. Avoid from tk: silent omission of unparseable tickets

## Acceptance criteria

- [x] `tkt ready` output matches the hand-rolled awk frontier on BOTH repos' current
      `.tickets/` (crew: respects env + priority; arch: 3-digit unquoted ids handled)
- [x] `tkt new` allocates past origin's max even when local is stale (test: local checkout
      missing the newest origin ticket)
- [x] Round-trip proof: `tkt claim` + `tkt close` on a copy of archwright ticket 001
      preserves `created:` and all prose byte-for-byte outside the edited lines
- [x] `tkt validate` exits 0 on both repos' current tickets as-is; a fixture with a
      dangling blocked_by / duplicate id / unquoted-boolean key fails loudly
- [x] Tests wired into `mise run validate` or a `tkt`-local test task; validation-contract
      JSON output per project conventions
- [x] `archwright-check --static design/specs/` runs green: the 8 pending constraint
      checks activate against tools/tkt and PASS (no-yaml-roundtrip, loud-parse-errors,
      stage-only-ticket-file, allocation-single-step, validate-reports-decay + 3 skeletons);
      zero-migration stays green
- [x] No migration: zero edits to existing tickets in either repo

## Out of scope

- Steering/docs rollout, archwright adoption, plan drift-check (R9), renumber (R12),
  batch create (R13) — follow-up ticket 41
- Cross-repo blocked_by, board view, ledger integration (COULDs R14–R16)

## Resolution (2026-07-21)

Built and verified. `tools/tkt/` — pyproject (uv-installable, zero deps) + `tkt/` package
(core.py frontmatter engine, gitio.py git facade, cli.py commands) + 13-test suite.

- AC1 frontier parity: parity tests vs independent recomputation on BOTH live corpora
  (crew 43 tickets, archwright 40); env filter + priority jump verified (CREW_ENV=corp
  excludes ticket 30; 40 jumped as HIGH)
- AC2 stale-local allocation: bare-remote + two-clone fixture; stale clone allocated past
  origin max; true-race fixture exercised PUSH_REJECTED -> renumber (42->43 reported)
- AC3 byte preservation: claim/close on arch-style ticket (unquoted id, created:, trailing
  spaces) — single-line surgical diffs; PLUS all 81 tickets in both repos round-trip
  byte-identical
- AC4 validate: pass on both live corpora (19 + 25 warnings, all unchecked-acs-on-done
  decay findings); violation fixtures fail loudly with named files (dangling/duplicate/
  bad-status/unparseable). Unquoted-boolean-key AC interpreted per its intent: raw-text
  parsing makes coercion IMPOSSIBLE — test asserts on:/no: keys stay text and survive
  rewrite. Contract enum extended additively (bad-env, duplicate-id) in cli-outputs.yaml
- AC5 mise: `mise run test:tkt` (13 passed); validate outputs crew validation-contract JSON
- AC6 archwright-check: 12/12 PASS — the 10 pending checks activated (target_status
  removed per CK-06) and pass; stage-only-ticket-file pattern upgraded during activation
  (R1: prose form over-matched docstrings, under-matched Python list idiom; non-vacuity
  re-proven with violating fixture). Tool defect found: check `exclude` documented but
  unimplemented -> archwright#040 filed; worked around by narrowing target to source pkg
- AC7 zero migration: git status clean of .tickets/ edits in both repos

Two implementation bugs the test suite caught pre-commit: soft reset after lost race
blocked pull --rebase (now mixed reset); rescan counted the tool's own candidate file
(now excluded — was renumbering spuriously on every stale-local retry).

Deferred to ticket 41 (unchanged): steering integration, archwright adoption, renumber,
plan drift-check, batch create, extension registration.
