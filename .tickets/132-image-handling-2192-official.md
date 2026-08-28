---
id: "132"
title: "Update image-handling steering — local image attachment official in 2.19.2"
status: open
blocked_by: []
validation_criteria:
  - "image-handling.md no longer calls local attachment field-proven/workaround; states officially supported since 2.19.2"
tags: ["kiro-v3"]
---

# Update image-handling steering — local image attachment official in 2.19.2

## Intent source

Ticket 123 (kiro-cli 2.19.2 feature review), image-attachment half. Full analysis:
`.scratch/research/t123/image-handling-review.md`. 2.19.2 made "image paths in
prompts attach images in local sessions" official — the image-handling guidance
still frames it as an undocumented field-proven workaround.

## Context

Target files (image-handling is deployed steering + a skill references dir):
- `~/.kiro/steering/image-handling.md` (deployed) and its source
- `~/.kiro/skills/image-handling/references/tool-dispatch.md`
- Note: confirm the repo source location before editing (may be deployed-only like
  other steering — apply to source of truth, then it deploys).

## What to build

Five documented edits (from the research review):

1. **HIGH** — Remove the "NOT explicitly documented" / "field-proven, re-validate
   on major CLI upgrades" caveat; replace with "officially supported as of kiro-cli 2.19.2."
2. **MEDIUM** — Verify whether `--trust-tools=read` is still needed for headless
   image analysis, or if native attachment makes it unnecessary; update the example.
3. **MEDIUM** — Re-check kiro.dev/docs/cli/chat/images/ for newly documented pixel
   dims / resize tier / min size; fill the "not documented" table cells if now published.
4. **LOW** — `tool-dispatch.md` kiro-cli section: reframe — official support; the
   fresh-session dispatch is for context compaction (a model limit), not tool fragility.
5. **LOW** — SKILL/frontmatter description: drop the "workaround" framing.

Do NOT change (per research): token-cost formula, sizing rule, practice notes,
multi-tool dispatch logic, codex/agy/crush sections, fallback section.

## Acceptance criteria

- [ ] "field-proven" / "NOT explicitly documented" caveat removed → "official since 2.19.2"
- [ ] `--trust-tools=read` necessity verified and the headless example updated accordingly
- [ ] Limits table re-checked against kiro.dev docs; documented values filled if published
- [ ] tool-dispatch.md kiro-cli section reframed (official support; fresh-session = compaction only)
- [ ] "workaround" framing removed from the description
- [ ] Applied to source of truth (not deployed-only); redeploys cleanly

## Out of scope

- Any change to token-cost/sizing/practice-notes/multi-tool/fallback content (unaffected by 2.19.2)
