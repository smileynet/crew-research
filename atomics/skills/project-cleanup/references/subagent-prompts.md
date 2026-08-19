# Subagent Dispatch Templates

Templates for the subagent calls in project-cleanup Phases 3 and 4. These run in fresh sessions with no working-session bias.

## CONTEXT.md Review (Phase 3)

Write task file to `.scratch/subagent-input/context-review.md`, then dispatch:

```
Read {project}/.memory/CONTEXT.md.

For each entry, apply the disambiguation gate: "Could two people mean different things by this word?"

- YES → keep (trim to ≤3 lines: term + definition + _Avoid_)
- NO → route to the appropriate staging file:
  - Operational gotcha/environment fact → .scratch/context-cleanup/move-to-agents.md
  - Implementation detail/spec → .scratch/context-cleanup/move-to-spec.md
  - Decision with rationale → .scratch/context-cleanup/move-to-decisions.md
  - Stale/duplicate → delete (don't stage)

Write:
1. The cleaned CONTEXT.md (only passing entries)
2. Staging files for routed content (with section explaining where each item should go)

Preserve any YAML frontmatter at the top of CONTEXT.md.
```

## AGENTS.md Review (Phase 4)

Write task file to `.scratch/subagent-input/agents-review.md`, then dispatch:

```
Read {project}/AGENTS.md.

Check for role violations:
1. Term definitions with `_Avoid_` notes → belongs in .memory/CONTEXT.md
2. Inline content >10 lines on one topic without a link → extract to .memory/specs/
3. Total line count (report if >150)
4. Commands section: are commands verifiable? (expected output/exit code)
5. Referenced file paths: do they exist?

Write findings to .scratch/subagent-raw/agents-review.md:
- List each violation with line numbers and proposed fix
- Classify severity: HIGH (wrong content type), MEDIUM (over budget), LOW (stale ref)
- If >3 HIGH findings, recommend /agents-md-authoring full rewrite
```

## When to Skip Subagent Dispatch

- CONTEXT.md has <20 entries and all are ≤3 lines → skip Phase 3
- AGENTS.md is <100 lines with no `_Avoid_` patterns → skip Phase 4
- Working session didn't touch either file → skip both (no drift this session)

## After Subagent Returns

1. Read the staging files
2. Integrate `move-to-agents.md` content into AGENTS.md Constraints section
3. Review `move-to-spec.md` — create spec file if valuable, discard if not
4. Review `move-to-decisions.md` — write ADRs for ADR-worthy items, discard rest
5. Commit the cleaned files together
