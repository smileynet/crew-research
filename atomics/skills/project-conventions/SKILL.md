---
name: project-conventions
description: "Workspace conventions and skill customization guidance. Always loaded."
metadata:
  type: reference
  invocation: agent-only
---

# Project Conventions

## Skill Customization

Skills have a `params:` section in frontmatter with project-specific values. When you encounter a skill referencing a command or path that doesn't match this project, check `.crew-config.yaml` for the correct values.

### Adjusting verification commands
Edit `.crew-config.yaml`:
```yaml
params:
  verification-protocol:
    build_command: "your build command"
    test_command: "your test command"
    lint_command: "your lint command"
```

### Adding project-specific context to a skill
Create a file in the skill's `references/` directory:
```
.kiro/skills/testing-guide/references/project-patterns.md
```
The agent reads references on-demand when it needs more detail.

### Removing unwanted behavior
- Delete `.kiro/steering/{name}.md` to remove always-on rules
- Delete `.kiro/skills/{name}/` to remove an on-demand skill
- Skills don't affect each other — removing one won't break others

## Document Placement

| What | Where |
|------|-------|
| Working notes, research | `.scratch/` |
| Lasting decisions, glossary | `.memory/` |
| User-facing docs | `docs/` (only when requested) |

## Session Workflow

1. Start: `@read-handoff` (if continuing prior work)
2. Work: skills activate automatically based on what you're doing
3. End: `@handoff` (captures state for next session)
4. Periodic: `@workspace-cleanup` (consolidate artifacts)
