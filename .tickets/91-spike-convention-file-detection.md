---
id: "91"
title: "Spike: convention-file auto-detection in code-review and adopt-project"
status: open
blocked_by: []
env: either
spec: "eval-harness"
priority: high
---

# Spike: Convention-File Auto-Detection

## Hypothesis

If code-review and adopt-project scan for all known convention files (AGENTS.md, CLAUDE.md,
.cursorrules, .cursor/rules/, copilot-instructions.md, .windsurfrules, .clinerules/, etc.)
and use their content as review criteria, review findings will be more aligned with project
intent without requiring explicit configuration.

## Baseline to measure against

1. **adopt-project**: Currently detects `.kiro/steering/`, `.kiro/skills/`, `.memory/`.
   Does NOT scan for tool-specific convention files from other tools.
2. **code-review**: Currently reviews against diff + project conventions from `.kiro/steering/`
   only. Does not read other convention files as criteria.

**Baseline measurement:**
- Run `code-review` on 3 test repos that have `.cursorrules` or `CLAUDE.md` with explicit
  rules. Count how many review findings align with those rules vs miss them.
- Run `adopt-project` on the same repos. Check if it discovers and reports existing conventions.

## Spike design

1. **Catalogue detection targets** (from research):
   - `AGENTS.md`, `AGENT.md` (root + subdirs)
   - `CLAUDE.md` (root + subdirs)
   - `GEMINI.md` (root + subdirs)
   - `.cursorrules`, `.cursor/rules/*.mdc`
   - `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md`
   - `.windsurfrules`, `.windsurf/rules/*.md`
   - `.clinerules/*`, `.rules/*`

2. **Build a detection function** — scan project root for all patterns, report what's found
   with scoping info (root-level = project-wide, subdir = scoped).

3. **For adopt-project**: Add detection as first step of intake. Report found files, extract
   rules, flag duplicates across files.

4. **For code-review**: Read all found convention files as additional review criteria.
   Priority: `.kiro/steering/` > `AGENTS.md` > tool-specific files.

5. **Test on 3 repos** with different convention file patterns.

## Validation criteria

- [ ] Detection function finds all convention files in test repos (100% recall)
- [ ] code-review produces findings aligned with discovered rules that it previously missed
- [ ] adopt-project reports all found convention files with their scoping
- [ ] No false positives (doesn't treat random .md files as convention files)
- [ ] Skill stays under 100 lines (detection logic in references/)

## Reject if

- Detection adds >2s to review startup (scan should be <100ms)
- Discovered rules conflict with `.kiro/steering/` with no clear priority resolution
- The additional review findings are noise (rules the team actually ignores)

## References

- Research: `.scratch/research/convention-file-autodetect.md`
- CodeRabbit docs: https://docs.coderabbit.ai/knowledge-base/code-guidelines
