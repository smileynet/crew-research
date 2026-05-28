---
name: init-project
description: "Initialize a new project with crew-research workspace conventions. Sets up .scratch, .memory, CONTEXT.md, steering, skills, and prompts."
metadata:
  type: process
  invocation: user-only
  practice: null
---

# Initialize Project

Set up this project with crew-research conventions.

## If already initialized (`.kiro/` exists)

This project already has crew-research deployed. To update/sync:
```bash
# From the crew-research repo:
mise run init -- --project $(pwd) --tier <basic|full> --tool kiro-cli
```
This updates skills (preserves your customizations in references/ and prompts).

## If not initialized

Guide the user through setup:

### 1. Choose tier

- **basic** — Core project lifecycle (11 skills + 4 steering + 8 prompts). Covers: setup → design → plan → build → verify → commit → deliver → hand off → cleanup.
- **full** — Everything in basic + specialized skills (architecture, research, creative), multi-agent crews (7 agents), and additional prompts.

Recommend **basic** unless the user needs multi-agent delegation or specialized activities.

### 2. Run init

```bash
# From the crew-research repo:
mise run init -- --project <this-project-path> --tier <chosen-tier> --tool kiro-cli
```

### 3. After init

- Review `.crew-config.yaml` — verify build/test/lint commands are correct
- Add project terms to `.memory/CONTEXT.md` as they emerge
- Start working — skills activate automatically

### 4. Key prompts available after setup

- `@grill-with-docs` — stress-test a plan
- `@handoff` / `@read-handoff` — session continuity
- `@plan-prereqs` — identify pre-work before building
- `@workspace-cleanup` — periodic consolidation
- `@project-audit` — check if deployment matches reality
