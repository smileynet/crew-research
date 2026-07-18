---
name: frontier-work
description: "Always-on: when a project has tickets, work the frontier (first unblocked open ticket), mark done, update plan status."
metadata:
  type: protocol
  invocation: agent-only
  practice: null
---

# Frontier Work

When a project has tickets, work the frontier.

## Ticket Sources (priority order)

Check `$CREW_TICKET_SOURCES` (comma-separated) or default to `local,github`:

1. **local** — scan `.tickets/*.md` frontmatter for `status: open` with all `blocked_by` done
2. **github** — `gh issue list --label ready-for-agent --state open --json number,title,body` (only if `gh` auth'd + GitHub upstream exists)
3. **gitlab** — `glab issue list --label ready-for-agent --opened` (only if GitLab upstream)

Use the first source that returns results. Local always takes priority when `.tickets/` exists.

## The Rule

The **frontier** = any ticket where `status: open` and all `blocked_by` are `done`.

When tickets exist and no specific task is given:
1. Identify the frontier (scan sources in priority order, or run `tk ready` if available)
2. Pick the lowest-numbered frontier ticket
3. Propose it: "Next on the frontier: {title}. Start?"

## Working a Ticket

1. Read the ticket file (or issue body) completely
2. Read referenced context (files, specs, ADRs listed in the ticket)
3. Do the work described in "What to build"
4. Verify all acceptance criteria pass
5. Mark done + update plan (see below)

## Marking Done

When a ticket's acceptance criteria are all met:

1. Update the ticket: `status: done` (local file edit, or `tk close <id>`)
2. If ticket originated from GitHub: `gh issue close <number>` (only if `CREW_TICKET_SYNC=true`)
3. Update `PLAN.md` task graph — mark the ticket complete, note any fog cleared
4. Check if completing this ticket unblocks others — if so, state the new frontier
5. If the completed ticket was the last one: report "All tickets done for this spec"

## Creating Tickets

Ticket creation is a race when 2+ sessions work the same repo (observed twice: archwright 005 pair, crew-research 12/13 collision — both required reconciliation merges).

1. **Claim before allocating:** `git fetch`, then rescan `.tickets/` (local + `origin/main`) for the true max ID
2. **Push promptly:** commit + push the ticket file right after creating it — a pushed ticket is a claim; an unpushed ticket is invisible to other sessions
3. **On collision:** reconcile immediately — merge content into the lower-numbered/pushed ticket (or renumber the newer one), never let both proceed
4. Optional `lane:` frontmatter when sessions have declared work lanes

## Between Tickets

- Do NOT carry implementation context from one ticket to another
- Each ticket starts from its file + referenced context
- If a ticket reveals new work: create a new ticket file, don't expand the current one
- If context is exhausted: `/handoff` and start fresh for the next ticket

## PLAN.md is Authoritative

The plan is the single source of truth for work status. Tickets provide detail; the plan provides the map. Never duplicate status in HANDOFF.md or AGENTS.md — reference the plan instead.
