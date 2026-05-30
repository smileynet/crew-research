---
name: project-cleanup
description: "Consolidate workspace artifacts — promote scratch to memory, deduplicate memory, organize scripts, update steering/skills accuracy. Use periodically or when the workspace feels cluttered."
metadata:
  type: process
  invocation: user-only
  practice: null
  params:
    ephemeral_path: ".scratch"
    durable_path: ".memory"
    scripts_path: "tools"
    mise_file: "mise.toml"
---

# Workspace Cleanup

Systematic consolidation of workspace artifacts. Run periodically to prevent drift and clutter.

## Phase 1: Promote Scratch → Memory

Review all files in `{{params.ephemeral_path}}/`:
- **Promote** findings/decisions that have lasting value → `{{params.durable_path}}/`
- **Archive** completed handoffs (superseded by newer ones) → delete
- **Keep** only the current handoff and active scratch notes

Decision criteria for promotion:
- Will a future session need this? → promote
- Is this a one-time finding already captured elsewhere? → delete
- Is this a decision that should be an ADR? → write ADR, delete scratch

## Phase 2: Consolidate Memory

Review all files in `{{params.durable_path}}/`:
- **Deduplicate** — merge documents covering the same topic
- **Update CONTEXT.md** — add any terms used but not yet defined
- **Deprecate** — mark outdated ADRs as superseded (don't delete)
- **Aggregate** — if multiple small findings exist on one topic, combine into one document

Check: is every entry in CONTEXT.md still accurate? Remove stale definitions.

## Phase 3: Organize Scripts

Review `{{params.scripts_path}}/`:
- **Document** — every script has a usage comment in its header
- **Consolidate** — merge scripts with overlapping purpose
- **Remove** — delete dead scripts (not referenced anywhere)
- **README** — ensure each tool directory has a README with quick-reference commands

## Phase 4: Update Task Runner

Review `{{params.mise_file}}` (or Makefile/justfile):
- **Add** commonly used invocation patterns as named tasks
- **Remove** tasks that reference deleted/renamed scripts
- **Document** — each task has a description

Common patterns to capture:
- `validate` — run all validation (generator validate + lint)
- `generate` — generate deployment for current project
- `test` — run eval suite
- `init` — initialize a new project

## Phase 5: Verify Steering & Skills

For each eager-context file and skill:
- **Accuracy** — do file paths and commands referenced still exist?
- **Freshness** — does the content reflect current project state?
- **Cross-links** — run `tools/lint/check-crosslinks.sh`
- **Params** — do declared params have sensible defaults?

Flag any skill that references files/tools that no longer exist.

## Phase 6: README & AGENTS.md Currency

**README.md** (user-facing entry point):
- Does it reflect what the project IS and HOW to use it?
- Focus on user concerns: what it does, quick start, how to get value
- No sausage-making: no implementation details, no internal architecture
- No commands/configs that only agents need — those go in AGENTS.md
- Links to docs/ for deeper user-facing content

**AGENTS.md** (agent-facing entry point):
- Does it reflect current workspace structure and conventions?
- Aware of BOTH user docs (docs/) and agent docs (.memory/, .kiro/)
- Contains: workspace layout, commands, configs, tool references
- Navigation map: where to look for what kind of information
- Updated when scripts/tools/structure changes

## Phase 7: Dependency & Config Hygiene

- **Dependencies** — are all tools referenced by scripts actually installed?
- **Git** — any untracked files that should be committed or gitignored?
- **Stale branches** — any merged branches that can be deleted?
- **Issues** — any completed work that should close an open issue?

## Report

After cleanup, produce a summary:
```
## Cleanup Summary
- Promoted: N files from scratch → memory
- Deleted: N stale scratch files
- Consolidated: N memory documents merged
- Scripts: N documented, N removed
- Skills: N updated, N flagged as stale
- Issues: N closeable
```
