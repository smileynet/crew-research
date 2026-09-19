---
id: "163"
title: "skill-authoring: add Jobs-to-be-done activation table technique (P4 ADD-TO)"
status: in_progress
blocked_by: []
spec: "rider-followups"
---

# skill-authoring: add Jobs-to-be-done activation table technique

## Intent source

Rider review, tkt skill (SYNTHESIS pattern #4). Proposal: `.scratch/new-skill-proposals-from-rider.md` P4.
tkt's "Jobs to be done" table indexes commands by agent *situation* ("park this", "what do I
work on next") rather than by tool verb — more activatable because it matches how a user
actually phrases the need.

## What to build

Add a short technique note to `atomics/skills/skill-authoring/SKILL.md`: for multi-command
tool-wrapper skills (git-protocol, tkt, mise-helper shape), organize the body with an
intent→command "Jobs to be done" table (situation the agent is in → the command/action),
not a flag reference. Improves both activation (matches user phrasing) and routing (agent
picks the right command).

## Acceptance criteria

- [x] `skill-authoring` gains a concise "Jobs-to-be-done table" technique note (where/when to use it)
- [x] Framed as a technique for multi-command tool-wrapper skills, not all skills
- [x] `mise run validate` + `mise run lint` pass; skill stays coherent
- [x] No duplication of existing activation guidance (references it, doesn't restate)

## Out of scope

- Rewriting existing tool-wrapper skills to add the table (guidance only)
