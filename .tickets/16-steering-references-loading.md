---
id: "16"
title: "Steering references stop defeating progressive loading"
status: done
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

- [x] Decision recorded as an ADR (this changes deployment semantics — hard to reverse quietly)
- [x] Implementation matches the decision; redeploy is idempotent
- [x] Always-on line count measured before/after and recorded
- [x] Skills whose bodies link references still resolve (lint passes)

## Out of scope

- Changing skill reference behavior in `~/.kiro/skills/` (progressive loading works there)

## Resolution (2026-07-18)

**Decision: ADR 0009** — non-eager references deploy as skill companion files, adjacent to SKILL.md in each tool's skills tree (the purpose-built non-eager zone); deployed steering bodies (kiro files and AGENTS.md renders) get links rewritten to absolute paths. Option (b) refined by operator: reuse the skills tree instead of inventing `~/.kiro/references/`.

**Measured always-on cost (managed):** before = 90 lines/turn global (project-checks 46 + tool-limitations 44) + 213 in crew-research sessions (tool-installation.md eager duplicate). After = **0**. Only user-owned `environment-gotchas.md` (160) remains in `steering/references/`, by design.

**Implementation notes:**
- kiro: refs → `~/.kiro/skills/{name}/references/`, recorded in `.crew-skills`; migration removes exactly `project-checks.md tool-limitations.md windows.md unix.md` from the eager dir (user files untouched by construction); OS gate dropped (lazy files cost nothing)
- codex/agy: refs → shared `~/.agents/skills/{name}/references/`; AGENTS.md links rewritten (codex 3, agy 2 — subagent-reliability is tools-scoped without agy); fixed previously-dangling links
- Shared-dir hazard found and fixed: codex+agy share `~/.agents/skills/` with different tool-scoped sets — per-tool manifests (`.crew-skills-{tool}`) stop cross-tool prune flapping (observed: agy repeatedly pruned codex's subagent-reliability)
- Bonus: tool scoping (metadata.tool/tools) now honored in AGENTS.md skills loops + agy CLI loop (mcp-partitioning no longer leaks off-kiro)
- Project orphan converted: `.kiro/steering/references/tool-installation.md` (213-line eager duplicate) deleted; pointer retargeted at the existing `.kiro/skills/tool-installation/` skill, now tracked
- Verified: second deploy = 0 updated/0 pruned on all three tools; lint clean
