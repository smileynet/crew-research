# Cross-Tool Capability Comparison: kiro-cli vs codex vs agy

**Date:** 2026-06-18
**Tool versions:** kiro-cli 2.7.1, codex-cli 0.140.0, agy 1.0.9
**Models:** Claude (kiro-cli), GPT-5.5 (codex), Gemini (agy)
**Method:** LLM-as-judge (Claude Sonnet 4.6), 2 trials per task, defu (~2k LOC) and hono (~15k LOC) fixtures

## Summary

All three tools perform competitively on small projects. Differences emerge at scale: kiro-cli degrades least, codex collapses on planning in larger codebases, agy is capable but timeout-sensitive.

## Results

### Small project (defu, ~2k LOC)

| Tool | Overall | Planning | Prose | Code |
|------|---------|----------|-------|------|
| kiro-cli | 4.00 | 4.0 | 3.5 | 4.5 |
| codex | 4.00 | 4.5 | 2.5 | 5.0 |
| agy | 4.33 | 4.0 | 4.0 | 5.0 |

### Large project (hono, ~15k LOC)

| Tool | Overall | Planning | Prose | Code |
|------|---------|----------|-------|------|
| kiro-cli | 3.50 | 4.0 | 4.0 | 2.5 |
| codex | 2.33 | 0.0 | 4.0 | 3.0 |
| agy | 3.16 | 4.0 | 3.0 | 2.5 |

### Degradation (small → large)

| Tool | Drop | Primary failure mode |
|------|------|---------------------|
| kiro-cli | -0.50 | Code complexity (not navigation) |
| codex | -1.67 | Planning collapse — can't navigate before timeout |
| agy | -1.17 | Code + prose — exploration burns budget |

## Behavioral Profiles

### kiro-cli (Claude)
- **Strength:** Consistent. Scales to larger codebases with minimal degradation. Planning remains at 4.0 regardless of project size.
- **Weakness:** Lower ceiling on code tasks. Doesn't hit 5.0 as often as codex/agy on small projects.
- **Exploration strategy:** Targeted reads. Navigates directly to relevant files without reading git history, CI configs, or unrelated source.

### codex (GPT-5.5)
- **Strength:** Highest code quality ceiling on small projects (5.0 consistent). Strong on focused implementation tasks.
- **Weakness:** Collapses on planning in larger codebases (0.0 on both hono trials). Prose is volatile (scores 1-5 across trials).
- **Exploration strategy:** Minimal. Prefers to work from what it already knows. When the project is too large for that, it fails rather than explores.

### agy (Gemini)
- **Strength:** Highest overall score on small projects (4.33). Most consistent on prose tasks (4.0 every trial in defu). Strong code ceiling.
- **Weakness:** Exhaustive exploration burns timeout budget. In earlier runs, 50% of trials timed out at 180s. At 300s, completes reliably.
- **Exploration strategy:** Exhaustive. Reads git log, branches, .github/, README, tests before focusing on the task. Produces thorough context but at time cost.

## Task-Type Analysis

### Planning
- All tools perform equally on small projects (4.0-4.5)
- At scale: kiro-cli and agy maintain 4.0, codex drops to 0.0
- Planning requires navigation → codex's minimal-exploration approach fails when the answer isn't immediately visible

### Prose/Documentation
- Most stable across project sizes for all tools (3.0-4.0)
- Doesn't require deep codebase navigation for the tasks tested
- agy produces the most consistent quality; codex is volatile

### Code/Bug Fixes
- Universally hardest in larger projects (all tools drop to 2.0-3.0 range on hono)
- Requires: find the right file → understand context → write correct fix
- codex has highest ceiling when it finds the file (scored 4-5 when it did)
- The cors optimization task was genuinely hard — required understanding middleware lifecycle

## Operational Findings

### agy Invocation
- `--print` mode works for stdout capture in real project contexts (Issue #76 only affects empty workspaces)
- `--dangerously-skip-permissions` flag confuses the model — it interprets it as task context. Must be omitted.
- Requires 300s timeout for reliability on larger projects
- Skills deploy to `.agents/skills/{name}/SKILL.md` (shared path with codex)
- Steering goes to `AGENTS.md` (shared with codex) + `GEMINI.md` (agy-specific)

### Eval Harness Updates
- Added `--adapter agy` support: invokes via `agy --print`
- Added `--adapter codex` support: invokes via `codex exec --dangerously-bypass-approvals-and-sandbox`
- Steering deployment is adapter-aware: `.kiro/steering/` for kiro-cli, appended to `AGENTS.md` for codex/agy

## Implications for Skill Design

1. **Skills help codex most** — it needs navigation guidance that kiro-cli/agy do naturally. Research gates and self-answer gates showed +0.84 delta on codex vs +0.17 on kiro-cli.

2. **Timeout-aware tasks for agy** — agy's exploration is thorough but slow. Skills that say "focus on X, don't explore unrelated files" could reduce its exploration overhead.

3. **Planning skills should target codex at scale** — codex's planning collapse in larger projects is the biggest opportunity. A skill that forces "read the relevant source directory structure before planning" could prevent the 0-score failures.

4. **Code tasks need better fixtures** — all tools struggle with the larger-project code task. The cors optimization required finding a specific file in a large codebase AND understanding its optimization opportunity. Future evals should separate "navigation" from "implementation" to isolate the failure mode.

## Backlog

- Multi-turn eval harness — test interactive behaviors (codex dithering, agy subagent dispatch)
- Navigation-specific eval — test file-finding separately from code-writing
- Skills-at-scale eval — test whether navigation-focused skills help codex's planning collapse
- Larger fixture (bullmq, 12k LOC, different architecture) — validate findings generalize
