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
    crosslink_lint: "tools/lint/check-crosslinks.sh"
---

# Project Cleanup

Systematic consolidation of project artifacts. Run periodically to prevent drift and clutter.

## Phase 1: Promote Scratch → Memory

Review all files in `{{params.ephemeral_path}}/`:
- **Promote** findings/decisions that have lasting value → `{{params.durable_path}}/`
- **Archive** completed handoffs (superseded by newer ones) → delete
- **Keep** only the current handoff and active scratch notes

## Phase 2: Process Decisions → ADR

Check for decisions files (`decisions.md`, `DECISIONS.md`, `.memory/decisions.md`, `docs/decisions.md`). Route each entry per the knowledge routing table: ADR-worthy → write ADR; disambiguation term → CONTEXT.md; gotcha → AGENTS.md Constraints; not worth preserving → delete. Remove the decisions file once all entries are processed.

## Phase 3: Consolidate Memory

Review all files in `{{params.durable_path}}/`:
- **Deduplicate** — merge documents covering the same topic
- **CONTEXT.md scope enforcement** — for each entry, apply the disambiguation gate ("could two people mean different things by this word?"):
  - Passes → keep, trim to ≤3 lines (term + definition + avoid)
  - Fails → route: gotcha/env → stage for AGENTS.md Constraints; spec → `.memory/specs/`; decision → ADR or delete; stale → delete
  - Stage routed content in `.scratch/context-cleanup/` for integration
- **Deprecate** — mark outdated ADRs as superseded (don't delete)
- **Aggregate** — if multiple small findings exist on one topic, combine into one document

## Phase 4: References Directory

Verify reference-repo layout per [init-project](../init-project/SKILL.md)'s detection procedure: gitignored `references/` or `resources/` → rename to `.references/`; ensure `.references/` is gitignored and documented in AGENTS.md.

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
- **Cross-links** — run `{{params.crosslink_lint}}` if it exists
- **Params** — do declared params have sensible defaults?

Flag any skill that references files/tools that no longer exist.

## Phase 8: README & AGENTS.md Currency

- **README.md** (user-facing): reflects what the project IS and HOW to use it — what it does, quick start, how to get value. No internal architecture or agent-only details.
- **AGENTS.md** (agent-facing): check both currency AND role:
  - Commands still work? Layout accurate? Workflows available?
  - No term definitions (term + _Avoid_ pattern) — move to CONTEXT.md
  - No inline specs (>10 lines on one topic) — extract to `.memory/specs/`, leave a link
  - Constraints section includes operational gotchas from `.scratch/context-cleanup/move-to-agents.md` if it exists
  - Under 150 lines? If over → extract per agents-md-authoring trim rules

## Phase 9: Ticket Hygiene

If `.tickets/` exists:
- **Stale open tickets** — work completed but ticket not closed? `tkt close <id>`
- **Plan drift** — `tkt sync-plan --check` to detect status mismatches vs plan.md
- **Orphaned tickets** — tickets referencing deleted specs or features? Close with note
- **Done tickets with unchecked ACs** — `tkt validate` reports these; check or document why skipped

## Phase 10: Dependency & Config Hygiene

- **Dependencies** — tools referenced by scripts installed?
- **Git** — untracked files to commit or gitignore? Merged branches to delete?
- **Issues** — completed work that should close an open issue?

## Report

After cleanup, summarize: files promoted, decisions processed, scratch deleted, memory consolidated, skills flagged, tickets closed, issues closeable.
