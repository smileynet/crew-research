---
name: plan-ticket-sync
description: "Reconcile PLAN.md and .tickets/ — ensure all planned work has tickets, all tickets are current, and ordering matches the plan. Use when auditing plan-ticket drift, after closing tickets, when the plan feels stale, or when asking 'is everything tracked?'. Trigger: sync plan, plan drift, are tickets current, is everything tracked, reconcile plan, plan audit, ticket hygiene, update plan."
metadata:
  type: process
  invocation: both
  practice: null
---

# Plan-Ticket Sync

Reconcile PLAN.md and `.tickets/` so neither lies. The plan is the map; tickets are the work units. Both must agree.

## When to Run

- After closing tickets (plan rows may be stale)
- After creating tickets (plan may be missing rows)
- After changing priorities or dependencies
- Periodically (weekly or at session start if drift suspected)
- When asked "is everything tracked?" or "what's the current state?"

## Process

### 1. Automated drift check

```bash
tkt sync-plan --check --brief
```

This reports:
- **plan-status-drift** — ticket is done but plan says not done (or vice versa)
- **missing-plan-row** — open ticket has no entry in the plan
- **missing-ticket** — plan references a ticket that doesn't exist

If `tkt` is not on PATH, perform manually: compare plan rows against `.tickets/*.md` frontmatter.

### 2. Fix derivable drift

```bash
tkt sync-plan --fix
```

Auto-fixes status columns in the plan to match ticket status. Report what changed.

If `--fix` is insufficient (structural issues), proceed to manual steps below.

### 3. Manual reconciliation (findings that --fix can't resolve)

| Finding | Action |
|---------|--------|
| Missing plan row | Add the ticket to the appropriate plan section |
| Missing ticket | Create ticket (`tkt new`) or remove stale plan reference |
| Ordering mismatch | Reorder plan rows to match current priority + dependency graph |
| Orphan ticket (no plan context) | Assign to a plan section or mark `status: backlog` |
| Completed phase still open | Close all remaining tickets or document why they're deferred |

### 4. Verify clean

```bash
tkt sync-plan --check --brief
# Expected: pass (0 findings)
tkt validate --brief
# Expected: pass (only historical warnings on closed tickets)
```

### 5. Commit

Commit the reconciled plan and any ticket updates together:
```
chore(plan): reconcile plan-ticket drift (N fixes)
```

## What This Skill Does NOT Do

- Create new features or specs (that's `spec-driven-development`)
- Decompose specs into tickets (that's `ticket-planning`)
- Pick what to work on next (that's `frontier-work`)
- Change ticket content or acceptance criteria

## Quality Check

After sync, verify:
- Every open ticket appears in the plan
- Every plan row marked incomplete has a corresponding open/in_progress ticket
- Dependency ordering in plan matches `blocked_by` in tickets
- No ticket is both `done` and listed as incomplete in the plan
