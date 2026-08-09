---
id: "95"
title: "Spike: AGENTS.md generation as cross-tool compatibility layer"
status: open
blocked_by: []
env: either
spec: "eval-harness"
priority: low
---

# Spike: AGENTS.md Generation as Cross-Tool Compatibility Layer

## Finding (2026-08-09): Partially Already Implemented

init.sh ALREADY generates AGENTS.md in two contexts:
1. **Global deploy for codex/crush/agy**: `deploy_agents_md_tool()` renders steering INTO
   an AGENTS.md at each tool's native path. Full steering content.
2. **Project scaffold**: Generates a template AGENTS.md with workspace layout, commands,
   skill references. Does NOT include steering content.

The remaining gap: project-level AGENTS.md is a static template, not a rendering of
steering rules. Other tools reading `$PROJECT/AGENTS.md` get workspace info but NOT the
conventions from `.kiro/steering/` (verification protocol, code hygiene, etc.).

## Revised hypothesis

Enriching the project scaffold AGENTS.md with key steering rules (rendered, not symlinked)
would make conventions visible to Codex/Claude Code/Cursor when working in that project
without additional setup. The global AGENTS.md already works for global deploys — this is
about the project-level gap.

## Baseline to measure against

1. **Current state**: init.sh deploys to tool-specific paths only. A kiro-cli project has
   no AGENTS.md readable by other tools unless manually created.
2. **Cross-tool coverage**: With kiro-cli only → 1 tool reads conventions. With AGENTS.md → ~20.
3. **Drift risk**: Deploy, hand-edit AGENTS.md, re-deploy. What happens? (Currently: nothing.)

## Spike design

1. **Define AGENTS.md content** (subset of steering, ≤150 lines):
   - Project layout, build commands, key constraints
   - NOT verbose skill content or tool-specific paths
2. **Generation logic**: Extract from deployed steering (project-conventions, verification-protocol, CONTEXT.md glossary).
3. **Drift management options**:
   - A: Generate once, mark user-owned (never regenerate)
   - B: Regenerate on deploy, warn if user edits detected
   - C: Managed section markers; user adds below
4. **Test**: Deploy, verify Codex/Claude Code/Cursor read it correctly.

## Validation criteria

- [ ] Generated AGENTS.md readable by ≥3 different tools
- [ ] Content stays ≤150 lines (Claude Code's effective limit)
- [ ] Round-trip: deploy → tool reads → hand-edit → redeploy → no data loss
- [ ] No duplication with `.kiro/steering/` (references, not copies)
- [ ] `mise run doctor` can detect drift between AGENTS.md and steering source

## Reject if

- Drift management unsolvable (any option → user confusion or data loss)
- Generated content too generic to be useful
- Encourages maintaining conventions in two places (violates single source of truth)

## References

- Research: `.scratch/research/convention-file-autodetect.md`
- init.sh: `tools/generator/init.sh`
- agents-md-authoring skill: `~/.kiro/skills/agents-md-authoring/SKILL.md`
