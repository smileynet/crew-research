# Knowledge Management

Rules for organizing project knowledge. Apply these when working in crew-research or any project initialized with crew-research conventions.

## File Placement

| Content | Location | Tracked? |
|---------|----------|:--------:|
| Project glossary | `.memory/CONTEXT.md` | Yes |
| Architecture decisions | `.memory/adr/NNNN-slug.md` | Yes |
| Lasting reference | `.memory/specs/` | Yes |
| Current session state | `.scratch/HANDOFF.md` | Yes |
| Working notes | `.scratch/` | No (gitignored) |
| User-facing docs | `docs/` | Yes |

## Rules

- **One source of truth per fact.** Don't duplicate across files.
- **CONTEXT.md is a glossary only.** Term + definition + avoid. No implementation details.
- **ADRs only when all three**: hard to reverse, surprising without context, real trade-off.
- **Scratch is ephemeral.** Promote to .memory/ or delete. Never accumulate.
- **Update HANDOFF.md every session.** New supersedes old.
