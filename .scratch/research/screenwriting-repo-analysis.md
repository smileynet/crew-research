---
topic: screenwriting repo skill candidates
date: 2026-05-25
status: complete
confidence: high
---

# Screenwriting Repo — Skill Candidates

## Summary

The `~/code/sceenwriting` repo contains a 5-phase story generation pipeline with sophisticated craft guidance. Several concepts are portable as general-purpose skills beyond fiction writing. The strongest candidates are the phased pipeline pattern, the minimum-elements checklist approach, and the anti-slop/craft rules (which overlap with our existing writing-style skill but go deeper for creative contexts).

## Sources

- `~/code/sceenwriting/AGENTS.md` — pipeline overview and phase routing
- `~/code/sceenwriting/docs/minimum-writing-elements.md` — 8 required story elements
- `~/code/sceenwriting/docs/craft-principles-when-to-apply.md` — 6 revision diagnostics
- `~/code/sceenwriting/docs/writing-subagent.md` — voice, prohibitions, quality bar
- `~/code/sceenwriting/docs/story-generation-pipeline.md` — 5-phase pipeline definition
- `~/code/sceenwriting/docs/skills/fiction-craft-writing.md` — anti-slop rules for prose

## Portable Skill Candidates

### 1. Phased Generation Pipeline (pattern)
**What**: Separate divergent (generation) from convergent (revision) phases. Never apply later-phase constraints during earlier phases.
**Portable to**: Any multi-step creative or analytical work — design docs, architecture proposals, research reports.
**Skill type**: protocol
**Effort**: New skill (~60 lines)

### 2. Minimum Elements Checklist (pattern)
**What**: Define N required elements that must be present regardless of style/approach. A lens/style shapes HOW they appear, not WHETHER.
**Portable to**: Any templated output — PRs, ADRs, handoffs, research reports. We already do this implicitly (handoff has "required sections") but this formalizes the pattern.
**Skill type**: reference
**Effort**: Already partially captured in existing skills. Could be a meta-skill for "how to define minimum elements for any artifact."

### 3. Fiction Craft Writing (creative prose)
**What**: Anti-slop rules specific to narrative/creative writing. Em-dash density, rhythm variation, banned vocabulary, structural tells.
**Portable to**: Any project doing creative writing, game narrative, content creation.
**Skill type**: reference
**Effort**: Port directly (~90 lines, needs trimming)

### 4. World-Building Specification (game/fiction)
**What**: The premise specification checklist — what does the conceit DO, NOT do, what happens on failure, social model, banned vocabulary.
**Portable to**: Game world creation, speculative fiction, any project defining a fictional system.
**Skill type**: protocol
**Effort**: New skill (~50 lines)

### 5. Revision Diagnostics (pattern)
**What**: 6 diagnostic questions applied AFTER drafting: dramatize the choice, pay off details, voice consistency, no circular argument, no connective tissue without payload, show vs tell.
**Portable to**: Any revision/editing workflow. The "diagnostic questions after drafting" pattern is more general than fiction.
**Skill type**: protocol
**Effort**: New skill (~70 lines) — distill the 6 questions without the fiction-specific examples

## Related Topics

- Phased pipeline as a general crew pattern (not just fiction)
- "Minimum elements" as a validation pattern for any structured output
- Anti-slop rules overlap with our `writing-style` skill — consider merging or making fiction-craft an extension
- The "lens" concept (same content, different style) maps to our archetype model

## Related Tools & Resources

- The `bd` (beads) issue tracker used in the repo
- Story orchestrator prompt (`docs/prompts/story-orchestrator.md`) — example of a dispatcher for creative work
- Director/author profiles in `authors/` — examples of "lens" definitions

## Recommendations

### Adopt Now (high value, low effort)
- **World-building specification** — useful for game projects, speculative fiction
- **Fiction craft writing** — port for content crew, game narrative work

### Consider Adopting (medium value, needs design)
- **Phased pipeline pattern** — generalize beyond fiction into a reusable crew workflow pattern
- **Revision diagnostics** — generalize the "diagnostic questions after drafting" approach

### Research Further
- How the "lens" concept (same story, different style) maps to our archetype/skill model
- Whether the "minimum elements" pattern should be a meta-skill or just a documentation convention
- The story orchestrator as a model for a "content dispatcher" that routes by content type

### Testing Spikes
- Deploy fiction-craft-writing to the content crew and test on a narrative task
- Test whether the phased pipeline (generate freely → revise with diagnostics) produces better output than single-pass generation with all constraints loaded upfront
