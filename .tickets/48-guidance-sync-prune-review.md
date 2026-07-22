---
id: "48"
title: "guidance-sync reviews edits/deprecations, not just additions"
status: done
blocked_by: []
env: either
---

# guidance-sync reviews edits/deprecations, not just additions

## What to build

A reviewed and reworked `guidance-sync` skill whose probes surface guidance that should
be EDITED or REMOVED, not only added. Today all five probes (P1–P5) produce additive
candidates — new rules, new notes, new entries. Nothing asks "what existing guidance
was wrong, ignored, redundant, or contradicted by this session?" A capture-only loop
grows the guidance layer monotonically until context budgets and signal-to-noise decay
(the exact failure the skill exists to prevent).

Scope includes proposing coordinated changes to related artifacts: adjacent skills
(project-audit, project-cleanup, agents-md-authoring), AGENTS.md, and any tooling
(deprecated.yaml mechanism, lint) that a prune path would lean on.

## Context

- **Skill source:** `atomics/skills/guidance-sync/SKILL.md` (protocol, user-only)
- **Observed trigger:** 2026-07-22 session — a full guidance-sync run produced only
  additive candidates; the skill's own structure never prompted an edit/deprecate pass
- **Existing prune machinery:** `compositions/deprecated.yaml` (skill retirement),
  project-audit (drift), project-cleanup (consolidation), memory steering ("delete
  notes that turn out to be wrong"), tkt validate decay rules
- **Research first (Design Gate):** prior art + best practices via subagent dispatch
  before proposing the rework; findings land in `.scratch/research/`

## Acceptance criteria

- [x] Research findings documented: prior art on agent-guidance pruning, doc-decay best
      practices, and existing in-repo deletion mechanisms (sources cited)
- [x] Proposed skill changes presented with findings and decided by operator
- [x] guidance-sync SKILL.md updated per decision (<100 lines; references/ if over)
- [x] Related-artifact changes applied or explicitly rejected: adjacent skills,
      AGENTS.md, tools
- [x] Redeployed to this machine's tools; a subsequent /guidance-sync run exercises the
      edit/deprecate path

## Out of scope

- Automated periodic session-history review (ticket 34 owns that)
- Building new lint/tooling beyond what the decided changes require

## Resolution (2026-07-22)

Applied in commit d5ed495 after a 4-subagent research dispatch (findings:
`.scratch/research/agent-guidance-pruning.md`, `doc-decay-practices.md`,
`note-maintenance-heuristics.md`, `in-repo-prune-mechanisms.md` — gitignored,
regenerate if pruned).

- **P6 prune probe added** to guidance-sync: violated-rules, corrections-despite-coverage
  (→ mechanical enforcement), repair-on-touch, duplicate consolidation; removals route to
  owning mechanisms (deprecated.yaml / agents-md-authoring / project-audit / docs-audit)
- **Net guidance delta** added to output format; entry-filter + supersede-don't-obliterate
  added to Discipline. Skill at 77 lines (<100 budget)
- **Related artifacts:** session-analysis retirement route documented; AGENTS.md
  deprecated.yaml scope clause; project-audit numbering fix (6→8 skip); ticket 34 gains
  the deletion-testing pointer. Rejected: quarantine mechanism (status flags rot without
  a sweep), new prune registry (routing suffices), project-cleanup edits (it's the actor)
- **Verified:** mise validate + lint pass (1 pre-existing warning), 12/12 design checks,
  redeployed to kiro-cli + codex (2 updated, 0 pruned; P6 present in both trees), live
  P6 run surfaced a real duplicate-ownership finding (AGENTS.md ↔ user-setup-guide WSL
  sections — left as operator call)
