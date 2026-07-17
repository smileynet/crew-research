# crew-research

Portable behavioral skills that make AI coding assistants plan before building, verify before claiming done, and remember decisions across sessions.

## What It Does

You install skills into your project. Your AI assistant gets better without changing how you work:

- Plans before building — asks clarifying questions, tracks assumptions
- Verifies before reporting done — runs checks, cites evidence
- Remembers across sessions — recalls past decisions, continues prior work
- Produces cleaner code — concise, well-structured, no defensive bloat

Skills are plain markdown files. They work with kiro-cli, codex, and other skill-compatible tools.

| When I'm... | I want to... | So I can... |
|-------------|-------------|-------------|
| Starting a new feature | get structured planning | stop diving in without thinking |
| Ending a session | capture state automatically | continue tomorrow without re-discovery |
| Asking "what did we decide?" | get the actual decision, not a guess | avoid contradicting past choices |
| Reviewing generated code | have objective standards applied | catch bloat and missing verification |
| Deploying to production | get safety checks enforced | avoid breaking things on Friday |
| Working across projects | have consistent conventions | stop re-learning workspace layout |
| Onboarding to a codebase | get existing knowledge surfaced | skip the "where is everything?" phase |

## Quick Start

```bash
# Prerequisites
brew install mise yq                     # macOS (or: see docs for Linux/Windows)
curl -fsSL https://kiro.dev/install | sh # kiro-cli

# Deploy skills globally
mise run init -- --global --tier basic --tool kiro-cli

# Scaffold a project workspace
mise run init -- --project ~/my-project

# Verify
mise run doctor -- --project ~/my-project
# ✅ kiro-cli (2.10.0)
# ✅ 6 steering, 18 skills
# ✅ .memory/CONTEXT.md
# ✅ Healthy
```

That's it. Open any kiro-cli session — skills activate automatically.

## Tiers

| Tier | What you get | Best for |
|------|-------------|----------|
| **basic** | Planning, code review, testing, git, session continuity | Everyday development |
| **full** | + research, architecture, diagrams, deployment safety, docs | Full lifecycle |

Start with **basic**. Everything you need in every project, nothing you don't.

```bash
mise run catalog    # browse all available skills
```

## Extensions

Extensions add capabilities with external tool dependencies. They auto-deploy when prerequisites are met:

```bash
# Install cross-session memory (the prerequisite)
uv tool install ./tools/recall   # from a crew-research clone — PyPI "recall" is an unrelated squatted package

# Deploy tier — recall extension activates automatically
mise run init -- --global --tier basic --tool kiro-cli
# Extensions: recall ✅

# Now the agent remembers past decisions
recall import .memory/ --wing my_project  # index project knowledge
recall search "what did we decide about X"
```

| Extension | What it adds | Prerequisite |
|-----------|-------------|--------------|
| `recall` | Cross-session memory — searches past decisions, imports project knowledge | `recall` CLI on PATH |

Extensions auto-detect. To skip: `--skip-extension recall`.

## What You Can Do

After setup, these workflows are available in any kiro-cli session:

| Command | What it does |
|---------|-------------|
| `/grill-with-docs` | Stress-test a plan with evidence-backed questions |
| `/handoff` | Capture session state for the next session |
| `/read-handoff` | Orient at session start — continue where you left off |
| `/plan-prereqs` | Identify research and tooling needed before building |
| `/project-cleanup` | Consolidate notes, update glossary, remove stale artifacts |
| `/study-reference` | Deep-dive a reference repo and extract patterns |
| `/cheatsheet` | Quick reference for everything available |

## How It Works

**Before:** AI dives straight in, skips verification, loses context between sessions.

**After:** The AI automatically:
- Asks clarifying questions before building (planning skills)
- Verifies its work before reporting done (verification protocol)
- Produces concise code (code hygiene steering)
- Recalls past decisions when asked (recall extension)
- Captures state at session end (handoff)

None of this requires you to change how you work. You just chat normally.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│  Behavior Layer (skills + steering)                 │
│  "How to act" — protocols, reasoning modes, gates   │
│  Format: SKILL.md (markdown + YAML frontmatter)     │
├─────────────────────────────────────────────────────┤
│  Memory Layer (recall extension)                    │
│  "What happened" — decisions, lessons, preferences  │
│  Hybrid BM25 + vector search over sessions + docs   │
├─────────────────────────────────────────────────────┤
│  Knowledge Layer (.memory/)                         │
│  "What exists" — glossary, ADRs, specs, references  │
│  OKF-compatible (markdown + type/title frontmatter) │
└─────────────────────────────────────────────────────┘
```

**Skills** tell the agent what to DO. **Recall** gives it memory of what WAS. **Knowledge** describes what IS. All three are plain files — portable, git-native, tool-agnostic.

## Deployment Options

- **Globally** (`--global`) — skills install to `~/.kiro/` and apply in every project
- **To a project** (`~/my-project`) — workspace conventions scoped to that project
- **Per-project skills** — specialist skills (creative writing, prototyping) install only where needed

Most people deploy globally once, then scaffold per-project workspace conventions as needed.

### Multi-Tool Deployment

Skills are tool-agnostic. The `--tool` flag controls WHERE files are placed:

```bash
# kiro-cli (default)
mise run init -- --global --tier basic --tool kiro-cli
# Skills → ~/.kiro/skills/    Steering → ~/.kiro/steering/

# Codex (OpenAI)
mise run init -- --global --tier basic --tool codex
# Skills → ~/.agents/skills/  Steering → ~/.codex/AGENTS.md

# Antigravity (Google)
mise run init -- --global --tier basic --tool agy
# Skills → ~/.gemini/antigravity-cli/skills/  Steering → ~/.gemini/AGENTS.md
```

| Tool | Skills Path | Steering Path | Verify |
|------|-------------|---------------|--------|
| kiro-cli | `~/.kiro/skills/{name}/SKILL.md` | `~/.kiro/steering/*.md` | `mise run doctor` |
| codex | `~/.agents/skills/{name}/SKILL.md` | `~/.codex/AGENTS.md` (appended) | `codex --version` |
| agy | `~/.gemini/antigravity-cli/skills/{name}/SKILL.md` | `~/.gemini/AGENTS.md` (appended) | `agy --version` |

Same skill content, different delivery paths. Deploy to multiple tools simultaneously if you switch between them.

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

## Adapted From

**[MemPalace](https://github.com/MemPalace/mempalace)** — The recall extension adapts MemPalace's architecture (wings/rooms/drawers) as a purpose-built 673-line implementation. SQLite + FTS5 + local embeddings, no server dependencies. See [ADR 0007](.memory/adr/0007-purpose-built-recall-tool.md).

**[Google OKF](https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf)** — OKF's "nouns, not verbs" insight shapes how `.memory/` (knowledge) stays separate from skills (behavior). All `.memory/` files use OKF-compatible frontmatter (`type` + `title`), importable via `recall import`.

## License

[MIT](LICENSE)
