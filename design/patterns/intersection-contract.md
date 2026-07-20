---
kind: pattern
id: intersection-contract
name: "Intersection Contract: Core Schema Plus Optional Dialects"
scale: premise
confidence: "★★"
status: active
serves: [pf-consistent-agent-behavior, pf-files-hand-editable]
context: []
completed_by: [preserve-or-fail, automate-or-drop]
resolves_into:
  - "contract:frontmatter-contract"
  - "constraint:zero-migration"
---

# Intersection Contract: Core Schema Plus Optional Dialects

## Problem

**One tool serving two repos needs one schema, but the repos speak real dialects and neither may be forced to migrate.**

## Context

The premise-level commitment for tkt: every other pattern operates on files this contract describes.

## Forces

- **Desire:** The operator wants agents to exhibit identical ticket behaviors in every repo (pf-consistent-agent-behavior).
- **Desire:** Files stay hand-editable and trustworthy (pf-files-hand-editable).
- **Constraint (soft):** The contract stays minimal; per-repo needs enter as optional extensions, not required schema (minimal-contract).
- **Constraint (hard):** All 77 existing tickets remain valid unchanged (zero-migration).
- **Constraint (hard):** Sequential NN[-N]-slug ids are entrenched (sequential-readable-ids).

## Evidence

- Field inventory 2026-07-20 (verified, both repos): the intersection is exactly id/title/status/blocked_by; crew adds env/spec/priority, archwright has legacy created/closed on old tickets only. Padding differs (2 vs 3 digit) but is inferable from filenames (`.memory/specs/ticket-cli-spec.md`; extraction files).
- Empirical: both repos already interoperate through absent-field defaults (no `env:` = either; no `priority:` = normal) — the dialect mechanism exists in practice, this pattern names it (crew tickets 01–22 predate `env:` and remain valid).
- Rejected alternative — per-repo schemas/forked tool: reintroduces the behavioral divergence that cost reconciliation merges and motivated ticket 38 ("same frontier computation, same claim protocol… without forking the tool").
- Rejected alternative — adopt tk's schema: requires migrating all 77 tickets (deps, int priority, `closed`, random ids) and breaks prose cross-references (tk trial §2–3).
- Prior art (2026-07-20, `.scratch/research/prior-art-parsing-contract.md`): confirmed across three categories — XML versioning literature (Orchard's Must-Ignore pattern, 2003/04), IETF extensibility guidance (RFC 6709: an extension's absent-default must reproduce pre-extension behavior — env-absent=either passes this test; RFC 9170 on exercising extension points early), and production serialization practice (protobuf unknown-preserve + absent-default + zero-migration model). Partial contradiction (RFC 9413 anti-tolerance caution) is answered by preserve-or-fail's hard-fail on malformed structure. Known gap on record: Orchard's must-understand tier, if a semantics-critical extension field ever appears.

## Therefore

**Core = the verified intersection; dialects = optional interpreted extensions; everything else = preserved passthrough.** Required: `id` (text, matches filename), `title`, `status` (`open | in_progress | done`), `blocked_by` (list of id texts). Optional-interpreted: `env` (default either), `spec` (default ""), `priority` (`high` only). Unknown keys are preserved, never interpreted (per `preserve-or-fail`). Zero-padding is inferred per repo from existing filenames (default 2). `in_progress` is the one additive change — no existing ticket uses it, so adoption is compatible by construction.

## Consequences

- Contract changes are premise-level: any new REQUIRED field is a breaking change demanding a migration story — new needs should enter as optional extensions first.
- Dialect defaults are semantics the tool must document and test (absent ≠ empty).
- Frontier/status behaviors defined by other patterns are stated over THIS contract — the contract spec is their shared vocabulary.
- Does NOT cover: body structure (prose, out of scope), cross-repo id references (deferred COULD R14).

## Verification

- Contract spec `frontmatter-contract`: machine-readable field/type/default table (produced by archwright-contract phase).
- Constraint spec `zero-migration`: a script check that parses every existing ticket in this repo under the contract and fails on any invalid file — runnable today, pre-implementation.
- Acceptance test (ticket 40 AC): `tkt validate` exits 0 on both repos' current tickets as-is.

## Completion

This pattern is incomplete unless it also contains:
- `preserve-or-fail` — the read/write discipline for files under this contract.
- `automate-or-drop` — the governor on what may enter the contract.
