---
id: 90
title: "Review: SVG generation tool scripts (diagram_themes.py + render pipeline)"
status: done
priority: medium
blocked_by: [89]
---

## What to review

Tool scripts for generating architecture diagrams from code:

1. `diagram_themes.py` — theme system (LIGHT/DARK/apply_theme/cluster_attr/edge_fontcolor)
   Originally from genai-field-lab, vendored into discord-briefing. Should it live in a
   shared location?

2. `architecture-diagram.py` — Python `diagrams` script producing the Discord lakehouse
   architecture as PNG (light + dark). 106 lines.

3. Proposed `render-diagrams.py` — batch renderer that finds all `.py`/`.d2`/`.mmd` in
   `diagrams/` and renders to `guides/assets/`, hash-gated for idempotency.

## Questions

1. Should `diagram_themes.py` be extracted to a shared tool package?
2. Is the theme system complete enough for general use, or does it need more presets?
3. Should the render pipeline support Graphviz DOT directly (`.gv` files)?
4. What's the CI/CD story — should diagrams be committed as artifacts, or rendered on demand?
5. D2 PNG export is broken on Cloud Desktops (Playwright→azureedge.net 404). Accept SVG-only
   for D2, or fix the rasterisation path?

## Artifacts

- `~/code/discord-briefing/tools/diagram_themes.py`
- `~/code/discord-briefing/tools/architecture-diagram.py`
- `~/code/genai-field-lab/scripts/diagram_themes.py` (original)
- `~/code/genai-field-lab/docs/diagram-options.md` (conventions doc)

## Decision needed

- Extract to shared package → define where (a `tools/` repo? a mise plugin?)
- Keep vendored per-project → document the copy convention
- Merge improvements back to genai-field-lab

## Resolution (2026-08-10)

Follows ticket 89 decision: diagram tooling stays project-level. diagram_themes.py remains vendored per-project. No shared package extraction needed unless 3+ projects adopt it. D2 PNG rasterisation issue (azureedge.net 404) is a cloud desktop infra problem, not a tool problem — accept SVG-only for D2 on those environments.
