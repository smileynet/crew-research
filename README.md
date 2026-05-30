# crew-research

Portable skills and workflows for AI coding tools. Deploy globally, scaffold per-project.

## Quick Start

```bash
# One-time: deploy skills/steering globally
mise run init -- --global --tier basic

# Per-project: scaffold workspace conventions
mise run init -- --project ~/your-project

# Start using (skills available immediately)
cd ~/your-project && kiro-cli chat
```

## How It Works

**Global (`~/.kiro/`)** — skills and steering deploy once and are available in every project:
- `~/.kiro/steering/` — always-on rules (code hygiene, verification, conventions)
- `~/.kiro/skills/` — on-demand knowledge + user-invocable workflows (activates when relevant, invocable via `/name`)

**Per-project** — workspace structure scaffolded for each project:
- `.memory/CONTEXT.md` — project glossary
- `.scratch/` — ephemeral notes
- `AGENTS.md` — project reference
- `.crew-config.yaml` — build/test/lint commands

**Project overrides** — add project-specific rules to `.kiro/steering/` or `.kiro/skills/` locally.

## Tiers

**basic** — Core project lifecycle (22 skills + 3 steering):
setup → design → plan → build → verify → commit → deliver → hand off → cleanup.

**full** — Everything in basic + specialized skills, multi-agent crews, research tools, creative writing (47 skills + 3 steering).

```bash
mise run catalog    # see all available skills
```

## Key Skills (user-invocable)

- `/grill-with-docs` — Stress-test a plan before building
- `/handoff` / `/read-handoff` — Session continuity
- `/plan-prereqs` — Identify pre-work before building
- `/workspace-cleanup` — Periodic housekeeping
- `/study-reference` — Deep-dive a reference repo
- `/cheatsheet` — Quick reference

## Requirements

- `kiro-cli` 2.3.0+
- `yq` (YAML processing)
- `mise` (task runner, optional)

See [SETUP.md](SETUP.md) for platform-specific install instructions.

## Validation

```bash
mise run validate-deployment    # end-to-end test
mise run doctor -- --project ~/your-project
```
