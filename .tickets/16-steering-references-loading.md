---
id: "16"
title: "Steering references stop defeating progressive loading"
status: open
blocked_by: []
spec: "session-improvements-2026-07-17"
---

# Steering references stop defeating progressive loading

## What to build

A decision plus implementation for how steering companion files deploy. Today every file under `~/.kiro/steering/references/` loads eagerly on EVERY turn, defeating the progressive-loading design and silently inflating always-on cost (batch5 cross-cutting finding #1; it forced ticket 04 to demote tool-installation.md rather than simply link it).

## Context

- **Options surfaced in review:** (a) generator inline-trims references for steering targets, (b) deploy references outside the steering dir with explicit read-on-demand pointers (ADR-0002 pointer pattern), (c) accept eager loading and budget for it explicitly
- **Files:** `tools/generator/init.sh` (steering reference deploy loop, ~line 179), `.memory/review-2026-07/batch5.md` (evidence)
- **Current eager reference cost:** project-checks.md (46) + tool-limitations.md (44) + user's environment-gotchas.md (141, unmanaged)
- **Hazard:** any prune logic for references needs a symlink/allowlist escape — unmanaged user files live in that dir (see doctor's new drift warning)

## Acceptance criteria

- [ ] Decision recorded as an ADR (this changes deployment semantics — hard to reverse quietly)
- [ ] Implementation matches the decision; redeploy is idempotent
- [ ] Always-on line count measured before/after and recorded
- [ ] Skills whose bodies link references still resolve (lint passes)

## Out of scope

- Changing skill reference behavior in `~/.kiro/skills/` (progressive loading works there)
