---
id: "177"
title: "WATCH — evaluate v3 Workflows as a tier-gated kiro-only crew-pattern when schema stabilizes + leaves opt-in"
status: backlog
blocked_by: []
tags: [kiro-v3]
---

# WATCH: v3 Workflows

kiro-cli **2.26.0** added opt-in multi-step **Workflows** (V3): declarative
orchestration (steps/sequences/loops/parallel), each step a fresh isolated session
with explicit handoffs; recipes are JSON/YAML in `.kiro/workflows/`; bundled recipes
investigate / feature-pipeline / publish-pr. Enable in `/settings → Features`.

**Why watch, not adopt:** genuinely overlaps crew-research's `compositions/crew-patterns/`
+ `agent-archetypes/` + the subagent-reliability discipline, and IS a real deployable
artifact. But: opt-in, **V3-only, kiro-native (not portable to codex/crush/agy/opencode
— breaks the 5-tool contract)**, schema brand-new (2026-09-30) and likely to churn.

**Activate when:** Workflows leaves opt-in AND the authoring schema stabilizes. Then
prototype a tier-gated, kiro-only recipe that mirrors an existing crew-pattern; keep it
additive (never a portability prerequisite). Compare recipe semantics to our
agent-sop-author / crew-patterns before deciding to author or just cross-reference.

## Acceptance criteria (when activated)

- [ ] Re-check Workflows status (opt-in? schema stable?) and document the delta
- [ ] Decide: author a kiro-only tier-gated recipe vs cross-reference only (with rationale)
- [ ] If authored: additive, tier-gated, does not break the 5-tool portability contract
