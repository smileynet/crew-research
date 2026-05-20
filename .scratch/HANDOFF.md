---
created_at: 2026-05-20T06:40:00-07:00
base_commit: 6c00e15
handoff_key: crew-research-bootstrap
---

# Handoff

## Objective
Begin T1: scaffold the monorepo directory structure. All blocking spikes (S1-S3) are resolved.

## Constraints
- Do not modify files in `resources/` (read-only symlinks)
- S4 (judge model) deferred to Phase 2 (needs eval harness first)
- S5 (per-project customization) deferred to Phase 5 (doesn't block Phase 1-4)

## Prior Decisions
- 14 design decisions captured in `.memory/CONTEXT.md`
- 8 feature specs in `docs/specs/`
- Task graph in `docs/task-graph.md`
- Spike plans in `docs/spike-plans.md`

## Spike Results (S1-S3)

| Spike | Result | Key Finding |
|-------|--------|-------------|
| S1 | PASS | Skills-as-slash-commands is TUI-only (shipped 2.1). `@prompt-name` works in non-interactive. Generator maps `invocation: user-only` → `.kiro/prompts/`. |
| S2 | PASS | Claude Code strips unknown frontmatter harmlessly. Generator translates `invocation` → native `disable-model-invocation`/`user-invocable`. |
| S3 | PARTIAL PASS | Agent Skills standard is extensible. Codex/Pi likely safe. Live testing deferred (no access). Generator has strip escape hatch. |
| S4 | DEFERRED | Blocked by eval harness implementation (T9). |
| S5 | DEFERRED | Doesn't block until Phase 5 (generator). Issue #1 tracks this. |

## Current State
- Repo: `smileynet/crew-research` (private GitHub, 6c00e15)
- All specs written, all blocking spikes resolved
- No implementation code yet — ready for T1

## Next Steps
1. T1: Create `atomics/skills/`, `atomics/eager-context/`, `compositions/agent-archetypes/`, `compositions/crew-patterns/`, `compositions/workspace-conventions/`, `tools/proofs/`, `tools/evals/`, `docs/practices/`
2. T2: Implement tool adapter YAML schema + kiro-cli adapter
3. T3: Implement proof harness

## Evidence
- Spike results: `.scratch/spike-s1-results.md`, `.scratch/spike-s2-results.md`, `.scratch/spike-s3-results.md`
- Specs: `docs/specs/*.md`
- Task graph: `docs/task-graph.md`
