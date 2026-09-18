---
id: "158"
title: "Incorporate teach-me SVG diagram skill + tooling (draw-diagram.py, presets, theme/visual-qa)"
status: done
blocked_by: ["151", "153"]
spec: "rider-skill-updates"
---

# Incorporate teach-me SVG diagram skill + tooling

## Intent source

User request (2026-09-17): incorporate the SVG drawing skills & tools from
`D:\code\teach-me` into crew-research, scheduled AFTER the current rider-skill-updates
group (hence `blocked_by: 151, 153` — the two skill-change endpoints of that group).

## Source material (read before building)

`D:\code\teach-me\.kiro\skills\` — three related skills (the `.agents/skills/` entries are
symlink stubs pointing here):

1. **draw-diagram** (`draw-diagram/SKILL.md`) — the core. Generates inline SVG via
   `tools/draw-diagram.py` (drawsvg-backed, installed through `mise run setup` + uv). Output
   is SVG XML to stdout for direct embedding. Notable design:
   - Four diagram types: `stack` (layered), `flow` (L-to-R pipeline), `hub` (hub-and-spoke),
     `graph` (auto-ranked fan-out/fan-in with groups).
   - **Teaching-intent color presets** (concept=blue, example=green, process=amber,
     anti-pattern=red, infrastructure=gray) — color maps to pedagogical role, not aesthetics.
   - **Graphviz backend** (`--backend graphviz`) for cycles/cross-edges/large graphs, with
     engine auto-selection (dot/fdp/neato/sfdp/circo/twopi) and cluster subgraphs.
   - A clear "when to use this vs raw SVG vs D2" decision table.
2. **theme** (`theme/SKILL.md`) — `tools/theme-preview.py`: palette preview, WCAG contrast
   validation (AA/AAA table), CSS-variable emission. SVG-adjacent (governs diagram colors).
3. **visual-qa** (`visual-qa/SKILL.md`) — behavioral screenshot QA incl. an SVG-render check
   ("renders at all", color-vocabulary, labels-on-diagram). SVG-adjacent verification.

## Context / prior art in crew-research

- crew-research already has a global **`diagrams`** skill (ASCII/Mermaid/C4/D2/HTML, routes
  incl. kroki). teach-me's approach is DIFFERENT: local drawsvg generation of **inline SVG**
  with a teaching color vocabulary — no external service, embeddable output.
- Tickets **89/90** (done) already decided *discord-briefing/genai-field-lab* diagram tooling
  stays **project-level** (vendored per-project, no shared package unless 3+ adopters). This
  ticket is a NEW source (teach-me) and must respect that precedent: default to project-level
  unless the intake decides otherwise.
- Per AGENTS.md, project-level installable skills live in `compositions/project-level.yaml`;
  global skills in a tier. Tool scripts (draw-diagram.py) are a project-level concern by the
  89/90 precedent.

## What to build (intake-first, then decide)

1. **Study the source** (`/study-reference` on `D:\code\teach-me` draw-diagram + tools/draw-diagram.py)
   — document the tool's dependency footprint (drawsvg, graphviz binary), portability, and
   novel patterns (preset vocabulary, backend auto-selection).
2. **Decide the incorporation shape** (record as ADR if hard-to-reverse):
   - (a) Enrich the existing `diagrams` skill with an "inline SVG via drawsvg" section +
     the teaching-preset vocabulary (guidance only, no vendored tool), OR
   - (b) Add a project-level `draw-diagram` skill + vendored `tools/draw-diagram.py`
     (per the 89/90 project-level precedent), OR
   - (c) Both: preset-vocabulary guidance global, tool project-level.
3. **Apply the rider-skill-updates lessons** (this is why it's sequenced after the group):
   - P2 (ticket 151): the "when to use builtin vs graphviz vs raw SVG vs D2" table and the
     graphviz-binary prerequisite are SUCCESS-path caveats — keep them inline, not gated
     behind a reference (Rule 4 sharpening / Gate G4d from 151).
   - P1 (ticket 151): front-load trigger keywords; if it overlaps the existing `diagrams`
     skill, resolve by scope (split/positive-specificity), not a negative clause.
4. **Handle the graphviz system-binary dependency** — document install per OS (tool-installation
   skill) and a graceful fallback to the builtin backend when the binary is absent.
5. **theme/visual-qa**: decide whether they come along (they're teach-me-project-specific —
   palette files, lesson UI). Likely OUT unless a general need exists; note the decision.

## Acceptance criteria

- [x] Source studied; draw-diagram.py dependency + portability documented in `.scratch/teachme-svg-intake-158.md` (drawsvg required; graphviz pip+binary optional with in-tool guard; builtin backend pure-Python cross-platform)
- [x] Incorporation shape decided: **Option (a)** — enrich the global `diagrams` skill with the inline-SVG-via-drawsvg approach + teaching-preset vocabulary as GUIDANCE, tool NOT vendored (respects 89/90: teach-me is 1st adopter, not 3rd+). Not hard-to-reverse → no ADR (rationale in the study note).
- [x] Skill enriched: new "Inline SVG (drawsvg)" section in `diagrams/SKILL.md` with G4d-compliant inline caveats (decision table + graphviz prereq inline, not gated). `mise run validate` + `mise run lint` (0/0) + `generate` clean.
- [x] Tool NOT vendored (guidance-only per 89/90), so the "if tool vendored" clause doesn't bind — but the graphviz-binary prereq + builtin fallback ARE documented inline in the diagrams skill with per-OS install commands.
- [x] Overlap resolved by scope, not a negative clause: the new content lives IN the existing `diagrams` skill (same owner), so no new skill collides with it; no negative clause needed (per 151 P1).
- [x] theme/visual-qa: **OUT** — both are teach-me lesson-UI-specific (palette JSON, Playwright screenshot QA); no general crew-research need (documented in the study note).

## Out of scope

- Porting teach-me's lesson-UI-specific pieces (palette JSON files, progressive-reveal.js, glossary)
- Re-litigating the 89/90 project-level-vs-global decision unless teach-me is the 3rd+ adopter
- Building new diagram types beyond what draw-diagram.py already provides

## Why sequenced after the group

It should apply the skill-authoring improvements (P1 front-load/scope, P2 success-path-caveats-inline)
that tickets 151/153 land — building this skill first would miss the very lessons the group adds.
Hence `blocked_by: 151, 153`.

## References

- Source: `D:\code\teach-me\.kiro\skills\{draw-diagram,theme,visual-qa}\SKILL.md` + `tools/draw-diagram.py`
- Prior decisions: tickets 89, 90 (diagram tooling stays project-level)
- Existing skill: `atomics/skills/diagrams/SKILL.md`
- Applies: ticket 151 (skill-authoring P1/P2)

## Resolution (2026-09-18)

Intake of teach-me SVG tooling. Studied draw-diagram.py (drawsvg required; graphviz pip+system-binary optional with in-tool guard; builtin backend pure-Python cross-platform) — study note .scratch/teachme-svg-intake-158.md. DECISION: Option (a) — enriched the global diagrams skill with an 'Inline SVG (drawsvg)' section + the teaching color-preset vocabulary (concept/example/process/anti-pattern/infrastructure) + a builtin-vs-graphviz-vs-raw-SVG-vs-D2 decision table + the graphviz-binary prereq, all INLINE per ticket 151 G4d (success-path caveats not gated). Tool NOT vendored — respects 89/90 project-level precedent (teach-me is 1st adopter, not 3rd+); a project wanting the tool vendors it project-level. Overlap with diagrams resolved by scope (same owner, no negative clause) per 151 P1. theme/visual-qa OUT (lesson-UI-specific). validate + lint 0/0 + generate clean. Commit 31ad425.
