---
id: "113"
title: "Review and improve changelog-discipline skill — research popular GitHub patterns, remove jargon"
status: done
blocked_by: []
priority: high
---

# Review and improve changelog-discipline skill

## Intent source

Session finding (2026-08-18): changelog guidance should produce entries that communicate user-facing value clearly, without internal jargon or methodology terms. Research how successful projects write changelogs that users actually read.

## What to build

Research how popular GitHub projects write their changelogs (Keep a Changelog, conventional commits consumers, hand-written narrative changelogs), extract what makes entries useful to readers, and rewrite changelog-discipline to coach those patterns.

### Research phase (dispatch subagents)

Study 15-20 popular projects with well-regarded changelogs:
- Entry structure and level of detail
- How they communicate impact vs implementation
- Grouping patterns (Added/Changed/Fixed vs features/bugfixes/breaking)
- How they handle breaking changes (migration guidance inline vs linked)
- Audience awareness (who reads this — end users? developers? ops?)
- What they leave OUT (internal refactors, dependency bumps, CI changes)

### Rewrite phase

Based on findings:
- Ensure guidance produces entries a user understands without codebase knowledge
- Remove any methodology jargon from the skill itself
- Add guidance on audience-appropriate language (user-facing vs developer-facing changelogs)
- Clarify when NOT to write a changelog entry (internal-only changes)
- Update crew-research's own CHANGELOG.md as a reference implementation

## Context

- Current skill: `atomics/skills/changelog-discipline/SKILL.md`
- Related: `atomics/skills/release-protocol/SKILL.md` (references changelog)
- Changelogs are user-facing documents — they should communicate value, not implementation

## Acceptance criteria

- [x] 15+ popular projects' changelogs studied with findings documented
- [x] changelog-discipline SKILL.md rewritten with user-facing focus
- [x] No methodology jargon in the skill content
- [x] Guidance distinguishes user-facing vs developer-facing entries
- [x] crew-research CHANGELOG.md reviewed against new guidance
- [x] Skill still ≤100 lines (use references/ for detail)
- [x] `mise run validate` passes

## Out of scope

- Changing the release-protocol skill (keep the mechanical steps)
- Automating changelog generation (this is about what to write, not how to generate)

## Resolution (2026-08-23)

Rewrote changelog-discipline with user-facing focus, added references/patterns.md, fixed CHANGELOG.md
