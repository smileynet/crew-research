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

For every open/in_progress ticket, check for real drift:

- **Stale blocked_by** — a dependency is done but blocked_by still lists it (ticket should be on the frontier but isn't)
- **Missing blocked_by** — work can't actually start without another ticket, but no edge declared
- **Vague ACs** — criteria use "properly", "correctly", "as expected" instead of testable conditions
- **Dead context** — file paths that moved, ADRs that were superseded, specs that changed
- **Superseded work** — the plan changed and this ticket no longer reflects what's needed (→ close or rewrite)
- **Scope creep** — ticket grew during discussion but wasn't split

For each issue: fix in place (edit frontmatter/body), or if the ticket is no longer relevant, close it with a note or move to `status: backlog`.

### 3. Identify untracked work

Scan session context for work that has no ticket:
- Decisions made that require implementation
- Issues discovered during the session
- Follow-up work from completed tickets
- Planned items with no corresponding ticket

For each gap, create a ticket following the quality standard below.

After creating tickets, add them to the plan — every open ticket needs a plan row so `tkt sync-plan --check` passes clean. Place new rows in the appropriate plan section with correct status.

### 4. New ticket quality standard

Apply the tkt skill's ticket-standards (if the tkt skill is loaded, read `references/ticket-standards.md`; otherwise apply the checklist below).

Every new ticket MUST have:

- **Intent source** — link to what spawned it (session decision, plan section, ADR, spec, or prior ticket)
- **Key context** — relevant files, decisions, domain terms the implementer needs
- **Desired outcome** — behavioral "What to build" (what the system does, not how to build it)
- **Validation** — concrete, testable acceptance criteria + `validation_criteria` frontmatter
- **Ordering** — correct `blocked_by` and priority (see step 5)

```bash
tkt new <slug> --title "..." [--blocked-by NN,NN] [--priority P]
```

Then fill the body with the full template (What to build, Context, ACs, Out of scope). A ticket that fails the quality bar wastes the implementer's context window.

### 5. Set ordering

Two independent axes — don't conflate them:

**Dependencies** (`blocked_by`): structural — A must finish before B can start.
- Only add blocked_by when there's a real technical or logical dependency
- "We want to do A first" is NOT a blocked_by — that's priority

**Priority**: urgency — among unblocked tickets, what matters most.
- Set via `tkt edit <id> --priority high|medium|low`
- Reflects session agreement on what's urgent vs what can wait

```bash
tkt validate --brief   # catches cycles and broken blocked_by refs
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
