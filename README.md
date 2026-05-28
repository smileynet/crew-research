# crew-research

Portable skills and workflows for AI coding tools. Install a tier of skills into your project to improve agent behavior across the full development lifecycle.

## Quick Start

```bash
# Initialize your project with the basic tier
mise run init -- --project ~/your-project --tier basic --tool kiro-cli

# Verify the deployment
mise run doctor -- --project ~/your-project

# Start using
cd ~/your-project && kiro-cli chat
```

## Tiers

**basic** — Core project lifecycle (11 skills + 2 steering + 5 prompts):
setup → design → plan → build → verify → commit → deliver → hand off → cleanup.

**full** — Everything in basic + specialized skills, multi-agent crews, research tools, creative writing.

```bash
# See all available skills
mise run catalog
```

## What Gets Deployed

```
your-project/
├── .kiro/
│   ├── steering/        # Always-on rules (code hygiene, verification, conventions)
│   ├── skills/          # On-demand knowledge (activates when relevant)
│   └── prompts/         # User-invoked workflows (@handoff, @grill-with-docs, etc.)
├── .memory/
│   └── CONTEXT.md       # Project glossary (grows as you work)
├── .scratch/            # Ephemeral notes (gitignored)
└── AGENTS.md            # Agent-facing project reference
```

## Key Prompts

- `@grill-with-docs` — Stress-test a plan before building
- `@handoff` / `@read-handoff` — Session continuity
- `@workspace-cleanup` — Periodic housekeeping

## Requirements

- `kiro-cli` 2.3.0+
- `yq` (YAML processing)
- `mise` (task runner, optional — scripts work standalone)

## Customizing

After init, customize for your project:
- Edit `.crew-config.yaml` for build/test/lint commands
- Remove unwanted skills: delete from `.kiro/skills/`
- Remove unwanted steering: delete from `.kiro/steering/`
- Add project context: create `.kiro/skills/{name}/references/project-notes.md`

## Development

```bash
mise run validate          # validate compositions + cross-links
mise run eval              # run all evals
mise run eval:activation   # test skill activation
mise run lint              # check cross-links
```

## Documentation

- `docs/specs/distribution-design.md` — tier design and UX
- `docs/practices/` — experiment results and research findings
- `tools/evals/README.md` — eval harness usage
