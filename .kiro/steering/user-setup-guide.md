# User Setup Guide

When a user asks about setting up crew-research, installing skills, or getting started, follow this flow.

## Decision Flow

```
"What is this?" → Explain: portable skills that improve AI coding assistants
"How do I use it?" → Guide through tier selection + init
"What tier?" → Ask about their workflow, recommend basic unless they need crews/research/creative
"Something isn't working" → Run doctor, check output
```

## Tier Recommendation

Ask: "What does your workflow look like?"

- **Building and shipping code** (plan, build, review, test, deploy) → `basic`
- **Full development lifecycle** (also research, architecture, docs, deployment safety) → `full`

Both tiers are global. **Project-level specialist skills** (creative, prototyping, meta) install per-project — suggest them during init or when you detect matching work.

## Setup Steps

1. **Ensure prerequisites**: `kiro-cli` 2.3.0+, `yq`, `mise` (optional but recommended)
2. **Run init**:
   ```bash
   mise run init -- --project ~/their-project --tier basic --tool kiro-cli
   ```
3. **Verify**: `mise run doctor -- --project ~/their-project`
4. **Explain what was deployed**:
   - `.kiro/steering/` — always-on rules (code hygiene, verification)
   - `.kiro/skills/` — on-demand knowledge (activates when relevant, invocable via `/name`)
   - `.memory/CONTEXT.md` — project glossary (they should add terms as they work)
   - `AGENTS.md` — agent-facing project reference

## After Setup

Teach the user these workflows:
- **Starting a session**: `/read-handoff` (if continuing prior work)
- **Planning work**: just describe what they want — `planning-cycles` activates automatically
- **Stress-testing a design**: `/grill-with-docs`
- **Ending a session**: `/handoff`
- **Periodic cleanup**: `/workspace-cleanup`

### Personal Global Steering (symlink convention)

Files added directly to `~/.kiro/steering/` that aren't in the deployed tier get **PRUNED on the next deploy**. To add personal always-on steering that survives redeploys, symlink it — init.sh's prune preserves symlinks:

```bash
ln -s ~/my-notes/my-conventions.md ~/.kiro/steering/my-conventions.md
```

`mise run doctor` warns about unmanaged regular files at risk.

### Customizing Global Skills

If a global skill needs project-specific knowledge (domain questions, source priorities, cross-reference targets), use a **steering pointer** instead of forking the skill:

1. Create `.kiro/steering/pointer-file.md` (always-loaded, ~2 lines): "Before starting [skill], read [detail file]"
2. Create `.kiro/steering/detail-file.md` with `inclusion: manual` — contains the domain context
3. The global skill runs unmodified; the agent reads the detail file on demand when the skill activates

This costs ~50 characters of always-loaded context vs thousands for a full skill copy. See ADR 0002 for when to use params vs pointers vs extends.

### Extensions (Auto-Deploy)

Extensions add capabilities that require external tools. They deploy automatically when prerequisites are met during tier deploy.

```bash
uv tool install ./tools/recall            # install from a crew-research clone
mise run init -- --global --tier basic    # recall auto-activates
mise run init -- --skip-extension recall  # opt out if desired
```

| Extension | What it adds | Prerequisite |
|-----------|-------------|--------------|
| `recall` | Cross-session memory — remembers decisions, past work, preferences | `recall` CLI on PATH |

**When to suggest:** If the user works on long-lived projects, frequently resumes work across sessions, or asks about past decisions — suggest installing `recall` CLI.

**Install recall prerequisite:**
```bash
uv tool install ./tools/recall   # from a crew-research clone (PyPI "recall" is a squatted unrelated package)
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Skills not activating | Check `mise run doctor`; verify `.kiro/skills/` has SKILL.md files |
| "Command not found" for mise | `mise` is optional; they can run `tools/generator/init.sh` directly |
| Want to add more skills later | `mise run catalog` to browse, then re-run init with `--tier full` |
| Steering feels too aggressive | Remove specific `.kiro/steering/*.md` files they don't want |
