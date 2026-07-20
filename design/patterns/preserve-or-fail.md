---
kind: pattern
id: preserve-or-fail
name: "Preserve or Fail: Tolerance Without Guessing"
scale: loops-systems
confidence: "★★"
status: active
serves: [pf-files-hand-editable]
context: [intersection-contract]
completed_by: []
resolves_into:
  - "constraint:no-yaml-roundtrip"
  - "constraint:loud-parse-errors"
---

# Preserve or Fail: Tolerance Without Guessing

## Problem

**Hand-edited ticket files vary in ways a parser must survive, but a parser that quietly copes is a parser that quietly loses tickets.**

## Context

In the context of `intersection-contract`, this pattern addresses how the tool reads and writes the files that contract describes.

## Forces

- **Desire:** Operators and agents want to hand-edit ticket files and trust tooling never to mangle, hide, or reinterpret them (pf-files-hand-editable).
- **Constraint (hard):** Ids must be read/written as raw text, never YAML-typed scalars (ids-as-text).
- **Constraint (hard):** Fields the tool does not interpret survive rewrites verbatim (preserve-unknown-fields).
- **Constraint (hard):** An unparseable file is a named hard error in every command — silent omission forbidden (loud-parse-errors).
- **Constraint (hard):** All 77 existing tickets stay valid with zero edits (zero-migration).

## Evidence

- Empirical (anti-pattern observed): tk trial 2026-07-19 — a crew-style `priority: high` field made the ticket SILENTLY OMITTED from ls/ready/blocked/query, exit 0, no warning; `tk show` alone errored (`.scratch/research/tk-capabilities.md` §4). An invisible high-priority ticket is the worst possible failure for a frontier tool.
- Empirical (mechanism proven elsewhere): tk's `status` rewrite preserved title/blocked_by/env/quoted-id byte-for-byte — surgical line edits are achievable and are the behavior worth keeping (same trial, §4).
- YAML hazard: archwright ids are unquoted (`id: 010`); YAML 1.1 parses leading-zero integers as octal, and unquoted `on/off/yes/no` keys coerce to booleans (environment-gotchas: a spec compiler generated empty state machines for months from exactly this class of bug, 2026-07). Round-tripping through a YAML dumper would also re-quote, re-order, and drop comments — destroying hand-edited files.
- Rejected alternative — strict schema with migration: violates zero-migration (77 tickets, two repos) and punishes the hand-editability that makes files-as-database work.
- Prior art (2026-07-20, `.scratch/research/prior-art-parsing-contract.md`): fail-loudly confirmed by "Parse, don't validate" (King 2019) + RFC 9413's critique of silent tolerance (IETF 2023); raw-text-never-typed confirmed by YAML Norway-problem postmortems and Nueyaml's independent identical fix; verbatim preservation confirmed by ruamel.yaml round-trip mode and protobuf v3.5.0 REVERSING its unknown-field-drop decision for forward compatibility. Convergent rule across all categories: strict about structure, tolerant about unknown well-formed fields.

## Therefore

**Three-way split by knowledge, with loud failure as the floor.** The parser treats frontmatter as an ordered list of key → raw-text-line pairs. (1) KNOWN fields are interpreted from raw text under the contract (ids as text). (2) UNKNOWN fields pass through verbatim on any rewrite — never interpreted, never reordered, never dropped. (3) UNPARSEABLE files (no frontmatter fence, duplicate keys, missing required fields) abort every command with an error naming the file and the defect. No YAML dumper ever writes a ticket file; edits are line-surgical.

## Consequences

- The tool needs its own minimal frontmatter reader/writer (~small, but owned code) instead of a YAML library round-trip.
- "Loud error in EVERY command" means one corrupt file blocks even unrelated queries — deliberate: it forces immediate repair and makes `tkt validate` the repair guide.
- Does NOT cover: validating the BODY (prose is out of tool scope per automate-or-drop), or concurrent hand-edit conflicts (git's merge machinery owns that).

## Verification

- Constraint spec `no-yaml-roundtrip`: tkt source contains no YAML dump/serialize calls targeting ticket files.
- Constraint spec `loud-parse-errors`: every command path routes unparseable files to a named-file hard error (no bare `continue`/skip on parse failure).
- Acceptance test (ticket 40 AC): round-trip on archwright ticket 001 preserves `created:` and prose byte-for-byte outside edited lines.

## Completion

This pattern is incomplete unless it also contains:
- Nothing further — parsing floor is complete at this scale; the contract it enforces lives in `intersection-contract`.
