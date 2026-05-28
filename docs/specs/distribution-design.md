---
title: "Distribution Design — Basic vs Full Tiers"
date: 2026-05-27
status: proposed
---

# Distribution Design

## The Problem

38 skills + 8 crews + 9 archetypes is overwhelming for a new user who just wants "make my AI coding assistant better." We need tiers that let users start simple and grow.

## Proposed Tiers

### Basic (10 skills, 0 crews, 2 prompts)

For: Solo developer who wants better AI output without multi-agent complexity.

**Skills (always-on via steering):**
- ai-generation-hygiene — cleaner code output
- verification-protocol — agent verifies before reporting done

**Skills (on-demand):**
- five-whys — root cause analysis
- planning-cycles — structured planning for complex tasks
- git-protocol — commit/push discipline
- code-review — review checklist
- testing-guide — what/how to test
- troubleshooting-protocol — systematic debugging
- writing-style — clear technical writing
- script-authoring — quality shell scripts

**Prompts:**
- @handoff — session continuity
- @read-handoff — session orientation

**Workspace:**
- `.memory/CONTEXT.md` — glossary
- `.scratch/` — ephemeral notes
- `AGENTS.md` — minimal (commands + conventions)

**Init command:**
```bash
mise run init -- --project ~/myproject --tier basic --tool kiro-cli
```

### Full (38 skills, crews, 6 prompts)

For: Team or power user who wants multi-agent workflows, specialized crews, and the complete toolkit.

Everything in Basic, plus:
- All remaining skills (architecture-deepening, prototype-protocol, poc-workflow, diagrams, etc.)
- Multi-agent crew deployment (lead + workers)
- All prompts (@grill-with-docs, @workspace-cleanup, @read-handoff, @handoff, etc.)
- Workspace conventions with .memory/adr/, docs/ structure

**Init command:**
```bash
mise run init -- --project ~/myproject --tier full --crews development --tool kiro-cli
```

### Custom (pick and choose)

For: User who knows what they want.

```bash
mise run init -- --project ~/myproject --skills "five-whys,planning-cycles,code-review" --tool kiro-cli
```

## Tier Composition

| Category | Basic | Full |
|----------|:-----:|:----:|
| Steering (always-on) | 2 | 2 |
| On-demand skills | 8 | 36 |
| Prompts | 2 | 6 |
| Agents | 0 (default only) | 7+ |
| Crews | 0 | 1-8 |
| Workspace conventions | Minimal | Full |

## UX Improvements

### 1. Single install command

Currently: clone repo, run init with flags. 
Proposed: `npx crew-research init` or `mise run init` with interactive prompts.

```bash
$ mise run init -- --project .
? Tier: [basic] / full / custom
? Tool: [kiro-cli] / claude-code
? Language: (auto-detected: typescript)
? Build command: (detected: npm run build)

✅ Deployed 10 skills, 2 prompts, 2 steering files
   Run `kiro-cli chat` to start using them.
```

### 2. Auto-detection

The init script should:
- Detect language from package.json / Cargo.toml / pyproject.toml / go.mod
- Detect build/test/lint commands from existing config
- Detect existing .kiro/ and offer to merge rather than overwrite
- Detect git remote and set up issue templates if GitHub

### 3. Skill catalog with descriptions

```bash
$ mise run catalog
Category: Code Quality
  ai-generation-hygiene    Cleaner AI code output (steering, always-on)
  code-review              Review checklist for PRs
  testing-guide            What and how to test

Category: Planning
  planning-cycles          Structured planning with phases
  prototype-protocol       Throwaway code to answer design questions
  poc-workflow             Full PoC lifecycle

Category: Process
  git-protocol             Commit/push discipline
  verification-protocol    Verify before reporting done (steering)
  completion-protocol      Task completion sequence
  ...
```

### 4. Upgrade path

```bash
# Start basic
mise run init -- --project . --tier basic

# Later, add specific skills
mise run add -- --skills "architecture-deepening,diagrams"

# Or upgrade to full
mise run upgrade -- --tier full
```

### 5. Health check

```bash
$ mise run doctor
✅ kiro-cli 2.3.0 (required: >=2.3.0)
✅ yq 4.44.1
✅ 10 skills deployed, 2 steering files
⚠️  .memory/CONTEXT.md is empty (add project terms)
⚠️  No .gitignore entry for .scratch/
✅ All skill references valid
```

### 6. Skill preview before install

```bash
$ mise run preview -- five-whys
# five-whys (reasoning-mode)
# Root cause analysis via iterative "why?" questioning.
# Trigger: "why is this happening", "root cause", "diagnose"
# Lines: 45 | References: 0
# ---
# Activate when debugging, diagnosing failures, or investigating
# unexpected behavior. Ask "why?" 5 times to reach root cause.
```

## File Changes Needed

| File | Change |
|------|--------|
| `tools/generator/init.sh` | Add `--tier` flag (basic/full/custom), `--skills` flag |
| `compositions/tiers/basic.yaml` | New — lists skills/prompts for basic tier |
| `compositions/tiers/full.yaml` | New — lists everything |
| `tools/generator/catalog.sh` | New — prints skill catalog |
| `tools/generator/doctor.sh` | New — health check |
| `tools/generator/add.sh` | New — add skills to existing project |
| `mise.toml` | Add catalog, doctor, add, upgrade tasks |
| `README.md` | Rewrite for user-facing distribution |

## Priority

1. **Tier definitions** (basic.yaml, full.yaml) — defines what ships in each tier
2. **Init with --tier** — the primary UX improvement
3. **Auto-detection** — reduces friction for new users
4. **Catalog** — discoverability
5. **Doctor** — troubleshooting
6. **Add/upgrade** — growth path
