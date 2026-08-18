# Knowledge Management

Rules for organizing project knowledge. Apply these when working in crew-research or any project initialized with crew-research conventions.

## File Placement

| Content | Location | Tracked? |
|---------|----------|:--------:|
| Project glossary (terms only) | `.memory/CONTEXT.md` | Yes |
| Architecture decisions | `.memory/adr/NNNN-slug.md` | Yes |
| Lasting reference | `.memory/specs/` | Yes |
| Operational gotchas & environment facts | `AGENTS.md` Constraints section | Yes |
| Current session state | `.scratch/HANDOFF.md` | Yes |
| Working notes | `.scratch/` | No (gitignored) |
| User-facing docs | `docs/` | Yes |

## Rules

- **One source of truth per fact.** Don't duplicate across files.
- **CONTEXT.md is a glossary only.** Gate: "could two people mean different things by this word?" If yes → add. If no → it goes elsewhere (AGENTS.md, spec, or ADR). Format: term + one-sentence definition + avoid.
- **ADRs only when all three**: hard to reverse, surprising without context, real trade-off.
- **Gotchas go in AGENTS.md.** Operational surprises, workarounds, environment quirks → Constraints section.
- **Scratch is ephemeral.** Promote to .memory/ or delete. Never accumulate.
- **Update HANDOFF.md every session.** New supersedes old.
