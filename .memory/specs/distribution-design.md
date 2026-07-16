---
type: specification
title: "Distribution Design — Basic vs Full Tiers"
date: 2026-05-27
status: done
---

# Distribution Design

## The Problem

38 skills + 8 crews + 9 archetypes is overwhelming for a new user who just wants "make my AI coding assistant better." We need tiers that let users start simple and grow.

## Proposed Tiers

### Basic (11 skills + 2 steering + 5 prompts)

For: Any developer working through a project. Covers the full lifecycle: setup → design → plan → build → verify → commit → deliver → hand off → cleanup.

| Skill/Prompt | Phase | Role |
|---|---|---|
| ai-generation-hygiene *(steering)* | Build | Clean code every turn |
| verification-protocol *(steering)* | Verify | Agent verifies before reporting done |
| planning-cycles | Plan | Break down work, scope, phase it |
| five-whys | Plan | Diagnose before solving |
| assumption-tracking | Plan | Surface hidden assumptions |
| script-authoring | Build | Quality scripts |
| troubleshooting-protocol | Build | When things break |
| code-review | Verify | Check your own work |
| testing-guide | Verify | Know what to test |
| git-protocol | Commit | Commit discipline |
| writing-style | Deliver | Clear communication |
| @init-project | Setup | Bootstrap workspace conventions |
| @grill-with-docs | Design | Stress-test the plan, resolve decisions |
| @handoff | Continuity | Session state capture |
| @read-handoff | Continuity | Session orientation |
| @workspace-cleanup | Cleanup | Periodic consolidation |

### Full (35 skills + 2 steering + 6 prompts + 7 agents)

Everything in Basic, plus specialized skills for specific activities:

| Category | Additional Skills |
|----------|-----------------|
| Plan | prototype-protocol, architecture-deepening, poc-workflow, situation-routing |
| Verify | completion-protocol |
| Commit | commit-pr-discipline, deployment-safety |
| Deliver | changelog-discipline, readme-writing, tutorial-authoring, presentation-writing, diagrams, diataxis-classification, document-formats |
| Design | research-methodology, research-output, reference-exploration, adr-authoring |
| Cleanup | docs-audit |
| Meta | enforcement-hierarchy, eval-criteria, session-review-patterns |
| Creative | fiction-craft, world-building |
| Prompt | @research-prior-art |
| Agents | lead, planner, implementer, researcher, reviewer, tester, writer |

### Custom (pick and choose)

For: User who knows what they want.

```bash
mise run init -- --project ~/myproject --skills "five-whys,planning-cycles,code-review" --tool kiro-cli
```

## Tier Composition

| Category | Basic | Full |
|----------|:-----:|:----:|
| Steering (always-on) | 2 | 2 |
| On-demand skills | 11 | 35 |
| Prompts | 5 | 6 |
| Agents | 0 (default only) | 7 |
| Lifecycle coverage | Full (setup→cleanup) | Full + specialized activities |

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
