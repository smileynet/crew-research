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
5. **`external:` is a reserved field** (added 2026-07-22, ticket 41 research). Shape:
   list of typed refs `[{system, id, url?}]`; scalar sugar (`github: 123`) is legal and
   normalized to the list shape at read time. `id` is a string (Jira keys aren't
   numbers). Carried today by unknown-field preservation — the tool interprets NOTHING
   until a sync feature is a real ticket; sync, when built, is one-way local-authoritative
   (matches CREW_TICKET_SYNC close-propagation). Prior art: Jira remote links
   (globalId separate from display url), Linear attachments — bare URLs and
   one-field-per-system both rejected (field-zoo evidence: gh-jira-issue-sync needed six
   custom fields for one integration).
6. **Status vocabulary is frozen contract** (added 2026-07-22). The three statuses model
   hand-offs, not activity taxonomy; additions require a spec change here, never
   convention drift. Anti-pattern evidence: Atlassian now hard-caps workflow
   customization (700 fields/150 types) after the "custom field zoo" emerged from
   individually-reasonable additions.

## Requirements (yardstick — full JTBD/evidence tables in the raw notes)

MUST: R1 frontier (blocked_by + env filter + priority jump) · R2 one-step collision-safe
allocation (fetch → true-max scan local+origin → create → commit → push) · R3 zero
migration, unknown fields preserved · R4 sequential NN-slug ids kept · R5 surgical
frontmatter edits · R6 no silent omission · R7 validate (dangling/cyclic blocked_by,
id↔filename, unchecked ACs on done, boolean-key YAML casualties).

MUST (added 2026-07-21, ticket 44): R17 black-box validation — every tkt command ships
with acceptance coverage invoked through the public CLI surface (installed console script
or subprocess), asserting only on exit codes, output, files, and git state; structured
outputs are machine-validated against `design/specs/cli-outputs.yaml` (the spec YAML is
the oracle, never a hand-copied field list). White-box seams are allowed ONLY where
black-box cannot reach deterministically, and each must be justified in the test. Applies
to ticket 41's rollout commands and all future surface.

MUST (added 2026-07-22, ticket 45): R18 input validation — user arguments are validated
BEFORE any filesystem operation (CVE-class root cause: validate-after-first-write).
Slugs: allowlist `^[a-z0-9][a-z0-9-]*$` (verified against both corpora: zero existing
violations). Windows reserved device names (CON, PRN, AUX, NUL, COM1-9, LPT1-9) rejected
case-insensitively and extension-blind on ALL platforms (cargo's approach); trailing
dots/spaces rejected. Titles and other free-text frontmatter values: always double-quoted
with `\` and `"` escaped (charset-allowlist for identifier fields, escape-and-emit for
free text). Hostile-input fixtures required per R17.

SHOULD: R8 visible claim (`in_progress` + pushed commit) · R9 plan-projection drift-check
against docs/plan.md-style tables (report-only; crew exit contract 0=no-drift/1=drift/
2=crash — Terraform's 2=drift scheme rejected for intra-CLI consistency with validate) ·
R10 close helper (status flip + dated Resolution stub + AC warning) · R11 JSON query ·
R12 renumber (filename + id + inbound blocked_by refs atomically; **birth-window
operation** — cited ids are external contracts, so renumbering a ticket that has been
referenced in prose/commits warns that those references won't follow) · R13 batch create
under a spec · R19 informative lost-claim-race reporting (on push rejection, re-fetch and
report the winner's state — "42 already in_progress upstream" — as a normal outcome, not
a raw git error; DynamoDB ALL_OLD model).

COULD: R14 cross-repo blocked_by (`repo#NNN`) · R15 board view · R16 owed-run ledger
linkage · R20 repo-declared tool version floor checked at startup (terraform
required_version / nextest pattern; trigger to build: >2 regular machines or a skew
incident).

UX constraints: files are the database (git-native, hand-editable); **ceremony decays**
(created/closed dates and checkboxes demonstrably rot untooled — automate a field or
drop it from the contract); the body is the spec (tool never manages prose).

## Decision record — id architecture & distribution (ticket 41 research, 2026-07-21/22)

Research corpus: `.scratch/research/{git-native-tracker-renumber, github-issue-alignment,
dual-id-systems, external-correlation-fields, ticketing-pitfalls, atomic-multifile-commits,
python-cli-distribution, projection-drift-check, cli-input-validation,
concurrent-claim-semantics, tool-version-skew}.md` (gitignored — regenerate if pruned).

- **Sequential ids KEPT; hash ids rejected** at current scale. Every mature distributed
  tracker uses hash/random ids (git-bug, Fossil, jj), and Beads was forced to migrate
  sequential→hash under heavy multi-agent contention — but our profile is 2 sessions,
  0 collisions since tkt's push-to-claim landed, and the collision machinery is built and
  race-tested. **Revisit trigger:** regular concurrent writers >3 OR collisions recur
  despite tkt. Migration path if triggered: grandfather numeric ids (ids are opaque text
  — zero migration), new ids 4-char base36 containing ≥1 letter, `created:` field written
  at new-time for ordering.
- **Dual-id (stable uuid under the display number) rejected.** Decision rule from prior
  art (Jira id/key, GitLab id/iid, YouTrack): the second id earns its cost when entities
  cross namespaces, allocation authorities multiply (import/federation/merge), or alias
  history must survive. tkt matches the skip case on every axis (single namespace,
  push-CAS single allocator, human-centric refs). Markdown+git is already the portable
  migration substrate (archive-and-freeze is the documented cheapest exit). **Revisit
  trigger:** federation, import/merge, or cross-repo refs beyond `repo#NNN`.
- **GitHub alignment is impossible by construction** — the create-issue API takes no
  number, the counter is shared with PRs/discussions, deletion gaps are permanent. All
  surveyed bridges MAP ids (git-bug metadata; gh-issue-sync renames provisional local ids
  to the real number after push — i.e., renumber IS the future bridge primitive).
  Correlation happens via the reserved `external:` field, never id-space alignment.
- **Distribution: documented editable install** — `uv tool install -e ./tools/tkt`
  (verified uv 0.11.8). Live source tracking eliminates snapshot staleness; caveats
  documented: entry-point/metadata changes need reinstall, binary breaks if the checkout
  moves. NOT a tier extension: extensions gate conditional content on a prerequisite, and
  tkt has none — frontier-work steering ships regardless with a manual fallback. doctor
  hints when tkt is absent from PATH.
- **Multi-file tool commits sanctioned for renumber/batch** (extends D2a, pattern
  `surgical-git-side-effects`): every path explicitly staged AND tool-edited, staged set
  verified equal to the tool's edit list (`git diff --cached --name-status`) before
  commit, loud failure on mismatch. Bulk-staging idioms remain banned. Prior-art
  consensus: atomic = one logical change regardless of file count; agent commit tooling
  explicitly bans `add -A`/`add .`.
- **Portable-substrate invariant** (design test for future features): content lives in
  files in the repo; the tool is a view. API-gated trackers exclude agents and newcomers;
  this is why tkt exists. Any feature that makes the files less self-describing or
  hand-editable fails this test.
