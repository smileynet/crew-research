# crew-research

Portable skills and workflows that make AI coding assistants (kiro-cli) more effective at every stage of development — from planning through delivery.

## Quick Start

**Prerequisites:** [kiro-cli](https://github.com/smileynet/kiro-cli) 2.3.0+, [yq](https://github.com/mikefarah/yq), [mise](https://mise.jdx.dev/) (optional but recommended)

```bash
# One-time: deploy skills/steering globally
mise run init -- --global --tier basic

# Per-project: scaffold workspace conventions
mise run init -- --project ~/your-project

# Start using (skills activate automatically)
cd ~/your-project && kiro-cli chat
```

After init, skills activate based on what you're doing. Invoke workflows directly with `/name`:

```
/grill-with-docs     # stress-test a plan before building
/handoff             # end-of-session state capture
/read-handoff        # start-of-session orientation
/plan-prereqs        # identify pre-work before building
/workspace-cleanup   # periodic housekeeping
/study-reference     # deep-dive a reference repo
/cheatsheet          # quick reference for what's available
```

## How It Works

**Global (`~/.kiro/`)** — skills and steering deploy once, available in every project:
- `~/.kiro/steering/` — always-on rules (code hygiene, verification, conventions)
- `~/.kiro/skills/` — on-demand knowledge (activates when relevant)

**Per-project** — workspace structure scaffolded for each project:
- `.memory/CONTEXT.md` — project glossary
- `.scratch/` — ephemeral working notes
- `AGENTS.md` — agent-facing project reference
- `.crew-config.yaml` — build/test/lint commands

**Project overrides** — add project-specific rules to `.kiro/steering/` or `.kiro/skills/` locally.

## Tiers

| Tier | Skills | Covers |
|------|--------|--------|
| **basic** | 22 skills + 3 steering | setup → design → plan → build → verify → commit → deliver → hand off → cleanup |
| **full** | 47 skills + 3 steering | Everything in basic + multi-agent crews, research tools, creative writing |

```bash
mise run catalog    # see all available skills
```

If unsure, start with **basic**. It covers the full development lifecycle.

## Validation

```bash
mise run validate-deployment    # end-to-end test
mise run doctor -- --project ~/your-project
```

## Development

```bash
mise run validate       # validate compositions + cross-links
mise run eval           # run all evals
mise run lint           # check cross-links
```

## License

[MIT](LICENSE)
