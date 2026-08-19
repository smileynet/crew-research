---
id: "112"
title: "Review and improve readme-writing skill — research popular GitHub patterns, remove jargon"
status: in_progress
blocked_by: []
priority: high
---

# Review and improve readme-writing skill

## Intent source

Session finding (2026-08-18): the readme-writing skill includes a JTBD table pattern that reads as jargon-heavy and unnatural for the user-facing audience. The skill should guide agents toward patterns that real popular projects actually use, not impose framework vocabulary.

## What to build

Research how successful GitHub projects structure their READMEs (10K+ stars, diverse ecosystems), extract the natural patterns that make them effective, and rewrite the readme-writing skill to coach those patterns without framework jargon.

### Research phase (dispatch subagents)

Study 15-20 popular GitHub projects across ecosystems (Rust CLI tools, JS/TS frameworks, Python libraries, Go tools, developer tools). For each:
- Section order and naming
- How they communicate "who is this for" (without JTBD tables)
- How they hook the reader in the first 5 lines
- Quick start patterns that actually work
- What they DON'T include

### Rewrite phase

Based on findings:
- Remove the JTBD table pattern (or replace with a more natural "Use cases" or "Who it's for" approach if research shows one)
- Replace any methodology jargon (JTBD, Diátaxis, etc.) with plain descriptions
- Ensure guidance produces READMEs that sound like a human wrote them for humans
- Update anti-patterns based on what the research shows popular projects avoid

## Context

- Current skill: `atomics/skills/readme-writing/SKILL.md`
- The skill is user-facing guidance — it should produce warm, clear READMEs, not academic exercises
- Also review crew-research's own README.md against the updated guidance

## Acceptance criteria

- [ ] 15+ popular GitHub repos studied with findings documented
- [ ] readme-writing SKILL.md rewritten without framework jargon
- [ ] JTBD table removed or replaced with natural alternative
- [ ] crew-research README.md updated to match new guidance
- [ ] Skill still ≤100 lines (use references/ for detail)
- [ ] `mise run validate` passes

## Out of scope

- Changing other skills' descriptions or activation triggers
- User-facing documentation beyond README (that's docs-audit territory)
