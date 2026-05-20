---
created_at: 2026-05-20T06:29:00-07:00
base_commit: 42d04e8
handoff_key: crew-research-bootstrap
---

# Handoff

## Objective
Begin spike S1 (kiro-cli prompt/skill invocation parity), then proceed through S2-S3 in sequence. These three spikes de-risk the frontmatter schema before any module authoring begins.

## Constraints
- Do not modify files in `resources/` (read-only symlinks)
- Spikes S1-S3 must resolve before T1 (scaffold monorepo structure)
- S4 and S5 can run in parallel with Phase 1 implementation
- All decisions go in `.memory/CONTEXT.md`; ADRs only for hard-to-reverse choices

## Prior Decisions
- All design decisions captured in `.memory/CONTEXT.md` (20+ terms resolved)
- 8 feature specs written in `docs/specs/`
- Task graph with 5 spikes + 25 tasks in `docs/task-graph.md`
- Detailed experiment plans in `docs/spike-plans.md`
- Repo: `smileynet/crew-research` (private, GitHub)
- Labels: design, tooling, content, bug
- Issue templates: design-question, new-module, bug-report

## Current State
- Repo scaffolded with: `.memory/`, `.scratch/`, `docs/`, `resources/`, `.kiro/prompts/`, `.github/`
- No `atomics/`, `compositions/`, or `tools/` directories yet (created in T1 after spikes)
- 2 open issues: #1 (per-project customization), #2 (issue management automation)
- All specs are design docs only — no implementation code exists yet

## Next Steps
1. Run spike S1: create test workspace, deploy skill + prompt fixtures, run 5 test cases against kiro-cli
2. Record results in `.scratch/spike-s1-results.md`
3. If S1 passes: confirm `invocation: user-only` model works, update CONTEXT.md
4. If S1 fails: document which features are prompt-only, update generator spec
5. Proceed to S2 (Claude Code frontmatter tolerance)
6. Proceed to S3 (Codex/Pi — may defer if no access)

## Evidence
- Spike experiment plans: `docs/spike-plans.md`
- Task graph: `docs/task-graph.md`
- Feature specs: `docs/specs/*.md`
- Glossary: `.memory/CONTEXT.md`
- Prior art: `resources/agent-crews/`, `resources/best_practices/`, `resources/ai-references/`
