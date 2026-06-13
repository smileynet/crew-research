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

```bash
kiro-cli chat
```

Then ask:

> Install crew-research prerequisites (kiro-cli, yq, mise)

> Deploy crew-research basic tier to ~/my-project

That's it. Skills are now active.

## Tiers

| Tier | What you get | Best for |
|------|-------------|----------|
| **basic** | 40 skills + 5 always-on rules | Active development — planning, building, reviewing, shipping |
| **full** | 52 skills + 5 always-on rules | Basic + creative writing, prototyping, agent development |

**basic** covers the full ship-code lifecycle: plan → research → build → review → test → commit → deploy → hand off. Includes architecture, diagrams, README writing, changelogs, deployment safety.

**full** adds specialist workflows: fiction/world-building, PoC/prototyping, UX walkthroughs, and meta-skills for building new skills.

Start with **basic**. Upgrade to full if you need research dispatch, prototyping workflows, or creative writing.

## Where to deploy

- **To a project** (`~/my-project`) — skills and workspace conventions are scoped to that project
- **Globally** (`--global`) — skills install to `~/.kiro/` and are available in every project

Most people deploy globally once, then scaffold per-project workspace conventions as needed.

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

## Feedback

- [Report a bug](https://github.com/smileynet/crew-research/issues/new?template=bug_report.md)
- [Request a feature](https://github.com/smileynet/crew-research/issues/new?template=feature_request.md)

## License

[MIT](LICENSE)
