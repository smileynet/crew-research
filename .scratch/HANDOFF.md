---
created_at: 2026-07-15T22:30:00-07:00
base_commit: e6b40b3
handoff_key: skill-audit-phase4-rebaseline
---

# Handoff

## Objective
Complete the skill audit cycle: Phase 3 consolidation done (11 merges + 1 removal), multi-tool deployment fixed, image-handling universalized. Remaining: Phase 4 re-baseline, code-review re-eval, feedback-loop investigation.

## Constraints
- Skills must stay <100 lines (references/ for overflow)
- Generator supports `metadata.tool` and `metadata.tools` for tool-scoped steering
- Eval judge is 4-model consensus (opus + GPT-5.5 + GLM-5.2 + Gemini)
- Subagent reliability steering deploys only to kiro-cli + codex
- crush reads from `~/.agents/skills/` + `~/.config/crush/AGENTS.md` (not `~/.kiro/`)
- agy print mode soft-denies tools (Issue #548) — use `--add-dir`, never `--dangerously-skip-permissions`

## Prior Decisions
- ADR 0008: Plugins → Extensions (single deploy model, auto-detect prerequisites)
- Subagent failures = prompt size (not quota). Write-then-read pattern fixes.
- `image-handling` is now universal (PROBE→DETECT→DISPATCH→FALLBACK + multi-validator consensus)
- Wayfinder "fog of war" pattern propagated to 7 planning/session skills
- 5 grounded evals retired (model caught up, Δ≈0)
- crush deployment fixed: `deploy_crush()` function, separate from kiro-cli
- Model ID standardized to `glm-5.2` (no `glm/` prefix)

## Current State
- **Skill consolidation Phase 3:** DONE — 11 merges + 1 removal executed and eval-verified. 5 merges eval-blocked (kept standalone). Skill count: 64 → 53.
- **Multi-tool deployment:** Fixed and committed (f09f368). crush deploys correctly, agy adapter updated for v1.1.3.
- **Image handling:** Rewritten as universal skill with 3 passing evals (greedy=4.0, honesty=4.0, consensus=5.0 on crush).
- **Eval harness:** Fixture install for workspace-injection fixed. crush isolation via CRUSH_SKILLS_DIR. agy uses --add-dir.
- **Validation:** `mise run validate` PASS (20 references), `mise run lint` PASS (0 errors).

## Next Steps
1. **Phase 4 re-baseline** — Run activation suite on remaining 53 skills. Confirm no regressions from consolidation.
2. **Re-eval code-review** — Inline spec fix committed (`296776b`) but never re-tested. Run the eval.
3. **Feedback-loop investigation** — `tighten.md` not loading reliably (Δ still low after two attempts: `3e2b8f0`, `56822fb`). May need a fundamentally different approach — inline summary in SKILL.md body instead of progressive-load pointer.
4. **Archwright doc fixups** — `worked-examples.md` needs desires-primary reframing, `open-questions.md` needs Q6 note.

## Fog
- Whether the 11 completed merges broke activation tests (Phase 4 will reveal)
- Whether `metadata.tools: [kiro-cli, codex]` array syntax works on all machines (yq version sensitivity)
- Whether feedback-loop's `tighten.md` problem is a loading issue or a content quality issue
- The 3-trial eval run used 1 trial for baseline — true delta comparison needs matched trial counts

## Evidence
- Eval baselines: `tools/evals/results/2026-07-10T12-36-50Z/` through `2026-07-10T*/`
- Image eval results: run locally during Claude Code session (crush adapter, all 3 PASS)
- Proof results: `tools/proofs/results/proof-S1-2026-07-10T15-35-17Z/`
- Specs: `.memory/specs/skill-audit-consolidation.md`, `.memory/specs/skill-improvements-mattpocock.md`
- ADR: `.memory/adr/0008-unify-tiers-and-plugins.md`
- Consolidation phase 3 results: bottom of `.memory/specs/skill-audit-consolidation.md`
