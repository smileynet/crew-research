# AGENTS.md

## Project

crew-research — Portable skills and workflows for AI coding tools. Users install a tier of skills into their project to improve agent behavior across the full development lifecycle.

## How Users Set Up

When a user wants to use crew-research in their project, guide them through:

### 1. Choose a tier

- **basic** — Core project lifecycle (11 skills + 2 steering + 5 prompts). Covers: setup → design → plan → build → verify → commit → deliver → hand off → cleanup.
- **full** — Everything in basic + specialized skills, multi-agent crews, research tools, creative writing.

If unsure, recommend **basic**. It covers the full workflow without overwhelming.

### 2. Initialize

```bash
# From the crew-research repo:
mise run init -- --project ~/their-project --tier basic --tool kiro-cli
```

This deploys skills, steering, and prompts to their project's `.kiro/` directory.

### 3. Verify

```bash
mise run doctor -- --project ~/their-project
```

### 4. Start using

After init, the user just runs `kiro-cli chat` in their project. Skills activate automatically based on what they're doing. Prompts are invoked with `@name`.

### Key prompts to teach users:
- `@grill-with-docs` — stress-test a plan before building
- `@handoff` / `@read-handoff` — session continuity
- `@workspace-cleanup` — periodic housekeeping
- `@init-project` — bootstrap a new project

## Workspace (crew-research internal)

- `.memory/` — Durable artifacts (CONTEXT.md glossary, ADRs, specs/)
- `.scratch/` — Ephemeral artifacts (handoffs only)
- `docs/` — Plan, practices, specs (human-readable research)
- `atomics/` — Atomic modules (skills, eager-context, eval-definitions)
- `compositions/` — Compositions (agent-archetypes, crew-patterns, tiers, workspace-conventions)
- `tools/` — Generator, eval harness, proof harness, lint
- `resources/` — Symlinked reference repos (read-only)

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
mise run lint                                   # check cross-links
```

## Key Conventions

- **Glossary**: `.memory/CONTEXT.md` — update immediately when terms are resolved
- **ADRs**: `.memory/adr/NNNN-slug.md` — only for hard-to-reverse decisions
- **Skills**: `atomics/skills/{slug}/SKILL.md` — agent-loadable modules (<100 lines)
- **Tiers**: `compositions/tiers/{name}.yaml` — define what ships in each tier
- **Cross-links**: practices declare `skills:` in frontmatter; skills declare `practice:`

## Prompts

- `@grill-with-docs` — Design interrogation session
- `@research-prior-art` — Research reference repos to inform a decision
- `@handoff` — End-of-session handoff
- `@read-handoff` — Start-of-session orientation

## Do Not

- Modify files in `resources/` (symlinked read-only reference repos)
- Put implementation details in `.memory/CONTEXT.md` (glossary only)
- Create skills over 100 lines without justification
- Mix human docs and agent-loadable content in the same directory
