---
created_at: 2026-05-25T09:09:00-07:00
base_commit: fefdb69
handoff_key: feature-complete
---

# Handoff

## Objective
System is feature-complete. Next: run remaining coverage experiments, eat our own dogfood with `@workspace-cleanup`, and use crew-test for sustained real work.

## Task Graph Position
- **Complete:** All phases 1-10. Critical path done. 8 crews, 9 archetypes, 34 skills, full toolchain.
- **Open issues:** #3 (remaining experiments: task diversity, compression, activation sweep), #2 (issue automation — deferred design)
- **Next:** Coverage experiments (E7, E10, E14) or real-world usage of crew-test.

## Mental Model
- **Skill focusing effect** — more skills = fewer tokens (counterintuitive, confirmed in Phase 7)
- **Activation bottleneck** — skills work when loaded but kiro-cli's matching is unreliable; distinctive trigger words survive, generic phrases don't
- **Document placement rule** — default .scratch/.memory; docs/ only when deliberately requested for user-facing publication
- **Context isolation model** — orchestrator (bash), subject (kiro-cli + skills), judge (kiro-cli, empty dir) — no shared context

## Constraints
- `resources/` is read-only (gitignored, rehydrate from .memory/resources.md)
- Skills must be <100 lines SKILL.md
- Generator requires `yq` (~/.local/bin/yq)
- kiro-cli 2.3.0 authenticated
- Param substitution uses awk frontmatter extraction (yq can't parse full SKILL.md)

## What Was Tried
- Nothing failed this session. All implementation succeeded.
- Generator prompt deployment had a bug (yq on full markdown) — fixed with awk extraction.
- Init script had ordering issue (detection after AGENTS.md creation) — fixed.

## Current State
- `~/code/crew-test` deployed with 7 agents, 31 skills, 6 prompts, 3 steering files
- New skills this session: ux-walkthrough, fiction-craft (+ references), world-building, script-authoring, reference-exploration, research-output, cheatsheet, workspace-cleanup, read-handoff, init-project
- Experiments ran: token-efficiency, skill-interference, process-tracing (Phase 7), E8/E9/E11/E12/E13 (Phase 10)
- Findings: `docs/practices/phase-7-experiment-results.md`, `docs/practices/phase-10-e2e-results.md`
- GitHub: all pushed to smileynet/crew-research

## Next Steps
1. Run `@workspace-cleanup` on crew-research itself (dogfood)
2. Run E7 (activation sweep for 17 new skills)
3. Run E10 (eager-context effectiveness)
4. Use crew-test for sustained real work to surface integration issues
5. Close #3 when experiments complete

## Evidence
- Phase 7 results: `docs/practices/phase-7-experiment-results.md`
- Phase 10 E2E: `docs/practices/phase-10-e2e-results.md`
- Experiment coverage gaps: `docs/practices/experiment-coverage-proposal.md`
- Screenwriting analysis: `.scratch/research/screenwriting-repo-analysis.md`
- Phase 9 spikes: `docs/practices/phase-9-proposal.md`

## Available Prompts
`@cheatsheet`, `@handoff`, `@read-handoff`, `@init-project`, `@ux-walkthrough`, `@workspace-cleanup`
