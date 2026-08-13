---
id: "89"
title: "Intake: diagram rendering skill — D2 + diagrams + Mermaid"
status: done
priority: medium
blocked_by: []
---

## What to review

A diagram-building skill has been prototyped in `~/code/discord-briefing/`. It uses three
local renderers (Python `diagrams` for AWS icons, D2 for governance/container diagrams,
Mermaid for sequences) and produces SVG + PNG pairs in light/dark. No external services
(kroki.io is data egress for confidential architectures).

## Questions for intake

1. Should this become a **global skill** in `~/.kiro/skills/` or stay project-local?
2. Does it overlap with the existing global `diagrams` skill? (That one routes to kroki.io
   — this one renders locally for confidentiality.)
3. Should `mise run diagrams` become a convention like `mise run check`?
4. Is the D2 dependency acceptable globally? (single binary, no runtime deps for SVG)
5. Should `build-guide.py --check` gain asset validation gates (missing/orphan/stale)?

## Artifacts to review

- `~/code/discord-briefing/tools/architecture-diagram.py` — Python `diagrams` example
- `~/code/discord-briefing/tools/diagram_themes.py` — vendored theme system
- `~/code/discord-briefing/.scratch/research/d2-diagrams.md` — D2 research
- `~/code/discord-briefing/.scratch/research/svg-graphviz.md` — SVG/Graphviz research
- `~/code/discord-briefing/.scratch/research/diagram-skill-design.md` — skill design

## Decision needed

- Accept as global skill → create SKILL.md in `~/.kiro/skills/render-diagrams/`
- Accept as convention → document in project-conventions steering
- Reject / defer → close this ticket

## Decision (2026-08-10): DEFER — accept as project-level, not global

**Rationale:**

1. **The existing `diagrams` skill already covers format selection and D2/Mermaid usage
   guidance globally.** What this adds is a LOCAL RENDERING PIPELINE — running d2/mermaid-cli
   binaries and producing themed file pairs. That's tooling, not knowledge.

2. **Three dependencies globally is too heavy.** D2 binary + Python `diagrams` + mermaid-cli
   is a large toolset. Most projects don't render diagrams locally — they use Mermaid in
   markdown (GitHub/GitLab renders it) or inline ASCII. Only projects with confidentiality
   requirements or build systems need local rendering.

3. **Theme system is project-specific.** Light/dark pairs, specific color palettes, cluster
   styling — these vary per project's visual identity.

4. **Asset validation (missing/orphan/stale) belongs in a build system**, not a global skill.
   It's a `mise run check` task for projects that have diagram assets.

**What to do instead:**

- Keep `diagram_themes.py` and the render pipeline in project repos that need them
- Document the PATTERN in the existing `diagrams` skill's references/ (how to set up local
  rendering when kroki.io isn't acceptable) — a 20-line addition, not a new skill
- If the pattern recurs across 3+ projects, reconsider as a global skill then

**Answers to the intake questions:**

1. Stay project-local (or shared via a `tools/` package if multiple projects use it)
2. Overlaps minimally — `diagrams` skill handles format selection; this is the render step
3. `mise run diagrams` is a good project convention but not a global one (not all projects have diagrams)
4. D2 dependency is fine project-locally but too heavy for a global requirement
5. Asset validation gates: yes, but as a project-level mise task, not a global skill gate

## Resolution (2026-08-10)

DEFERRED. Local rendering pipeline stays project-level. Existing diagrams skill covers format selection globally. Add a references/ note about local rendering setup if the pattern recurs across 3+ projects.
