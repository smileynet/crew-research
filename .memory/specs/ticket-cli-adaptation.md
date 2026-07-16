---
type: specification
title: "Purpose-Built Ticket CLI (adapted from wedow/ticket)"
status: backlog
---

# Spec: Purpose-Built Ticket CLI

**Status:** Backlog
**Precedent:** ADR 0007 (recall adapted from MemPalace)

---

## Context

`wedow/ticket` (`tk`) is a git-native ticket tracker: single bash script, markdown+YAML frontmatter in `.tickets/`, dependency graphs, priority levels. We use it as-is for now.

Like recall (adapted from MemPalace), we should eventually build an opinionated version tuned to crew-research conventions:

## Adaptations Needed

| tk feature | Our adaptation |
|-----------|---------------|
| `.tickets/` directory | Keep (convention match) |
| Frontmatter schema | Extend: add `spec:` field, `research:` and `spike:` sections |
| `tk ready` (frontier) | Keep + integrate with PLAN.md (update task graph on status change) |
| `tk dep tree` | Keep + emit mermaid DAG for diagrams skill |
| Status states | Customize: open/blocked/active/done (not tk's default priority-based) |
| No GitHub sync | Add: `tk sync` plugin using `gh` CLI |
| No spec awareness | Add: `tk from-spec <path>` generates tickets from a spec file |
| Query output | Extend: structured JSON for agent consumption |

## Non-Goals (use tk as-is)

- File format changes (keep markdown + YAML frontmatter)
- Breaking tk CLI compatibility (our tool should be a superset)
- Server/database (stays file-based, git-native)

## Implementation Approach

Same as recall: purpose-built CLI in `tools/tickets/`, installable via `uv tool install` or direct from repo. Single entry point, <1000 lines target.

## When to Build

When any of:
- tk's frontmatter schema limits our workflow (e.g., can't express spec references cleanly)
- We need PLAN.md auto-update on status transitions
- We want `tk from-spec` to auto-generate tickets from spec files
- GitHub/GitLab sync becomes a requirement

Until then: use `tk` directly + manage schema conventions in the skill.
