---
id: "133"
title: "Trim CONTEXT.md HOW-clauses + AGENTS.md over-budget (197>150)"
status: backlog
blocked_by: []
validation_criteria:
  - "CONTEXT.md entries are pure term+def+avoid (HOW-clauses moved to spec); AGENTS.md <=150 lines with Recall dedup"
---

# Trim CONTEXT.md HOW-clauses + AGENTS.md over-budget (197>150)

## Intent source

`/project-cleanup` 2026-08-28 — unbiased subagent review of CONTEXT.md (35 entries)
and AGENTS.md (197 lines). Findings preserved at `.scratch/cleanup/context-review.md`
and `.scratch/cleanup/agents-review.md` (regenerate if scratch cleared).

## Context

**CONTEXT.md** (35 entries, glossary-only contract): review verdicts —
- KEEP 31, but ~14 embed a HOW-clause (paths, computation rules, storage internals,
  deploy triggers) that should be trimmed out, leaving pure term + definition + _Avoid_.
- MOVE-spec 3: #3 Canonical format, #8 Skill type, #21 Three-tier deployment → a new
  `.memory/specs/deployment-model.md` can absorb these + the trimmed HOW-clauses.
- MOVE-agents 1: #23 Steering shadow (activation evals read 0 TPR while behavior is
  correct — an operational gotcha, belongs in AGENTS.md Constraints).
- DELETE 0.

**AGENTS.md** (197 lines, 47 over the 150 cap): route to `/agents-md-authoring`.
- V2a Commands block (~80 lines): trim ~25-30 lines of commentary duplicating the
  tkt skill (birth-flow, tk-not-tkt) and user-setup-guide.md (CREW_ENV gating).
- V2b Recall Operations block (~26 lines): DUPLICATES the Recall subsection already
  in Commands — merge/delete (nearly closes the whole overage alone).
- Glossary patterns + commands/paths verified CLEAN.

## What to build

1. New `.memory/specs/deployment-model.md` absorbing the 3 MOVE-spec entries + trimmed HOW-clauses.
2. Trim all 35 CONTEXT.md entries to term + definition + _Avoid_ (≤3 lines each).
3. Move #23 Steering shadow → AGENTS.md Constraints (do this as part of the AGENTS trim, not before).
4. Run `/agents-md-authoring`: merge duplicate Recall block, trim Commands commentary → ≤150 lines.

## Acceptance criteria

- [ ] CONTEXT.md: every entry ≤3 lines, pure term+definition+_Avoid_, no HOW-clauses
- [ ] 3 MOVE-spec entries relocated to `.memory/specs/deployment-model.md`
- [ ] #23 Steering shadow moved to AGENTS.md Constraints
- [ ] AGENTS.md ≤150 lines; duplicate Recall block merged; commands still valid
- [ ] `mise run validate` + lint pass

## Out of scope

- Deleting CONTEXT entries (none warranted)
- Content changes beyond relocation/trim (no new rules)

- [ ] TBD
