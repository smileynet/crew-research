---
id: "48"
title: "guidance-sync reviews edits/deprecations, not just additions"
status: in_progress
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

- [ ] Research findings documented: prior art on agent-guidance pruning, doc-decay best
      practices, and existing in-repo deletion mechanisms (sources cited)
- [ ] Proposed skill changes presented with findings and decided by operator
- [ ] guidance-sync SKILL.md updated per decision (<100 lines; references/ if over)
- [ ] Related-artifact changes applied or explicitly rejected: adjacent skills,
      AGENTS.md, tools
- [ ] Redeployed to this machine's tools; a subsequent /guidance-sync run exercises the
      edit/deprecate path

## Out of scope

- Automated periodic session-history review (ticket 34 owns that)
- Building new lint/tooling beyond what the decided changes require
