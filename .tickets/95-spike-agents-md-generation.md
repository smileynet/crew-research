---
id: "95"
title: "Spike: AGENTS.md generation as cross-tool compatibility layer"
status: open
blocked_by: []
env: either
spec: "eval-harness"
priority: normal
---

# Spike: AGENTS.md Generation as Cross-Tool Compatibility Layer

## Hypothesis

Generating an AGENTS.md during `mise run init` (from steering content) would give teams
using Codex, Cursor, Claude Code, and other tools automatic access to project conventions —
since AGENTS.md is read by ~20 tools natively.

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
