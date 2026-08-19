# Phase Checklist

Detailed checks for each project-cleanup phase. The orchestrator (SKILL.md) auto-detects which phases apply; this reference provides the full checklist when a phase fires.

## Phase 2: Scratch Promotion

| File pattern | Action |
|--------------|--------|
| Completed handoffs (superseded) | Delete |
| Research findings with lasting value | Promote → `.memory/specs/` |
| Decisions made this session | Write ADR if ADR-worthy, else delete |
| One-time investigation notes | Delete |
| Active plans/working docs | Keep |

Decision criteria: "Will a future session need this?" If yes → promote. If no → delete.

## Phase 3: CONTEXT.md Scope Enforcement

The disambiguation gate: "Could two people mean different things by this word?"

| Entry type | Passes? | Route if fails |
|-----------|---------|----------------|
| Domain term with _Avoid_ alias | ✅ | — |
| Naming decision (chose X over Y) | ✅ | — |
| Abbreviation/acronym definition | ✅ | — |
| Operational gotcha/workaround | ❌ | AGENTS.md Constraints |
| Implementation detail/spec | ❌ | `.memory/specs/` |
| Decision with rationale | ❌ | `.memory/adr/` or delete |
| Process/workflow instruction | ❌ | AGENTS.md or skill |
| Stale/deprecated term | ❌ | Delete |

After routing, each remaining entry must fit: **Term** + one-sentence definition + _Avoid_ (≤3 lines).

## Phase 4: AGENTS.md Role Enforcement

| Check | Violation | Fix |
|-------|-----------|-----|
| Contains `**Term**:` + `_Avoid_:` pattern | Glossary content leaked in | Move to CONTEXT.md |
| Section >10 lines on one topic | Inline spec | Extract to `.memory/specs/`, leave link |
| Total >150 lines | Over budget | Extract detail to docs, or recommend `/agents-md-authoring` |
| Commands don't work | Stale | Update or remove |
| Referenced paths don't exist | Drift | Update or remove |
| Missing Constraints section | No gotcha home | Add section header |

## Phase 5: Ticket Sync

Run `tkt sync-plan --check --brief`. Address findings per `/plan-ticket-sync`:
- plan-status-drift → `tkt sync-plan --fix`
- missing-plan-row → add ticket to plan
- missing-ticket → create ticket or remove stale plan reference

## Phase 6: Guidance Capture

Run guidance-sync probes (from working session memory, not subagent):
- **P1 Corrections** — user corrected agent this session → rule candidate
- **P2 Friction** — work stalled or needed archaeology → doc/skill fix
- **P3 New knowledge** — gotchas → AGENTS.md; terms → CONTEXT.md; specs → `.memory/`
- **P4 Repetition** — manual 2+ times → script or skill candidate

Apply trivial fixes directly (stale syntax, dead links). Non-trivial → create ticket.

## Phase 7: Dependency & Config (if time)

- Scripts reference tools that are installed?
- Untracked files that should be committed or gitignored?
- Merged branches to delete?
