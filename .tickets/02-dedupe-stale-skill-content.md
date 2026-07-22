---
id: "02"
title: "Cross-skill contradictions and stale content are resolved"
status: done
blocked_by: []
spec: "project-review-followup"
---

# Cross-skill contradictions and stale content are resolved

## What to build

Skills that reference each other or share domains agree with each other. No skill points at removed skills, contradicts a sibling's protocol, or defines a competing format for the same artifact.

## Context

- **Relevant files:** `.memory/review-2026-07/skill-verdicts.md` (P1 section), batch1-3.md
- **Key conflicts:** troubleshooting-protocol vs feedback-loop-debugging Phase 1 protocols conflict; study-reference vs study-all-references write incompatible schemas to the same artifact; research-methodology has 3 competing output formats

## Acceptance criteria

- [x] cheatsheet: no references to removed skills (five-whys, session-review-patterns); consider generating from `mise run catalog`
- [x] troubleshooting-protocol: merged into feedback-loop-debugging OR re-scoped to non-overlapping triggers (RCA/postmortem); five-whys.md no longer routes to non-existent skills
- [x] study-reference + study-all-references: one output path, one section schema; `.references/` path convention consistent
- [x] research-methodology: points to research-output as the canonical format (inline format removed)
- [x] architecture-deepening: single Vocabulary section, duplicate reference file deleted
- [x] enforcement-hierarchy: practice frontmatter vs body claim reconciled; dead external-repo pointers removed
- [x] grill-with-docs: missing H1 added; "grill"/"stress-test" trigger words in description
- [x] `mise run validate` and lint pass

## Out of scope

- Line-count reductions beyond what dedup naturally achieves (ticket 03)

## Resolution
**Closed:** 2026-07-16 (Resolution backfilled 2026-07-22). Cross-skill contradictions resolved — troubleshooting-protocol merged into feedback-loop-debugging (user decision), study-reference/study-all-references unified to one output path and schema, research-output made the canonical research format, dead pointers and duplicate sections removed; validate + lint 0 errors. Evidence: docs/plan.md follow-up table row 02 ("✅ done (5cd6bb5)"); work commit 5cd6bb5, status→done in 3217828.
