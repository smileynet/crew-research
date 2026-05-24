---
created_at: 2026-05-23T21:40:00-07:00
base_commit: 9600bd0
handoff_key: eval-harness
---

# Handoff

## Objective
Continue critical path: T17 → T18 → T22 (composition authoring, generator).

## Task Graph Position
- **Complete:** S1–S7, T1–T7, T9, T10, T13, T16 + eval methodology research
- **Current:** Eval harness done, skills validated, methodology findings captured. Ready for T17.
- **Critical path:** T17 → T18 → T22
- **Deferred:** Remaining experiments (#3), T8 (cross-link lint)

## Constraints
- `resources/` is read-only
- Skills use `metadata` block for custom fields
- Proof harness requires `yq` (~/.local/bin/yq)
- kiro-cli 2.3.0, Claude Code 2.1.148
- Eval harness requires `claude` CLI for judge invocation

## Prior Decisions
- Eval methodology: grounded evals (real project fixture) are the valid methodology; empty-workspace evals inflate results
- Skill value taxonomy: novel formats > enforcement gates > reasoning patterns
- five-whys narrowed to "non-obvious/recurring technical problems" (not general debugging)
- situation-routing description fixed (activates 100% now)
- verification-protocol can't reliably activate on-demand; may need eager-loading
- Overloading: 20% activation degradation with 5 skills present; strong activators immune

## Current State
- Eval harness: `tools/evals/harness/run.sh` (dual-run, activation detection, fixture support)
- Activation detector: `tools/evals/harness/check-activation.sh`
- Fixture: `tools/evals/fixtures/defu.yaml` (unjs/defu, TypeScript, vitest)
- 5 skills in `atomics/skills/` (3 descriptions updated based on findings)
- Findings docs: `docs/practices/eval-findings-v1.md`, `phase-2-grounded-results.md`, `experiment-1-activation-results.md`
- Experiments plan: `docs/practices/eval-experiments-plan.md` (deferred to #3)
- GitHub: #1 closed, #2 open (deferred), #3 open (experiments)

## Next Steps
1. T17: Begin composition authoring (agent archetypes as YAML manifests)
2. T18: Crew patterns (multi-agent compositions)
3. T22: Generator implementation
4. Read `docs/specs/composition-format.md` for the spec before starting T17

## Evidence
- Eval results: `tools/evals/results/` (multiple runs)
- Spike findings: `docs/spike-findings.md`
- All specs: `docs/specs/*.md`
- Experiment designs: `docs/practices/eval-experiments-plan.md`
