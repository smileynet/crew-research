---
name: plan-ticket-sync
description: "Review all tickets for currency, completeness, and ordering. Create tickets for untracked work, update stale ones, and ensure ordering matches the session's established plan. Use when auditing ticket health, after planning, when work feels untracked, or asking 'is everything captured?'. Trigger: sync tickets, ticket review, are tickets current, is everything tracked, ticket audit, ticket hygiene, update tickets, refresh tickets."
metadata:
  type: process
  invocation: both
  practice: null
---

# Plan-Ticket Sync

Review all tickets against session context. Ensure every planned item is tracked, every ticket is current, and ordering reflects the agreed plan.

## Process

### 1. Gather context

Read all open tickets and the current plan (PLAN.md, session decisions, stated priorities). Build a mental map of: what's planned, what's tracked, what's stale.

### 2. Audit each open ticket

For every open/in_progress ticket, check:

| Check | Fix |
|-------|-----|
| Title still reflects the work | Update title to match current understanding |
| Status is accurate (not done but unclosed, or blocked but not marked) | Update status or blocked_by |
| Acceptance criteria are concrete and testable | Rewrite vague ACs |
| Context section has relevant file paths and decisions | Add links to ADRs, specs, CONTEXT.md terms |
| Out of scope is clear | Add boundaries if ambiguous |

### 3. Identify untracked work

Scan session context for work that has no ticket:
- Decisions made that require implementation
- Issues discovered during the session
- Follow-up work from completed tickets
- Planned items with no corresponding ticket

For each gap, create a ticket following the quality standard below.

### 4. New ticket quality standard

Every new ticket MUST have:

- **Intent source** — link to what spawned it (session decision, plan section, ADR, spec, or prior ticket)
- **Key context** — relevant files, decisions, domain terms the implementer needs
- **Desired outcome** — behavioral "What to build" (what the system does, not how to build it)
- **Validation** — concrete, testable acceptance criteria (checkboxes)
- **Ordering** — correct `blocked_by` reflecting dependencies and plan sequence

```bash
tkt new <slug> --title "..." [--blocked-by NN,NN] [--priority P]
```

Then fill the body with the full template (What to build, Context, ACs, Out of scope).

### 5. Order tickets to match the plan

Ensure `blocked_by` edges create the intended work sequence:
- Items the plan says come first should block items that come later
- Priority reflects urgency agreed in session (urgent > high > medium > low)
- No circular dependencies

```bash
tkt validate --brief   # catches cycles and broken deps
```

### 6. Verify

```bash
tkt sync-plan --check --brief   # plan↔ticket status agreement
tkt validate --brief            # structural health
tkt ready                       # frontier matches expectations
```

Present: tickets created, tickets updated, current frontier.

## Does NOT

- Pick what to work on next (that's `frontier-work`)
- Decompose a spec from scratch (that's `ticket-planning`)
- Create specs or features (that's `spec-driven-development`)
- Change the plan itself — it reflects the plan into tickets
