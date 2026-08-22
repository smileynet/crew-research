# Crew Research

Portable markdown skills that make AI coding assistants plan before building, verify before claiming done, and remember decisions across sessions.

- **Plans before building** — asks clarifying questions, tracks assumptions
- **Verifies before reporting done** — runs checks, cites evidence
- **Remembers across sessions** — recalls past decisions, continues prior work
- **Less defensive bloat** — no single-use abstractions, no redundant checks

**Before:** AI dives straight in, skips verification, loses context between sessions.
**After:** Planning before building, evidence before "done", memory across sessions.

## What It Does

You install skills into your project. Skills are plain markdown files — they work with kiro-cli, codex, crush, and agy. One deploy command, then skills activate in every session.

| Command | What it does |
|---------|-------------|
| `/grill-with-docs` | Stress-test a plan with evidence-backed questions |
| `/handoff` | Capture session state for the next session |
| `/read-handoff` | Orient at session start — continue where you left off |
| `/plan-prereqs` | Identify research and tooling needed before building |
| `/project-cleanup` | Consolidate notes, update glossary, remove stale artifacts |
| `/study-reference` | Deep-dive a reference repo and extract patterns |
| `/cheatsheet` | Quick reference for everything available |

## Quick Start

Get skills deployed in under 2 minutes:

```bash
brew install mise yq                     # macOS (or: see docs for Linux/Windows)
curl -fsSL https://kiro.dev/install | sh # kiro-cli
mise run init -- --global --tier basic --tool kiro-cli
mise run doctor
# ✅ kiro-cli (2.18.1)
# ✅ 6 steering, 18 skills
# ✅ Healthy
```
```

That's it. Open any kiro-cli session — skills activate automatically.

## Tiers

| Tier | What you get | Best for |
|------|-------------|----------|
| **basic** | Planning, code review, testing, git, session continuity | Everyday development |
| **full** | + research, architecture, diagrams, deployment safety, docs | Full lifecycle |

Start with **basic** unless you need research, architecture, or deployment safety.

```bash
mise run catalog    # browse all available skills
```

## Extensions

Extensions add capabilities that auto-deploy when their prerequisites are met:

| Extension | What it adds | Prerequisite |
|-----------|-------------|--------------|
| `recall` | Cross-session memory — searches past decisions, imports project knowledge | `recall` CLI on PATH |
| `tkt` | Ticket management — frontier detection, dependency graphs, plan sync | `tkt` CLI on PATH |

```bash
# Install cross-session memory
cargo install --path ~/code/recall

# Install ticket management
cargo install --path ~/code/tkt

# Deploy — extensions activate automatically
mise run init -- --global --tier basic --tool kiro-cli
# Extensions: recall ✅, tkt ✅
```

Extensions auto-detect. To skip: `--skip-extension recall`.

## Multi-Tool Deployment

Skills are tool-agnostic. The `--tool` flag controls where files land:

```bash
mise run init -- --global --tier basic --tool kiro-cli  # ~/.kiro/skills/
mise run init -- --global --tier basic --tool codex     # ~/.agents/skills/
mise run init -- --global --tier basic --tool agy       # ~/.gemini/antigravity-cli/skills/
mise run init -- --global --tier basic --tool crush     # ~/.agents/skills/
mise run init -- --global --tier basic --tool opencode  # ~/.config/opencode/skills/
```

Deploy to multiple tools if you switch between them.

## How It Works

```
┌─────────────────────────────────────────────────────┐
│  Skills — "How to act"                              │
│  Protocols, reasoning modes, verification gates     │
├─────────────────────────────────────────────────────┤
│  Memory — "What happened"                           │
│  Decisions, lessons, preferences across sessions    │
├─────────────────────────────────────────────────────┤
│  Knowledge — "What exists"                          │
│  Glossary, ADRs, specs, project references          │
└─────────────────────────────────────────────────────┘
```

**Skills** tell the agent what to do. **Memory** gives it recall of what was. **Knowledge** describes what is. All three are plain files — portable, git-native, tool-agnostic.

## Troubleshooting

```bash
mise run doctor -- --project ~/your-project
```

| Problem | Fix |
|---------|-----|
| Skills not activating | `mise run doctor`; check `.kiro/skills/` has files |
| Want more skills | Re-run init with `--tier full` |
| A rule feels too strict | Remove the file from `.kiro/steering/` |
| Starting fresh | Delete `.kiro/` and re-run init |
| Recall not finding things | `recall import .memory/ --wing project_name` |

## Acknowledgments

**[MemPalace](https://github.com/MemPalace/mempalace)** — The recall extension adapts MemPalace's architecture as a purpose-built Rust implementation. SQLite + FTS5 + local embeddings, no server dependencies.

**[Google OKF](https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf)** — OKF's "nouns, not verbs" insight shapes how `.memory/` stays separate from skills. All `.memory/` files use OKF-compatible frontmatter.

## License

[MIT](LICENSE)
