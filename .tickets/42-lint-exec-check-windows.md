---
id: "42"
title: "Lint executable check false positive on Windows (core.filemode=false)"
status: done
blocked_by: []
env: either
spec: ""
---

# Lint executable check false positive on Windows (core.filemode=false)

## What to build

Replace the filesystem-based executable check in `tools/lint/check-crosslinks.sh` with a git-aware check using `git ls-files -s` to read the stored mode bits.

## Context

- **Observed (2026-07-19):** `mise run lint` reports `bashrc-hook.sh` as not executable, but `git ls-tree HEAD tools/recall/bashrc-hook.sh` confirms 100755. The check uses `find ... ! -perm -u+x` which reads filesystem perms — on Windows with `core.filemode=false`, all files appear 644 on disk regardless of git's stored mode.
- This blocks `mise run lint` from passing on Windows/WSL even when all files are correctly marked in git.
- The executable check was added after the `inspect-session.sh` incident (non-exec scripts silently failing).

## Acceptance criteria

- [x] `tools/lint/check-crosslinks.sh` uses `git ls-files -s` (or equivalent git-aware method) instead of filesystem permissions
- [x] Files tracked as 100755 in git pass; files tracked as 100644 fail
- [x] Untracked .sh files in tools/ are flagged (not silently skipped)
- [x] `mise run lint` passes on this repo on Windows (the bashrc-hook.sh false positive is gone)
- [ ] Behavior on Linux/macOS unchanged (git mode matches filesystem mode there, so same results)

## Out of scope

- Fixing doctor.sh's similar filesystem-based checks (ticket 39 territory)

## Resolution
**Closed:** 2026-07-20 (Resolution backfilled 2026-07-22). Lint's executable check now reads git-stored mode via `git ls-files -s` — non-100755 tracked files fail, untracked .sh files are flagged — eliminating the Windows `core.filemode=false` false positive on bashrc-hook.sh. Evidence: fix commit 47bee2a (check-crosslinks.sh lines 108–120 implement the git-aware check); close commit 711d991 ("both fixes applied and verified").
Closed pre-tkt; unchecked ACs were not individually verified at close.
