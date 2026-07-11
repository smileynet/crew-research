---
created_at: 2026-07-10T21:40:00-07:00
base_commit: cee7880
handoff_key: skill-audit-improvements
---

# Handoff

## Objective
Skill audit + improvements from mattpocock reference + deployment unification. Multi-day session spanning recall maturity, skill improvements, subagent reliability, and the tier/plugin unification.

## Constraints
- Skills must stay <100 lines (references/ for overflow)
- Generator must support `metadata.tool` and `metadata.tools` for tool-scoped steering
- Eval judge is 4-model consensus (opus + GPT-5.5 + GLM-5.2 + Gemini)
- Subagent reliability steering deploys only to kiro-cli + codex

## Prior Decisions
- ADR 0008: Plugins → Extensions (single deploy model, auto-detect prerequisites)
- Subagent failures = prompt size (not quota). Write-then-read pattern fixes.
- `image-handling` is kiro-cli-only steering (tool-scoped)
- Wayfinder "fog of war" pattern propagated to 7 planning/session skills
- 5 grounded evals retired (model caught up, Δ≈0)

## Current State
- **Extensions model:** Shipped and working. `compositions/plugins/` deleted. Single deploy command.
- **Skill improvements:** 6 implemented from mattpocock. 3-trial baselines captured. 2 PASS (architecture Δ=+1.0, skill-authoring Δ=+0.83), 4 below threshold.
- **Subagent steering:** Global, tool-scoped. Proofs S1 (concurrency) and S2 (steering prevents) validated.
- **Eval harness:** 4-model consensus judging working. Proof runner at `tools/proofs/harness/run-proof.sh`.

## Next Steps
1. **Skill consolidation** — execute the 18 merges from `.memory/specs/skill-audit-consolidation.md` (move overlapping skills into `references/` of parent skills, update tier manifests)
2. **Re-eval code-review** — inline spec fix committed (`296776b`) but not re-tested
3. **Archwright doc fixups** — `worked-examples.md` needs desires-primary reframing, `open-questions.md` needs Q6 note
4. **Investigate feedback-loop** — `tighten.md` not loading reliably (Δ still low). May need stronger pointer or inline summary in SKILL.md body.

## Fog
- Whether the 18-skill consolidation will break activation tests (untested)
- Whether `metadata.tools: [kiro-cli, codex]` array syntax works on all machines (yq version sensitivity)
- The 3-trial eval run used 1 trial for baseline — true delta comparison needs matched trial counts

## Evidence
- Eval baselines: `tools/evals/results/2026-07-10T12-36-50Z/` through `2026-07-10T*/`
- Proof results: `tools/proofs/results/proof-S1-2026-07-10T15-35-17Z/`
- Specs: `.memory/specs/skill-audit-consolidation.md`, `.memory/specs/skill-improvements-mattpocock.md`
- ADR: `.memory/adr/0008-unify-tiers-and-plugins.md`
- Reference: `.references/mattpocock-skills/` (local, gitignored)
