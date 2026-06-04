# AGENTS.md

## Project

crew-research — Portable skills and workflows for AI coding tools. Users install a tier of skills into their project to improve agent behavior across the full development lifecycle.

## How Users Set Up

When a user wants to use crew-research in their project, guide them through:

### 1. Choose a tier

- **basic** — Core project lifecycle (22 skills + 3 steering). Covers: setup → design → plan → build → verify → commit → deliver → hand off → cleanup.
- **full** — Everything in basic + specialized skills, multi-agent crews, research tools, creative writing (47 skills + 3 steering).

If unsure, recommend **basic**. It covers the full workflow without overwhelming.

### 2. Initialize

```bash
mise run init -- --project ~/their-project --tier basic --tool kiro-cli
```

This deploys skills and steering to their project's `.kiro/` directory.

### 3. Verify

```bash
mise run doctor -- --project ~/their-project
```

### 4. Start using

After init, the user just runs `kiro-cli chat` in their project. Skills activate automatically based on what they're doing. User-invocable workflows are triggered with `/name`.

### Key workflows:
- `/grill-with-docs` — stress-test a plan before building
- `/handoff` / `/read-handoff` — session continuity
- `/workspace-cleanup` — periodic housekeeping
- `/plan-prereqs` — identify pre-work before building
- `/cheatsheet` — quick reference for what's available

## Workspace (crew-research internal)

- `.memory/` — Durable artifacts (CONTEXT.md glossary, ADRs, specs/)
- `.scratch/` — Ephemeral artifacts (handoffs, active plans)
- `docs/` — Practices, eval results (human-readable research)
- `atomics/` — Atomic modules (skills, eager-context, eval-definitions)
- `compositions/` — Compositions (agent-archetypes, crew-patterns, tiers, workspace-conventions)
- `tools/` — Generator, eval harness, proof harness, lint, session analyzer
- `references/` — Symlinked reference repos (read-only, gitignored)

## Commands

```bash
# User-facing
mise run init -- --project <path> --tier basic --tool kiro-cli
mise run catalog                                # list available skills
mise run doctor -- --project <path>             # health check

# Development
mise run validate                               # validate compositions + cross-links
mise run generate -- --tool kiro-cli --output ./deploy
mise run eval                                   # run all evals
mise run eval:activation                        # test skill activation
mise run eval:qualitative -- <name>             # keyword-based experiment
mise run lint                                   # check cross-links
mise run session:parse                          # parse session transcripts
```

## Key Conventions

- **Glossary**: `.memory/CONTEXT.md` — update immediately when terms are resolved
- **ADRs**: `.memory/adr/NNNN-slug.md` — only for hard-to-reverse decisions
- **Skills**: `atomics/skills/{slug}/SKILL.md` — agent-loadable modules (<100 lines)
- **Tiers**: `compositions/tiers/{name}.yaml` — define what ships in each tier
- **Cross-links**: practices declare `skills:` in frontmatter; skills declare `practice:`

## Do Not

- Modify files in `references/` (symlinked read-only reference repos)
- Put implementation details in `.memory/CONTEXT.md` (glossary only)
- Create skills over 100 lines without justification
- Mix human docs and agent-loadable content in the same directory
