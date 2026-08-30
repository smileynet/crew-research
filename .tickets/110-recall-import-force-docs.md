---
id: "110"
title: "Document recall import --force gotcha and add import to CLI reference skill"
status: in_progress
blocked_by: []
priority: medium
validation_criteria:
  - "CLI reference includes recall import command with --force warning"
  - "Skill or reference documents the subdirectory wipe behavior"
---

# Document recall import --force gotcha and add import to CLI reference skill

## Context

The `recall import` command is heavily used but completely missing from the recall skill's CLI reference (`~/.kiro/skills/recall/references/cli-reference.md`). The Commands section lists `search`, `add`, `ingest`, `prime`, `status` — but not `import`.

The `--force` flag has a destructive gotcha that caused data loss in a godot-helper session (2026-08-17): importing a SUBDIRECTORY with `--force` wipes the ENTIRE wing and replaces with ONLY that subdirectory's content. The correct usage is always importing from the full `.memory/` root.

**Incident:** `recall import .memory/api-capabilities/ --wing godot_api_reference --force` wiped 11,409 drawers and replaced with 68 (just the capability pages). Required a 60-minute full reimport to recover.

## What to build

1. Add `recall import` to the Commands section of `cli-reference.md`:
   ```bash
   recall import .memory/ --wing name          # import all markdown files
   recall import .memory/ --wing name --force  # wipe wing and reimport
   ```

2. Add a **hard rule** (prominently placed, not buried) documenting the `--force` gotcha:
   ```
   DANGER: --force on a SUBDIRECTORY wipes the ENTIRE wing, not just that subdirectory.
   ALWAYS import from the full .memory/ root when using --force.
   NEVER: recall import .memory/cards/ --wing X --force (destroys everything except cards)
   ```

3. Consider whether `recall import` itself should refuse `--force` on a subdirectory when a wing already has content (safety guard in the tool itself).

## Acceptance criteria

- [ ] CLI reference includes `recall import` with all flags
- [ ] --force gotcha documented with clear DO/DON'T examples
- [ ] Decision on whether to add a safety guard in the tool (issue or ADR)

## Scope refinement (2026-08-30, research + code review)

Dispatched research (destructive-flag safety, prior art) + code review (recall
import internals, crew doc conventions). Findings that adjust execution:

- **No `DANGER` banner** — it's not an established crew-research token. House style
  for destructive warnings is bold imperative prose + STOP/consequence + DO/DON'T
  (precedent: git-protocol, deployment-safety). Reformat the AC2 warning to match.
- **Placement**: inline `#` comment on the command line PLUS a short bolded block
  after it — not buried in the Known Issues table.
- **Extra in-scope fix**: `cheatsheet/SKILL.md:115` already teaches
  `recall import .memory/ --force --wing name` caveat-free — fix it too.
- **Redeploy required**: deployed recall skill is a COPY (not symlink), so editing
  `atomics/skills/recall/references/` needs `mise run init -- --global` to propagate.
  Verified: deployed cli-reference currently has 0 `import` matches.
- **AC3 decision — file a recall-repo ticket, don't edit recall from here**
  (ownership boundary). Source review (D:\code\recall\src\ingest.rs): `--force`
  deletes ALL wing import chunks (`import:{wing}:` prefix) then reimports only
  `<PATH>`. Literal "subdirectory-of-root detection" is HARD (import root stored
  nowhere). The EASY guard that closes the actual hole: confirm before force-deleting
  a NON-EMPTY wing, with a `--yes` bypass (distinct from `--force`) threaded through
  `sync`/`import-all` so the scheduled task keeps working; print blast-radius
  (chunk count) first. Prior art (terraform/rsync/git/npm): `--force` (skip guards)
  should be separate from `--yes` (skip prompt); show blast radius; non-TTY needs `--yes`.
