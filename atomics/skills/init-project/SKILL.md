---
name: init-project
description: "Scaffold workspace conventions for this project. Creates .memory, .scratch, AGENTS.md, .crew-config.yaml. Use when starting a new project or when workspace structure is missing."
metadata:
  type: process
  invocation: user-only
  practice: null
---

# Initialize Project Workspace

Scaffold workspace conventions for this project. Skills and prompts come from ~/.kiro/ (global). This creates the project-specific structure.

## Check First

If `.memory/` and `AGENTS.md` already exist, this project is already scaffolded. Ask if the user wants to update/verify instead (suggest `@project-audit`).

## Scaffold

Create these if they don't exist:

1. **`.scratch/`** — ephemeral working notes
2. **`.memory/CONTEXT.md`** — project glossary (empty template)
3. **`.memory/adr/`** — architecture decision records
4. **`AGENTS.md`** — project reference (workspace layout, commands, prompts)
5. **`.crew-config.yaml`** — detected build/test/lint commands
6. **`.gitignore`** entries — `.scratch/` and `resources/`
7. **`resources/`** — directory for reference repos

## Auto-detect

- Check for `package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`
- Extract build/test/lint commands
- Set language in `.crew-config.yaml`

## AGENTS.md Content

Include: workspace layout, detected commands, available prompts list, references section, customization notes.

## After Scaffolding

Tell the user:
- Skills/prompts are available globally from `~/.kiro/`
- Add project-specific steering to `.kiro/steering/` if needed
- Add project terms to `.memory/CONTEXT.md` as they emerge
- Use `@grill-with-docs` to stress-test plans before building
