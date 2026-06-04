# crew-research

Portable skills and workflows that make AI coding assistants (kiro-cli) more effective at every stage of development — from planning through delivery.

## What It Does

You install a set of behavioral skills into your project. Your AI assistant automatically gets better at:

- **Planning** — structured design thinking, assumption tracking, pre-work identification
- **Building** — code review standards, testing guidance, architecture decisions
- **Verifying** — automated checks before reporting done, scope enforcement
- **Delivering** — commit discipline, PR standards, deployment safety
- **Continuity** — session handoffs, project glossary, workspace hygiene

Skills activate automatically based on what you're doing. No configuration needed after setup.

## Quick Start

**Prerequisites:** [kiro-cli](https://github.com/smileynet/kiro-cli) 2.3.0+, [yq](https://github.com/mikefarah/yq), [mise](https://mise.jdx.dev/) (optional but recommended)

```bash
# Install skills globally (one-time)
mise run init -- --global --tier basic

# Set up a project
mise run init -- --project ~/your-project

# Start working
cd ~/your-project && kiro-cli chat
```

That's it. Skills are now active.

## What You Can Do

After setup, these workflows are available in any kiro-cli session:

| Command | What it does |
|---------|-------------|
| `/grill-with-docs` | Stress-test a plan with evidence-backed questions before you build |
| `/handoff` | Capture session state so the next session can pick up where you left off |
| `/read-handoff` | Orient at the start of a session — read prior state and continue |
| `/plan-prereqs` | Identify research, spikes, and tooling needed before implementing |
| `/workspace-cleanup` | Consolidate notes, update glossary, remove stale artifacts |
| `/study-reference` | Deep-dive a reference repo and extract patterns |
| `/cheatsheet` | Quick reference for everything available |

You don't need to memorize these — `/cheatsheet` lists them all.

## Tiers

| Tier | What you get | Best for |
|------|-------------|----------|
| **basic** | 22 skills + 3 always-on rules | Solo developers, most projects |
| **full** | 47 skills + 3 always-on rules | Multi-agent workflows, research, creative writing |

Start with **basic**. Upgrade to full later if you need specialized workflows.

```bash
mise run catalog    # browse all available skills
```

## How It Improves Your Workflow

**Before:** You ask the AI to build something. It dives straight in, skips verification, produces verbose code, loses context between sessions.

**After:** The AI automatically:
- Asks clarifying questions before building (planning skills)
- Verifies its work before reporting done (verification protocol)
- Produces concise, well-structured code (code hygiene rules)
- Captures state at session end so the next session can continue (handoff)
- Tracks project terminology so it uses the right words (glossary)

None of this requires you to change how you work. You just chat normally.

## Troubleshooting

```bash
mise run doctor -- --project ~/your-project    # diagnose issues
```

| Problem | Fix |
|---------|-----|
| Skills not activating | Run `mise run doctor`; check that `.kiro/skills/` has files |
| Want to add more skills | Re-run init with `--tier full` |
| A rule feels too strict | Remove the specific file from `.kiro/steering/` |
| Starting fresh | Delete `.kiro/` and re-run init |

## License

[MIT](LICENSE)
