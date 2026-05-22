---
created_at: 2026-05-21T21:32:00-07:00
base_commit: a293920
handoff_key: proof-harness
---

# Handoff

## Objective
Begin Phase 2 (eval harness) or Phase 3 (author first skills). Both can run in parallel.

## Task Graph Position
- **Complete:** All spikes (S1–S7), T1–T7 (scaffold, adapters, proof harness, proofs passing on kiro-cli + Claude Code)
- **Current:** Phase 1 done. Choosing between T9 (eval harness) and T13 (first skills).
- **Critical path:** T9 → T10 → T13 → T16 → T18 → T22 → T25

## Constraints
- `resources/` is read-only (symlinked reference repos)
- Custom frontmatter in `metadata` block only (Agent Skills standard)
- Proof definitions use abstract fixture types (`eager_files`, `skills`, `agents`)
- Skills: <100 lines SKILL.md, `metadata.type` required, description must include trigger phrases

## Prior Decisions
- 14 design terms in `.memory/CONTEXT.md`, 2 ADRs in `.memory/adr/`
- Unified skill model: prompts are skills with `metadata.invocation: user-only`
- Context loading taxonomy: eager (CLAUDE.md/steering), lazy (skills), progressive (references/)
- Compositions are YAML manifests referencing atomics by name
- Eval: dual-run comparison (with/without skill), judge variance = 0, 1 judge trial / 3 agent trials
- Per-project customization: Params (80%) + Extends (20%), ADR 0002
- Cross-tool: eager-context scoping via subagent system prompt body (Claude Code), per-agent resources (kiro-cli)

## Current State
- Proof harness: 4 proofs pass on kiro-cli 2.3.0 AND Claude Code 2.1.148 from same definitions
- 8 specs: `docs/specs/*.md`
- Findings: `docs/spike-findings.md` (all 7 spikes)
- Architecture ref: `.scratch/claude-code-architecture.md`
- Prompts: `@handoff`, `@read-handoff`, `@grill-with-docs`, `@research-prior-art`
- GitHub: smileynet/crew-research (private), #1 closed, #2 open (deferred)

## Next Steps
1. T9: Implement eval harness — judge invocation, scoring pipeline, results storage
2. T13: Author first 5 skills (one per type: protocol, reasoning-mode, reference, decision, process)
3. T10: Add dual-run mode (with/without skill baseline comparison)
4. T8: Implement cross-link lint script (`tools/lint/check-crosslinks.sh`)

## Evidence
- Spike results: `.scratch/spike-s*.md`
- Claude Code docs: `.scratch/claude-code-architecture.md`
- Proof results: `tools/proofs/results/{kiro-cli,claude-code}/`
- Task graph: `docs/task-graph.md`
- Plan: `docs/plan.md`
