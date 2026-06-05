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

Ask: "Are you working solo on a project, or do you need multi-agent delegation?"

- **Solo / small team / just want better output** → `basic`
- **Need multi-agent crews, research workflows, PoC lifecycle, creative writing** → `full`

## Setup Steps

1. **Ensure prerequisites**: `kiro-cli` 2.3.0+, `yq`, `mise` (optional but recommended)
2. **Run init**:
   ```bash
   mise run init -- --project ~/their-project --tier basic --tool kiro-cli
   ```
3. **Verify**: `mise run doctor -- --project ~/their-project`
4. **Explain what was deployed**:
   - `.kiro/steering/` — always-on rules (code hygiene, verification)
   - `.kiro/skills/` — on-demand knowledge (activates when relevant)
   - `.kiro/skills/` — on-demand knowledge (activates when relevant, invocable via `/name`)
   - `.memory/CONTEXT.md` — project glossary (they should add terms as they work)
   - `AGENTS.md` — agent-facing project reference

## After Setup

Teach the user these workflows:
- **Starting a session**: `@read-handoff` (if continuing prior work)
- **Planning work**: just describe what they want — `planning-cycles` activates automatically
- **Stress-testing a design**: `@grill-with-docs`
- **Ending a session**: `@handoff`
- **Periodic cleanup**: `@workspace-cleanup`

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Skills not activating | Check `mise run doctor`; verify `.kiro/skills/` has SKILL.md files |
| "Command not found" for mise | `mise` is optional; they can run `tools/generator/init.sh` directly |
| Want to add more skills later | `mise run catalog` to browse, then re-run init with `--tier full` |
| Steering feels too aggressive | Remove specific `.kiro/steering/*.md` files they don't want |
