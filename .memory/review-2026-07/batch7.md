# Skill Review — Batch 7 (Project-Level Specialist Skills)

Reviewed: fiction-craft, world-building, poc-workflow, prototype-protocol, presentation-writing, ux-walkthrough
Date: 2026-07-16
Note: These are project-level specialist skills, not in any tier — deployed per-project on demand. The <100-line rule still applies per AGENTS.md.

## Verdict Table

| Skill | Verdict | Lines | Issues | Recommended Fix |
|-------|---------|:-----:|--------|-----------------|
| fiction-craft | KEEP | 69 | None. Both references linked from body. | — |
| world-building | KEEP | 59 | None. No references/ (fine). | — |
| poc-workflow | FIX | 117 | (a) Over 100 lines, no justification stated. (b) Orphaned reference: `references/poc-cheatsheet.md` is never linked from SKILL.md body. (c) Cheatsheet is stale — describes a superseded phase model. (d) Trigger overlap with prototype-protocol ("prototype end-to-end"). | Trim SKILL.md under 100 (Validation Checkpoint + Work Types table are candidates for a reference file). Rewrite or delete poc-cheatsheet.md to match the current map/fog model; link it if kept. Cross-link the Spike work type to prototype-protocol and drop "prototype end-to-end" from the trigger list. |
| prototype-protocol | KEEP | 67 | Minor: "Spike" branch conceptually overlaps poc-workflow's "Spike" work type, but scopes differ (single artifact vs project lifecycle). | Optional: add one-line cross-link ("for a full PoC lifecycle see poc-workflow"). |
| presentation-writing | FIX | 96 | Frontmatter incomplete: missing `metadata.practice` key (AGENTS.md requires `name`, `description`, `metadata.type`, `metadata.invocation`, `metadata.practice`). Only skill in batch missing it. | Add `practice: null` to metadata. |
| ux-walkthrough | KEEP | 85 | None. Has `params.output_path` extension — valid. | — |

## Per-Skill Detail

### fiction-craft — KEEP (69 lines)

1. **Purpose**: Prose-level craft rules for fiction — voice discipline, banned AI-slop vocabulary/structures, required story behaviors, and post-draft revision diagnostics.
2. **Triggers**: Distinctive — "fiction, narrative, creative prose", "stories, game narrative", "anti-slop discipline". No collision with other skills.
3. **Frontmatter**: Complete (`name`, `description`, `type: reference`, `invocation: both`, `practice: null`).
4. **Line count**: 69 — under limit.
5. **References**: Both linked from the body's References section (`minimum-elements.md`, `pipeline-routing.md`). No orphans.
6. **Duplication**: Clean split with world-building (prose craft vs world spec) and writing-style (creative vs technical). One shared research claim with world-building (see below) — cosmetic only.
7. **Stale**: No.

### world-building — KEEP (59 lines)

1. **Purpose**: A 6-question specification checklist (capabilities, boundaries, failure mode, social model, banned vocabulary) that must be answered before writing scenes in a fictional world.
2. **Triggers**: Distinctive — "fictional worlds, game systems", "magic system", "speculative conceits".
3. **Frontmatter**: Complete (`type: protocol`, `invocation: both`, `practice: null`).
4. **Line count**: 59 — under limit.
5. **References**: None exist, none referenced. Consistent.
6. **Duplication**: Complements fiction-craft rather than duplicating it. Minor shared claim: world-building says "Explicit corrections with examples produce 100% compliance" while fiction-craft's `minimum-elements.md` says "Explicit instruction with examples produces 100% compliance; general requirements produce ~50%". Same finding stated twice across skills — acceptable, both are self-contained.
7. **Stale**: No.

### poc-workflow — FIX (117 lines)

1. **Purpose**: End-to-end PoC lifecycle workflow that navigates from a loose idea to a validated proof via progressive discovery (destination → map → fog-clearing → build → validate).
2. **Triggers**: Good — "build a PoC, prove this works, validate this approach". Problem: the fourth trigger, "prototype end-to-end", collides with prototype-protocol's activation space ("Use when user wants to prototype…"). A user saying "prototype this" could activate either.
3. **Frontmatter**: Complete (`type: process`, `invocation: user-only`, `practice: null`).
4. **Line count**: **117 — over the 100-line limit with no stated justification.** AGENTS.md: "Do NOT create skills over 100 lines without justification." It's a rich lifecycle skill, but the Work Types table and the Validation Checkpoint section could move to `references/` to get under budget.
5. **References — ORPHAN FOUND**: SKILL.md links only `poc-file-layout.md` ("See [references/poc-file-layout.md](references/poc-file-layout.md) for full layout."). **`references/poc-cheatsheet.md` is never referenced from the body** — it's an orphan that will never progressively load.
6. **Duplication**: Overlaps prototype-protocol on the Spike concept only. poc-workflow defines Spike as a work type ("Prove feasibility with throwaway code → `.memory/spike-N-findings.md`"); prototype-protocol defines a Spike branch ("Minimal proof the path works. Findings captured, code deleted."). Same concept, two definitions, no cross-link. **Not a merge candidate** — poc-workflow is macro (project lifecycle), prototype-protocol is micro (single throwaway artifact). Fix by cross-linking, not merging.
7. **Stale — CONFIRMED**: `poc-cheatsheet.md` (last touched Jun 02) describes a superseded phase model that contradicts SKILL.md (updated Jul 10):
   - Cheatsheet: `"Understand → Research → Design → Plan → Implement → Validate"` with kickoff commands like `"Review [background material] and create summary.md + requirements.md"` and `"Create research-topics.md, then dispatch parallel research per topic"`.
   - SKILL.md: `"Phase 0: Chart the map … Phase 1: Research + Resolve … Phase 2: Plan the build"` centered on `proposal-plan.md` as a map with Destination/Fog/Out-of-scope sections.
   - The cheatsheet never mentions the map, destination, or fog — the core concepts of the current skill. An agent loading it would follow the old workflow.

   **Fix**: (a) rewrite poc-cheatsheet.md against the current map/fog model and link it from the body, or delete it; (b) move Work Types + Validation Checkpoint to references to get under 100 lines; (c) change trigger "prototype end-to-end" to something like "end-to-end proof" to avoid collision; (d) cross-link Spike work type to prototype-protocol.

### prototype-protocol — KEEP (67 lines)

1. **Purpose**: Build throwaway prototypes that answer one specific design question, routing between a Logic branch (pure module + TUI state explorer), a UI branch (structurally-different variants with a switcher), and a Spike.
2. **Triggers**: Distinctive — "sanity-check a data model, explore UI options, test a state machine", and the colloquial "let me play with it". Good coverage of natural phrasings.
3. **Frontmatter**: Complete (`type: protocol`, `invocation: both`, `practice: null`).
4. **Line count**: 67 — under limit.
5. **References**: Both linked from body (`logic-prototype.md` from the Logic Branch section, `ui-prototype.md` from the UI Branch section). No orphans.
6. **Duplication**: See poc-workflow item 6 — Spike overlap, complementary scopes, cross-link recommended in poc-workflow's fix. No changes required here; optionally add a one-liner pointing at poc-workflow for full-lifecycle needs.
7. **Stale**: No. References are tight and consistent with SKILL.md.

### presentation-writing — FIX (96 lines)

1. **Purpose**: Assertion-evidence methodology for slides and workshop materials — glance test, methodology selection by talk type, MARP directives, accessibility minimums, structure template.
2. **Triggers**: Distinctive — "MARP decks, PowerPoint content, demo scripts", "slide decks, workshop materials".
3. **Frontmatter — INCOMPLETE**: Has `name`, `description`, `metadata.type: process`, `metadata.invocation: both`, but is **missing `metadata.practice`**. Every other skill in this batch declares `practice: null`. AGENTS.md lists it as required: "YAML frontmatter: `name`, `description`, `metadata.type`, `metadata.invocation`, `metadata.practice`".
4. **Line count**: 96 — under limit.
5. **References**: None exist, none referenced. Consistent.
6. **Duplication**: None significant. Adjacent to `diagrams` (visuals) and `writing-style` (prose) but covers a distinct artifact type.
7. **Stale**: No. (Footer example "Company © 2026" is current.)

   **Fix**: Add `practice: null` under `metadata:`.

### ux-walkthrough — KEEP (85 lines)

1. **Purpose**: Cognitive-walkthrough protocol — walk a user flow step by step answering four questions (see/think/do/happen) to surface usability mismatches before building.
2. **Triggers**: Distinctive — "designing interfaces, evaluating user flows, reviewing UI proposals", "what a user will experience at each step".
3. **Frontmatter**: Complete, plus a valid `params.output_path: ".scratch"` extension.
4. **Line count**: 85 — under limit.
5. **References**: None exist, none referenced. Consistent.
6. **Duplication**: Complements prototype-protocol's UI branch (evaluation vs generation) — no overlap in content or triggers.
7. **Stale**: No.

## Cross-Cutting Observations

- **poc-workflow vs prototype-protocol**: Not a merge. Different altitude — project lifecycle vs single throwaway artifact. Actionable overlap is limited to (a) the duplicated Spike definition and (b) the "prototype end-to-end" trigger phrase in poc-workflow. Both fixed by edits to poc-workflow only.
- **Frontmatter consistency**: 5/6 skills declare `practice: null`; presentation-writing omits the key entirely. One-line fix.
- **Only stale artifact in batch**: `poc-workflow/references/poc-cheatsheet.md` — orphaned AND contradicts the current SKILL.md. Highest-priority fix in this batch.
