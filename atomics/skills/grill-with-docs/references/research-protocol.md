# Research Protocol — Full Detail

Companion to grill-with-docs SKILL.md. The gates live in the skill body; this file covers what to research, how to classify options, and how to present them.

## What to research (per design question)

1. **Library/tool documentation** — how does the technology handle this? What's documented/supported? (web search → fetch docs)
2. **Prior art** — how did other projects solve this? What patterns exist?
3. **Anti-patterns** — what do maintainers warn against? (issues, post-mortems)
4. **Ecosystem health** — actively maintained? Known issues?

## How to classify options

Score each option along:

- **Supported vs. incidental** — documented feature or undocumented side effect?
- **Scoped vs. global** — affects only this subsystem, or the whole architecture?
- **Reversible vs. sticky** — how easy to change later?
- **Portable vs. environment-specific** — works everywhere, or only specific OS/tooling?

## How to present

| Option | Pro | Con | Source |
|--------|-----|-----|--------|
| A | ... | ... | docs.rs/crate: "feature X is supported..." |
| B | ... | ... | Anti-pattern per maintainer: github.com/... |

State confidence per option:

- **High** — documented behavior, verified in official docs
- **Medium** — works but undocumented (incidental support)
- **Low** — inferred from source code or single community report

## When to skip research

- The question is about internal project conventions (just read the codebase)
- The answer is in existing project docs or decision records
- The question is answerable from docs you already fetched
