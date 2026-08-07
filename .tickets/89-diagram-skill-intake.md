---
id: 89
title: "Intake: diagram rendering skill — D2 + diagrams + Mermaid"
status: open
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
