---
name: guidance-sync
description: "Propose updates to project-local skills, AGENTS.md, and tool-script guides after work lands — and enforce that every tools/ script family has a skill covering usage and output interpretation. Use after adding or changing tool scripts, closing tickets that touched tooling, or when commands/flags/outputs drifted from their docs. Trigger: sync guidance, update project skills, agents.md stale, tool script has no skill, guide coverage, output interpretation, keep skills in sync, tooling guide."
metadata:
  type: protocol
  invocation: both
  practice: null
---

# Guidance Sync

After work lands, the project's guidance layer (project-local skills, AGENTS.md, steering pointers) must still describe reality. Run this sync; propose updates as a batch.

## Coverage Gate (the invariant)

**Every `tools/` script family has a project-local skill** (`.kiro/skills/{name}/SKILL.md`) covering: how to run it, what the flags do, how to read its output, and known failure modes.

Judgment rule — a family needs a full guide skill when ANY hold:
- Output requires interpretation (verdicts, rates, thresholds, JSON fields)
- It has modes/flags an agent could misuse (resume, dry-run, destructive paths)
- Misuse has cost (long runtimes, state mutation, result corruption)

A single-command script with self-evident output needs only an AGENTS.md command entry — don't create ceremony.

## Sync Workflow

1. **Inventory** — list `tools/` families, `.kiro/skills/` guides, AGENTS.md command blocks, steering pointers.
2. **Coverage check** — apply the gate above; each uncovered family gets a proposed guide or an explicit "AGENTS.md entry suffices" verdict.
3. **Drift pass** — for each existing guide + AGENTS.md block, diff against current script behavior: flags, arg syntax, output fields, paths. Run `--help` or read the script header; don't trust memory. (Precedent: `session:skills` arg syntax was stale in AGENTS.md while the task worked fine.)
4. **New-knowledge pass** — did recent work produce decisions, gotchas, or output-reading rules that belong in a guide? (e.g., a new verdict field, a resume flag, a "never edit mid-run" rule.)
5. **Propose as a batch** — one table: file → change → reason. Apply on approval; for trivial corrections (stale flag syntax, dead path) apply directly and note it.

## Proposal Format

```
| Target | Change | Why |
|--------|--------|-----|
| .kiro/skills/X/SKILL.md | add --foo flag + verdict row | landed in ticket N |
| AGENTS.md commands | fix arg syntax | drifted from script |
| (new) .kiro/skills/Y/ | create guide | tools/Y fails coverage gate |
```

## What a Tool-Guide Skill Contains

Model on existing guides (eval-harness, deploy-toolkit, session-analysis):
- Run commands with real flag examples
- Output interpretation table (field → meaning → action)
- Failure modes and their fixes
- When to run / when NOT to run
- Hard rules with the incident that created them

## Scope Discipline

- Guides describe CURRENT behavior — never document planned features as existing
- One source of truth: AGENTS.md gets the command line; the guide skill gets interpretation. Don't duplicate prose between them
- Skill budget: <100 lines per SKILL.md; split to `references/` if over
