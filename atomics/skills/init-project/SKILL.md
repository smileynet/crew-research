---
name: init-project
description: "Initialize a new project with crew-research workspace conventions. Sets up .scratch, .memory, CONTEXT.md, .crew-config.yaml, and generates the agent deployment."
metadata:
  type: process
  invocation: user-only
  practice: null
---

# Initialize Project

Set up a new project with crew-research workspace conventions.

## Workflow

1. **Gather info** — ask the user:
   - Which crews do they want? (development, bugfix, research, documentation, review, content, infrastructure, onboarding)
   - What tool? (kiro-cli or claude-code)
   - Confirm the project directory (default: current working directory)

2. **Detect environment** — check for:
   - `package.json` → Node/TypeScript (npm/pnpm commands)
   - `Cargo.toml` → Rust (cargo commands)
   - `pyproject.toml` → Python (pytest/ruff)
   - `go.mod` → Go (go build/test)

3. **Run init script**:
   ```bash
   tools/generator/init.sh --project <path> --crews <selected> --tool <tool>
   ```

4. **Verify results** — confirm these exist:
   - [ ] `.scratch/` directory created (gitignored)
   - [ ] `.memory/CONTEXT.md` exists with glossary template
   - [ ] `.memory/resources.md` exists with rehydration template
   - [ ] `resources/` directory created (gitignored)
   - [ ] `docs/` directory created (user-facing only)
   - [ ] `AGENTS.md` exists with workspace map and commands
   - [ ] `.crew-config.yaml` has correct crews and verification commands
   - [ ] Agent configs generated (`.kiro/agents/` or `.claude/agents/`)
   - [ ] Skills deployed
   - [ ] `.gitignore` includes `.scratch/` and `resources/`

5. **Report** — show the user what was created and next steps.

## Available Crews

| Crew | Best For |
|------|----------|
| development | Features, refactoring, general code work |
| bugfix | Diagnose → fix → verify bugs |
| research | Investigation and knowledge capture |
| documentation | Project docs, guides, references |
| review | Code review, security audit (read-only) |
| content | Presentations, tutorials, workshops |
| infrastructure | Deploy, provision, CI/CD |
| onboarding | New contributor orientation |

## Default Recommendation

For most projects: `development,bugfix` is a good starting point.
Add `documentation` if the project has users. Add `infrastructure` if it deploys.
