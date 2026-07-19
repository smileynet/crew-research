---
id: "25"
title: "mcp-partitioning has passing activation + effectiveness evals"
status: done
blocked_by: ["24"]
spec: ""
---

# mcp-partitioning has passing activation + effectiveness evals

## What to build

Eval coverage for the mcp-partitioning skill (ticket 22 follow-up): an activation def (does "sessions feel slow / too many tools" trigger it?) and a judged effectiveness def (does it produce correct partitioning advice — placement rule, zero-tools trap, sentinel-probe validation?).

## Context

- **Origin:** ticket 22 shipped the skill with "eval definition for activation — future eval-suite pass" as an explicit follow-up
- **Blocked by 24:** new activation defs should land on the cleaned-up detection mechanism rather than adding to the dead-code path
- **Skill:** `atomics/skills/mcp-partitioning/SKILL.md` (kiro-scoped via `metadata.tools`), reference in `references/kiro-cli.md`
- **Trigger vocabulary to cover:** tool bloat, too many tools, sessions feel slow, mcp server placement, agent config, specialist agent, tools whitelist (from the description)
- **Effectiveness criteria source:** the measured migration it distills (~230 → ~14 tools/session) — score responses on whether they apply the placement rule and warn about the zero-tools trap, vs generic "remove some servers" advice
- **Conventions:** immutable `id:`, eval-criteria skill for judged criteria style, threshold/delta per existing skill-effectiveness defs

## Acceptance criteria

- [x] `activation-mcp-partitioning` def: ≥5 positive tasks covering the trigger vocabulary, ≥5 negatives; PASS (TPR ≥ 0.5, FPR ≤ 0.2) — 5 pos + 5 neg; run `activation-2026-07-19T13-13-30Z`: TPR 1.00, FPR 0, 10/10. Negatives designed to avoid commit-territory-style drift (ticket 27 precedent): MCP-protocol Q&A, UI "too many buttons" near-miss, unrelated dev tasks
- [x] Judged effectiveness def passes (with-skill ≥ threshold, delta ≥ delta_threshold) on a fresh run — `mcp-partitioning-effectiveness`, run `2026-07-19T13-32-32Z`: with-skill 5.00, baseline 2.44, delta 2.56 (thresholds 4 / 0.75). 3 tasks scoring the distinctive behaviors: placement rule + reachability, zero-tools whitelist trap + sentinel verification, negative-probe test plan
- [x] Both registered with immutable ids; lint clean — `mise run validate`: 0 errors, 0 warnings

## Resolution notes

- Both defs landed on the post-ticket-24 detection mechanism (Strategy 1 live output capture) as intended by the blocker.

## Out of scope

- Skill content changes beyond what eval failures force
- Porting the skill off kiro (it's tool-scoped by design)
