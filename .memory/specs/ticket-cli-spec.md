---
type: spec
title: "Ticket CLI: requirements, shared contract, and spike verdict (ticket 38)"
---

# Ticket CLI — Requirements & Verdict

Spike output of ticket 38 (2026-07-19/20). Evidence base: full-corpus extraction of both
repos' tickets + lifecycle git history + hands-on tk trial (raw notes in
`.scratch/research/{crew,archwright}-ticket-needs.md`, `tk-capabilities.md` — regenerate
from repos if pruned).

## Verdict (spike Q1 + Q4): BUILD — minimal custom CLI, hybrid enforcement

- **Adopt tk as-is: NO.** Contract-level mismatches: reads `deps` not `blocked_by`
  (dependency-blind on all 77 existing tickets); random `t-xxxx` nanoid ids with hardcoded
  prefix (breaks sequential cross-references and lowest-number-first selection); int 0-4
  priority; `status: closed` not `done`; **silently omits tickets it can't parse**
  (`priority: high` → invisible to ls/ready, exit 0) — disqualifying (R6). Zero git
  integration, so the #1 need (R2 claim protocol) is uncovered regardless.
- **Wrap/fork tk: NO.** The mismatches are core data-model, not flag-level; no config
  surface exists (prefix/fields hardcoded — tested). Forking means maintaining a Go
  codebase to reach a contract a small script can honor directly. Its one proven asset —
  surgical frontmatter rewrites preserving unknown fields — is a design requirement we
  replicate (R5).
- **Steering-only: NO.** 5 collision incidents across both repos, **one AFTER the manual
  claim protocol existed** (crew 37↔39, 2026-07-19) — direct evidence Level 4 is
  insufficient for the mechanical rules. Per enforcement-hierarchy: mechanical rules get
  automation.
- **Hybrid split (Q4, enforcement-hierarchy applied):**
  - Level 2 (the tool): frontier computation R1, claim-allocation R2, surgical edits R5,
    loud parse errors R6, schema validation R7, work claim R8, plan drift-check R9,
    JSON query R11, renumber R12.
  - Level 3 (judgment): acceptance-criteria verification and evidence quality stay with
    agent/human review; tool only *warns* on unchecked ACs at close (R10).
  - Level 4 (steering): selection behavior (propose next, lowest-number-first), body/prose
    conventions, when to spawn follow-ups — frontier-work steering keeps these and calls
    the tool for the mechanical parts.

## Home (spike Q3): crew-research `tools/tkt/` — recall pattern, not known-tool

Python CLI installed via `uv tool install ./tools/tkt`, like recall. The known-tool
pattern (ticket 37) is for skill-bearing repos that self-deploy content; this CLI has no
skills/steering of its own — it's a binary that frontier-work steering (crew-owned)
references. Works against any repo's `.tickets/` from inside that repo (needs the target
repo's git context for claims). Name `tkt` avoids shadowing the existing `tk` on PATH.

## Shared frontmatter contract (spike Q2)

Superset of what exists; **all 77 existing tickets in both repos are valid unchanged**
(verified by field inventory 2026-07-20: crew uses id/title/status/blocked_by/spec/env/
priority; arch uses id/title/status/blocked_by + legacy created/closed).

```yaml
id: "38"              # digits as TEXT; must match filename prefix NN[-N]-slug.md
title: "..."          # outcome-phrased
status: open          # open | in_progress | done  (in_progress is NEW — see below)
blocked_by: ["29"]    # ids as text; all-done ⇒ frontier-eligible
# optional extension fields — interpreted when present, defaulted when absent:
env: either           # corp | personal | either (default) — filtered vs $CREW_ENV
spec: ""              # campaign grouping
priority: high        # only recognized value; jumps lowest-number-first ordering
# unknown fields (created, closed, lane, …) are PRESERVED verbatim, never interpreted
```

Contract rules:
1. **ids are text, never YAML scalars.** Archwright's are unquoted (`id: 010`) — YAML 1.1
   would parse octal. Tool parses frontmatter as ordered key→raw-string lines and never
   round-trips through a YAML dumper (also satisfies R3/R5 preservation).
2. **Zero-padding inferred** from existing filenames per repo (crew 2-digit, arch
   3-digit); default 2. No config file.
3. **`in_progress`** = claimed WIP: excluded from the frontier, listed on the board.
   Set by `tkt claim` (edit + commit + push). No existing ticket uses it, so adoption is
   additive. Motivating incident: archwright 005 implemented twice concurrently.
4. **Loud errors:** any file in `.tickets/` the tool can't parse is a hard error naming
   the file — never silent omission (tk's disqualifying behavior).

## Requirements (yardstick — full JTBD/evidence tables in the raw notes)

MUST: R1 frontier (blocked_by + env filter + priority jump) · R2 one-step collision-safe
allocation (fetch → true-max scan local+origin → create → commit → push) · R3 zero
migration, unknown fields preserved · R4 sequential NN-slug ids kept · R5 surgical
frontmatter edits · R6 no silent omission · R7 validate (dangling/cyclic blocked_by,
id↔filename, unchecked ACs on done, boolean-key YAML casualties).

SHOULD: R8 visible claim (`in_progress` + pushed commit) · R9 plan-projection drift-check
against docs/plan.md-style tables · R10 close helper (status flip + dated Resolution stub
+ AC warning) · R11 JSON query · R12 renumber (filename + id + inbound blocked_by refs
atomically) · R13 batch create under a spec.

COULD: R14 cross-repo blocked_by (`repo#NNN`) · R15 board view · R16 owed-run ledger
linkage.

UX constraints: files are the database (git-native, hand-editable); **ceremony decays**
(created/closed dates and checkboxes demonstrably rot untooled — automate a field or
drop it from the contract); the body is the spec (tool never manages prose).
