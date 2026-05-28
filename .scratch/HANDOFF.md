---
created_at: 2026-05-27T17:06:00-07:00
base_commit: 2ef6028
handoff_key: experiments-complete
---

# Handoff

## Objective
Run E8 (multi-agent workflow) and E9 (crew E2E). These are the last two experiments requiring full crew deployment.

## Task Graph Position
- **Complete:** E7, E10, E11, E12, E13, E14, E15, E16. Workspace cleanup. New skills (prototype-protocol, architecture-deepening, poc-workflow).
- **Open issues:** #7 (E8), #8 (E9), #2 (deferred design)
- **Next:** E8 → E9 (require full crew deployment with multiple agents)

## Mental Model
- **Activation solved**: diagrams fixed via description rewriting. ai-gen-hygiene + verification-protocol → eager-load (can't fix via description or linking).
- **Cross-skill linking disproven**: kiro-cli doesn't follow markdown links between skills in single-turn mode.
- **Skill focusing effect confirmed**: steering reduces tokens on complex tasks (18-57%).
- **Harness limitation**: single-turn `--no-interactive` can't test multi-step behaviors (verification, iterative refinement).
- **Scope boundaries work**: steering with explicit scope + "suggest handoff" is effective.
- **Research-output works**: skill shapes structured output correctly.
- **Handoff round-trip works**: @handoff → @read-handoff produces correct orientation.

## Constraints
- E8/E9 require deploying full crew system (multiple agents with routing, subagent tool)
- This means generating agent JSON from compositions and deploying to a test workspace
- The generator's `generate` command for external projects has a gap (E13 finding)
- May need to deploy from `~/code/crew-test` (already has 7 agents deployed)

## What Was Tried
- E15: 4 treatments (baseline, link, mention, companion, directive) — all failed
- E16: description rewriting fixed diagrams, worsened verification-protocol
- E10: behavioral delta inconclusive in single-turn mode

## Current State
- 38 skills, 4 prompts
- Experiments: 8 complete (E7, E10-E16), 2 remaining (E8, E9)
- Key findings captured in docs/practices/: e7, e10, e15, e16 results
- Prompts written to ~/code/project-kickoff.md and ~/code/project-cleanup.md

## Next Steps
1. Deploy crew-test workspace (or use existing ~/code/crew-test)
2. Run E8: invoke general-lead with multi-worker task, verify delegation loop
3. Run E9: invoke each crew lead with representative task

## Evidence
- docs/practices/e7-activation-sweep-results.md
- docs/practices/e10-eager-context-results.md
- docs/practices/e15-cross-skill-linking-results.md
- docs/practices/e16-description-rewriting-results.md
- tools/evals/experiments/e15-cross-skill-linking.sh
- tools/evals/experiments/eager-context-behavioral-delta.yaml
