# Assumption Tracking

Every plan rests on assumptions. Make them visible before they become load-bearing.

## Process

1. **Surface** — before executing, ask: what must be true for this to work?
2. **Check** — verify against codebase/docs/environment before asking the user
3. **Track** — mark each assumption with status. **Count consecutive confirmations.**
4. **Guard** — if 3+ assumptions confirmed in a row without ANY modification or challenge from the user, INTERRUPT the process (see below)
5. **Report** — include unresolved assumptions in completion

## Rules

- Identify assumptions BEFORE writing implementation code
- One question at a time (don't batch)
- Provide a recommended answer with rationale for each question
- Check the codebase before asking the user — only ask what requires judgment

## Rubber-Stamp Guard (interrupts step 3→4)

**Trigger:** 3 consecutive assumptions confirmed without the user modifying, challenging, or adding nuance to any of them.

**When triggered, STOP the assumption process. Instead of confirming the next assumption, say:**

"Pause — you've confirmed 3 in a row without changes. Before I continue:
- Is there one you'd push back on if you thought about it longer?
- Is [weakest assumption] genuinely safe, or are we moving too fast?

I'd rather slow down now than build on a bad assumption."

**Then:** challenge the weakest assumption yourself with a specific counter-argument or edge case.

**Resume only after** the user either (a) confirms they're genuinely engaged, or (b) modifies at least one assumption.

## Status Markers

- ✓ **Confirmed** — validated by evidence
- ⚠ **Assumed** — proceeding on best guess
- ✗ **Invalidated** — proven wrong
- ◌ **Deferred** — acknowledged, not blocking

## Output Format

```
## Assumptions (N confirmed, N assumed, N invalidated)
- ✓ <assumption> (confirmed: <evidence>)
- ⚠ <assumption> (assumed: <rationale>)
- ✗ <assumption> (invalidated: <what we found>)
```
