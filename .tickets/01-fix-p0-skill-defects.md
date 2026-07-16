---
id: "01"
title: "Broken skill content is repaired (P0 + one-line fixes)"
status: done
blocked_by: []
spec: "project-review-followup"
---

# Broken skill content is repaired

## What to build

Skills with broken or contradictory content render correctly and follow repo conventions. An agent loading any of these skills gets working guidance, not empty tables or wrong paths.

## Context

- **Relevant files:** `.scratch/skill-review/verdicts.md` (P0 + P3 sections), batch4.md, batch8.md, batch6.md
- **Relevant decisions:** `.memory/adr/` path convention (`.memory/adr/NNNN-slug.md`)

## Acceptance criteria

- [x] tutorial-authoring: "Tutorial vs How-To" table has data rows (or links docs-audit's diataxis reference)
- [x] adr-authoring: storage path says `.memory/adr/NNNN-slug.md`; stale jargon ("warlock output", "BPAPPA survey") removed
- [x] adopt-project: references/project-notes.md linked from body
- [x] skill-authoring: declares its own scope boundary
- [x] project-audit: duplicate check 6 deleted
- [x] metadata.practice added where missing (presentation-writing, readme-writing, project-winddown, recall, spec-driven-development per batch1)
- [x] `bash tools/lint/check-crosslinks.sh` → 0 errors
- [x] Redeployed: `mise run init -- --global`

## Out of scope

- Line-budget reductions (ticket 03)
- Content deduplication across skills (ticket 02)
