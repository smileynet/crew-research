# Frontier Work

When a project has tickets (`.specs/tickets/`), work the frontier.

## The Rule

The **frontier** = any ticket where `status: open` and all `blocked_by` are `done`.

When tickets exist and no specific task is given:
1. Identify the frontier (scan `.specs/tickets/` frontmatter)
2. Pick the lowest-numbered frontier ticket
3. Propose it: "Next on the frontier: {title}. Start?"

## Working a Ticket

1. Read the ticket file completely
2. Read referenced context (files, specs, ADRs listed in the ticket)
3. Do the work described in "What to build"
4. Verify all acceptance criteria pass
5. Mark done + update plan (see below)

## Marking Done

When a ticket's acceptance criteria are all met:

1. Update the ticket: `status: done`
2. Update `PLAN.md` task graph — mark the ticket complete, note any fog cleared
3. Check if completing this ticket unblocks others — if so, state the new frontier
4. If the completed ticket was the last one: report "All tickets done for this spec"

## Between Tickets

- Do NOT carry implementation context from one ticket to another
- Each ticket starts from its file + referenced context
- If a ticket reveals new work: create a new ticket file, don't expand the current one
- If context is exhausted: `/handoff` and start fresh for the next ticket

## PLAN.md is Authoritative

The plan is the single source of truth for work status. Tickets provide detail; the plan provides the map. Never duplicate status in HANDOFF.md or AGENTS.md — reference the plan instead.
