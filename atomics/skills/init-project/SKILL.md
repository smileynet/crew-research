---
name: init-project
description: "Scaffold project conventions. Creates .memory, .scratch, AGENTS.md, .crew-config.yaml. Use when starting a new project or when project structure is missing."
metadata:
  type: process
  invocation: user-only
  practice: null
---

# Initialize Project

Scaffold project conventions. Skills and prompts come from ~/.kiro/ (global). This creates the project-specific structure.

## Check First

If `.memory/` and `AGENTS.md` already exist, this project is already scaffolded. Ask if the user wants to update/verify instead (suggest `@project-audit`).

## Scaffold

Create these if they don't exist:

1. **`.scratch/`** — ephemeral working notes
2. **`.memory/CONTEXT.md`** — project glossary (empty template)
3. **`.memory/adr/`** — architecture decision records
4. **`tools/`** — project scripts and automation (validation, extraction, deployment)
5. **`AGENTS.md`** — project reference (project layout, commands, prompts)
6. **`.crew-config.yaml`** — detected build/test/lint commands
7. **`.gitignore`** entries — `.scratch/` and `references/`
8. **`references/`** — directory for reference repos

## Auto-detect

- Check for `package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`
- Extract build/test/lint commands
- Set language in `.crew-config.yaml`

## Process Existing Decisions

Check for existing decisions files (`decisions.md`, `DECISIONS.md`, `docs/decisions.md`, `.memory/decisions.md`):

1. **Read** each decisions file
2. **Evaluate** each decision for ADR fitness (hard to reverse? surprising without context? real trade-off?)
3. **Promote** qualifying decisions → `.memory/adr/NNNN-slug.md`
4. **Extract terms** — scan for domain terminology and add to `.memory/CONTEXT.md`
5. **Report** what was processed and what was left as-is (lightweight decisions stay in place)

## Detect References Directory

Check for both `references/` and `resources/` directories:
- If `resources/` exists and is gitignored → rename to `references/`, update `.gitignore`
- If both exist → ask user which contains reference repos, consolidate to `references/`
- Ensure `references/` is in `.gitignore`

## AGENTS.md Content

Include: project layout, detected commands, available prompts list, references section, customization notes.

## After Scaffolding

Tell the user:
- Skills/prompts are available globally from `~/.kiro/`
- Add project-specific steering to `.kiro/steering/` if needed
- Add project terms to `.memory/CONTEXT.md` as they emerge
- Use `@grill-with-docs` to stress-test plans before building
