---
id: "52"
title: "Scope --force DELETE to the target wing"
status: done
blocked_by: []
env: either
spec: "recall-import-fix"
---

# Scope --force DELETE to the target wing

## What to build

Change `recall import --force` to delete only the specified wing's import chunks, not all imports globally.

## Context

- **Current code (cli.py ~line 183):**
  ```python
  conn.execute("DELETE FROM drawers WHERE source LIKE ?", (f"import:%",))
  ```
  This deletes ALL `import:*` rows regardless of wing. Running `recall import .memory/ --wing project_a --force` destroys project_b's imports.

- **Fix:**
  ```python
  conn.execute("DELETE FROM drawers WHERE source LIKE ? AND wing = ?", ("import:%", wing))
  ```

- After ticket 51 removes `--force` from scheduled scripts, this ticket makes `--force` safe for manual single-project reimport (e.g., after editing `.memory/CONTEXT.md` and wanting immediate refresh).

## Acceptance criteria

- [ ] `recall import dir --wing X --force` deletes only rows where `wing = X AND source LIKE 'import:%'`
- [ ] Importing wing A with --force does NOT affect wing B's import chunks
- [ ] Test: import two wings, force-reimport one, verify the other's chunk count is unchanged
- [ ] The deleted-count message still reports accurately

## Out of scope

- Automatic change detection (ticket 53)
- A `--all-wings` flag for full reset (can be added later if needed)
