# Skill Review Verdicts — 2026-07-16

53 skills reviewed in 8 subagent batches (batch1-8.md in this dir have full detail with quoted evidence).

## Summary

| Verdict | Count | Skills |
|---------|:-----:|--------|
| KEEP | 32 | handoff, read-handoff, plan-prereqs, feedback-loop-debugging, code-review, testing-guide, diagrams, research-output, writing-style, agents-md-authoring, changelog-discipline, init-project, project-winddown, docs-audit, fiction-craft, world-building, prototype-protocol, ux-walkthrough, deployment-safety, image-handling, source-authority, verification-protocol, recall-check, recall-session-start, git-protocol, eval-criteria, ... |
| FIX | 20 | see table below |
| MERGE | 1 | troubleshooting-protocol (into feedback-loop-debugging, or re-scope) |
| RETIRE | 0 | — |

## Fix List (prioritized)

### P0 — broken functionality

| Skill | Issue | Fix |
|-------|-------|-----|
| multi-agent-validation | NO frontmatter (can't activate); 177 lines; orphan reference; in NO tier | Add frontmatter, dedupe inline invocation vs references/, add to full tier |
| tutorial-authoring | Diátaxis comparison table has header but ZERO data rows | Fill rows or link docs-audit's diataxis reference |
| adr-authoring | Storage path `docs/adrs/` contradicts repo-wide `.memory/adr/` convention (8 other skills) | Align path; remove stale jargon ("warlock output, BPAPPA survey") |

### P1 — stale/contradictory content

| Skill | Issue | Fix |
|-------|-------|-----|
| cheatsheet | Lists five-whys + session-review-patterns (don't exist post-consolidation) | Remove rows; consider generating from `mise run catalog` |
| poc-workflow | Orphan cheatsheet describing superseded phase model; trigger collision with prototype-protocol | Rewrite/delete cheatsheet; rename trigger |
| study-reference | Output path contradicts its own template (.memory/ vs .scratch/research/) | Align paths |
| study-all-references | Incompatible section schema vs study-reference for same artifact; missing dot in `.references/` | Delegate structure to study-reference |
| research-methodology | 3 competing output formats (inline vs research-output vs dispatch-pattern ref) | Point to research-output canonical |
| architecture-deepening | TWO "## Vocabulary" sections pointing at near-duplicate reference files | Merge files, delete dupe section |
| enforcement-hierarchy | practice: null contradicts body's "Source practice:" claim; dead external pointers | Reconcile |
| troubleshooting-protocol | Trigger collision + CONFLICTING Phase 1 vs feedback-loop-debugging; five-whys.md routes to 3 non-existent skills | Merge or re-scope to RCA/postmortem only |

### P2 — line budget violations (no justification)

| Skill | Lines | Fix |
|-------|:-----:|-----|
| grill-with-docs | 166 | Extract research protocol to reference; delete Project Customization dup |
| subagent-reliability (steering) | 137 | Dedupe "never inline" (stated 3×); link tool-limitations.md |
| planning-cycles | 125 | Compress spike/tracer table to pointer |
| script-authoring | 121 | Move cross-platform section to references/ |
| project-cleanup | 116 | Dedupe vs init-project; parameterize hardcoded lint path |
| spec-driven-development | 116 | Move PLAN.md template to references/ |
| vertical-slice-planning | 111 | Delete do-nothing Step 1 stub |

### P3 — one-line fixes

| Skill | Fix |
|-------|-----|
| recall | Link orphaned references/cli-reference.md |
| adopt-project | Link orphaned references/project-notes.md |
| skill-authoring | Add its own scope boundary (violates own gate G3) |
| presentation-writing, readme-writing, project-winddown, recall | Add missing metadata.practice key |
| project-audit | Delete duplicate check 6 |

### Steering-specific (always-on cost)

| File | Lines (effective) | Fix |
|------|:-----:|-----|
| project-conventions | ~318 (incl. refs deployed globally) | Cut system-prompt dups; demote tool-installation.md to project-level; OS-gate windows.md |
| ai-generation-hygiene | 93 | States same 9 rules 3× — collapse to ~40 |
| context-budget-awareness | 44 | "When to Restart" conflicts with system prompt context_awareness |

Batch 5 total: 812 always-on lines → post-fix target ~450.

## Cross-Cutting Issues (feed into other tickets)

1. **Lint gap (→ R6):** no validation that SKILL.md has frontmatter, or that every skill is in ≥1 tier or documented as project-level. multi-agent-validation slipped both.
2. **metadata.practice inconsistency:** standardize (require `practice: null` explicitly or drop the field).
3. **Dead external pointers:** "best_practices repo", "agent-crews/shared" — repo-wide sweep needed.
4. **Steering references deploy eagerly (→ R6):** generator copies references/ into steering dir, defeating progressive loading and inflating always-on cost.
5. **Research output format fragmentation:** 3 templates across research-methodology, research-output, dispatch-pattern.
6. **Path convention:** `.references/` vs `references/` inconsistent across study skills.
