# AGENTS.md

## Project

crew-research — Monorepo of independent tools for building consistent, reusable behavioral modules across AI coding tools.

## Workspace

- `.memory/` — Durable artifacts (CONTEXT.md glossary, ADRs)
- `.scratch/` — Ephemeral artifacts (handoffs, scratch notes)
- `docs/` — Plan, inventory, practices (human-readable)
- `atomics/` — Atomic modules (skills, steering, prompts, eval-definitions)
- `compositions/` — Compositions (agent-archetypes, crew-patterns, workspace-conventions)
- `tools/` — Proof harness, eval harness
- `resources/` — Symlinked reference repos (read-only prior art)

## Backlog

GitHub Issues on `smileynet/crew-research`. Use `gh issue create` for new items.

When filing issues:
- Title: imperative verb + what ("Design per-project customization")
- Body: Problem, Questions to Resolve, Prior Art, Acceptance Criteria
- Use issues for anything deferred, out-of-scope, or needing future design work

Labels (exclusive — one per issue):
- `design` — needs design decisions before implementation
- `tooling` — proof harness, eval harness, lint scripts
- `content` — new/updated skills, practices, protocols
- `bug` — something broken

Issue templates enforce structure. Don't file issues for work you can finish in one sitting.

## Key Conventions

- **Glossary**: `.memory/CONTEXT.md` — update immediately when terms are resolved
- **ADRs**: `.memory/adr/NNNN-slug.md` — only for hard-to-reverse decisions with real trade-offs
- **Practices**: `docs/practices/{slug}.md` — human research docs
- **Skills**: `atomics/skills/{slug}/SKILL.md` — agent-loadable modules (<100 lines)
- **Cross-links**: practices declare `skills:` in frontmatter; skills declare `practice:` in frontmatter

## Prompts

- `@grill-with-docs` — Design interrogation session
- `@research-prior-art` — Research reference repos to inform a decision

## Commands

```bash
gh issue list --repo smileynet/crew-research    # view backlog
gh issue create --repo smileynet/crew-research  # file new item
```

## Do Not

- Modify files in `resources/` (symlinked read-only reference repos)
- Put implementation details in `.memory/CONTEXT.md` (glossary only)
- Create skills over 100 lines without justification
- Mix human docs and agent-loadable content in the same directory
