---
name: project-cleanup
description: "Consolidate project artifacts — promote scratch to memory, deduplicate memory, process decisions, organize scripts, update steering/skills accuracy. Use periodically or when the project feels cluttered."
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

# Project Cleanup

Systematic consolidation of project artifacts. Run periodically to prevent drift and clutter.

## Phase 1: Promote Scratch → Memory

Review all files in `{{params.ephemeral_path}}/`:
- **Promote** findings/decisions that have lasting value → `{{params.durable_path}}/`
- **Archive** completed handoffs (superseded by newer ones) → delete
- **Keep** only the current handoff and active scratch notes

Decision criteria for promotion:
- Will a future session need this? → promote
- Is this a one-time finding already captured elsewhere? → delete
- Is this a decision that should be an ADR? → write ADR, delete scratch

## Phase 2: Process Decisions → ADR

Check for decisions files (`decisions.md`, `DECISIONS.md`, `.memory/decisions.md`, `docs/decisions.md`):

1. **Read** each decisions file
2. **Evaluate** each decision for ADR fitness:
   - Hard to reverse? Surprising without context? Real trade-off? → write ADR
   - Lightweight/easily reversed? → leave in place or delete if captured elsewhere
3. **Extract terms** — scan for domain terminology, add to `.memory/CONTEXT.md`
4. **Clean up** — remove decisions files once all entries are processed

## Phase 3: Consolidate Memory

Review all files in `{{params.durable_path}}/`:
- **Deduplicate** — merge documents covering the same topic
- **Update CONTEXT.md** — add any terms used but not yet defined
- **Deprecate** — mark outdated ADRs as superseded (don't delete)
- **Aggregate** — if multiple small findings exist on one topic, combine into one document

Check: is every entry in CONTEXT.md still accurate? Remove stale definitions.

## Phase 4: References Directory

- If `resources/` or `references/` exists and is gitignored → rename to `.references/`, update `.gitignore`
- Ensure `.references/` is in `.gitignore`
- Verify reference repos are documented in AGENTS.md

## Phase 5: Organize Scripts

Review `{{params.scripts_path}}/`:
- **Document** — every script has a usage comment in its header
- **Consolidate** — merge scripts with overlapping purpose
- **Remove** — delete dead scripts (not referenced anywhere)
- **README** — ensure each tool directory has a README with quick-reference commands

## Phase 6: Update Task Runner

Review `{{params.mise_file}}` (or Makefile/justfile):
- **Add** commonly used invocation patterns as named tasks
- **Remove** tasks that reference deleted/renamed scripts
- **Document** — each task has a description

## Phase 7: Verify Steering & Skills

For each eager-context file and skill:
- **Accuracy** — do file paths and commands referenced still exist?
- **Freshness** — does the content reflect current project state?
- **Cross-links** — run `tools/lint/check-crosslinks.sh`
- **Params** — do declared params have sensible defaults?

Flag any skill that references files/tools that no longer exist.

## Phase 8: README & AGENTS.md Currency

**README.md** (user-facing entry point):
- Does it reflect what the project IS and HOW to use it?
- Focus on user concerns: what it does, quick start, how to get value
- No internal architecture or agent-only details

**AGENTS.md** (agent-facing entry point):
- Does it reflect current project structure and conventions?
- Aware of BOTH user docs (docs/) and agent docs (.memory/, .kiro/)
- Contains: project layout, commands, configs, tool references
- Navigation map: where to look for what kind of information

## Phase 9: Dependency & Config Hygiene

- **Dependencies** — are all tools referenced by scripts actually installed?
- **Git** — any untracked files that should be committed or gitignored?
- **Stale branches** — any merged branches that can be deleted?
- **Issues** — any completed work that should close an open issue?

## Report

After cleanup, produce a summary:
```
## Cleanup Summary
- Promoted: N files from scratch → memory
- Decisions: N processed → ADR, N terms extracted
- Deleted: N stale scratch files
- Consolidated: N memory documents merged
- References: ✅/❌ (standardized?)
- Scripts: N documented, N removed
- Skills: N updated, N flagged as stale
- Issues: N closeable
```
