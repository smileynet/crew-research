---
id: "159"
title: "Remove stale dispatch-codex-review/ dir failing lint (empty, post-rename orphan)"
status: in_progress
blocked_by: []
priority: high
---

# Remove stale dispatch-codex-review/ dir failing lint (empty, post-rename orphan)

## Intent source

`mise run lint` has failed on every skill change this session (surfaced during tickets 152
and 151 verification). Diagnosed as a pre-existing orphan, not caused by any current work.
High priority because it makes `mise run lint` red for ALL contributors — masking real lint
regressions behind a known failure.

## Problem

`mise run lint` (`tools/lint/check-crosslinks.sh`) emits two errors:

```
❌ deprecated name resurrected: atomics/skills/dispatch-codex-review/ exists but
   dispatch-codex-review is in compositions/deprecated.yaml
❌ dispatch-codex-review: no SKILL.md
```

Root cause: ticket 127 renamed `dispatch-codex-review` → `dispatch-review` (tool-neutral
reviewer) and correctly added the old name to `compositions/deprecated.yaml`, but the old
directory `atomics/skills/dispatch-codex-review/` was left behind. It now contains only two
EMPTY subdirs (`agents/`, `assets/`) and NO `SKILL.md`.

## Findings (verified this session)

- `atomics/skills/dispatch-codex-review/` = 0 files; only empty `agents/` + `assets/` subdirs.
- **Untracked by git** (`git ls-files` returns nothing; git doesn't track empty dirs) — this
  is a local-only stale artifact from the rename, not committed content.
- The replacement `dispatch-review` skill exists and is live.
- `deprecated.yaml` entry for `dispatch-codex-review` is CORRECT and must stay (never remove
  deprecated entries — field machines deploy years apart).
- No tier/composition lists the old name as an active skill (only historical ticket mentions
  + a deploy-toolkit doc reference explaining prune behavior).

## What to build

1. Delete the empty directory `atomics/skills/dispatch-codex-review/` (and its empty
   `agents/`, `assets/` subdirs).
2. Do NOT touch `compositions/deprecated.yaml` — the entry stays (prune contract).
3. Re-run `mise run lint` → must be green (0 errors).

## Acceptance criteria

- [ ] `atomics/skills/dispatch-codex-review/` no longer exists
- [ ] `compositions/deprecated.yaml` unchanged (dispatch-codex-review entry retained)
- [ ] `mise run lint` passes with 0 errors
- [ ] `mise run validate` still passes
- [ ] No other skill/dir touched (scope = directory removal only)

## Out of scope

- Removing the `deprecated.yaml` entry (must persist for field prune)
- Any change to the live `dispatch-review` skill
- Reconciling historical ticket references to the old name (they're history)

## Note

Since the dir is untracked, the removal won't show in `git diff` for tracked files — verify
via `mise run lint` going green rather than a diff. If any environment has the dir tracked,
`git rm -r` it instead of a plain delete.
