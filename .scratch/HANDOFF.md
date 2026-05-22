---
created_at: 2026-05-21T22:36:00-07:00
base_commit: a7c04d0
handoff_key: skill-authoring
---

# Handoff

## Objective
Build the eval harness (T9) to enable dual-run skill evaluation, then validate the 5 authored skills prove value against baseline.

## Task Graph Position
- **Complete:** S1–S7, T1–T7 (proof harness + both adapters), T13 (5 skills authored)
- **Current:** Phase 1 done, T13 done. Next is T9 (eval harness) → T10 (dual-run) → T16 (eval skills).
- **Critical path:** T9 → T10 → T16 → T17 → T18 → T22

## Mental Model
Read `.memory/CONTEXT.md` — key terms for this workstream:
- **Skill (refined)** — on-demand knowledge, <100 lines, `metadata` block for custom fields
- **Dual-run evaluation** — with/without skill comparison, delta = skill's value
- **Context loading taxonomy** — eager/lazy/progressive (how content reaches agents)
- **Invocation control** — `metadata.invocation`: user-only, agent-only, both
- **Composition format** — YAML manifests referencing atomics by name

## Constraints
- `resources/` is read-only (symlinked reference repos)
- Skills must use `metadata` block for custom fields (not top-level)
- Proof harness requires `yq` (installed at `~/.local/bin/yq`)
- kiro-cli 2.3.0, Claude Code 2.1.148 (both authenticated)
- Judge config: 1 judge trial, 3 agent trials (S4 finding)

## What Was Tried
- Nothing failed this session. All implementation succeeded on first attempt.
- Proof harness abstract fixtures work across both tools from same definition.

## Current State
- 5 skills in `atomics/skills/`: verification-protocol, five-whys, eval-criteria, situation-routing, handoff
- Proof harness passes 4 proofs on kiro-cli AND Claude Code
- Generator architecture reverse-engineered (`.scratch/generator-architecture.md`)
- Handoff/read-handoff prompts updated to match actual workflow
- GitHub: smileynet/crew-research (private), #1 closed, #2 open (deferred)
- No unresolved design questions

## Next Steps
1. T9: Implement eval harness (judge invocation + scoring pipeline + results storage)
2. T10: Add dual-run mode (with/without skill baseline comparison)
3. T16: Run dual-run evals on the 5 authored skills (prove they add value)
4. T8: Implement cross-link lint script (`tools/lint/check-crosslinks.sh`)

## Evidence
- Spike findings: `docs/spike-findings.md`
- Generator internals: `.scratch/generator-architecture.md`
- Claude Code architecture: `.scratch/claude-code-architecture.md`
- Proof results: `tools/proofs/results/{kiro-cli,claude-code}/`
- All specs: `docs/specs/*.md`

## Available Prompts
`@handoff`, `@read-handoff`, `@grill-with-docs`, `@research-prior-art`
