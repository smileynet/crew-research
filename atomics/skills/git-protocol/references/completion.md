# Task Completion Protocol

## Sequence (execute in order after finishing work)
1. **Verification** — confirm all checks pass (gate workflow)
2. **Git** — commit and push verified work
3. **CI Check** — after push, if `.github/workflows/` exists, confirm run triggered
4. **Signaling** — emit structured status signal (see format below)
5. **Followups** — file issues for out-of-scope findings
6. **Handoff** — deliver handoff summary
7. **Memory** — persist lessons/decisions

## Signal Format

```
## DONE
- Task: [what was assigned]
- Result: [what was delivered]
- Evidence: [verification command + output proving it works]
- Remaining: [follow-up work, or "none"]
- Assumptions: [what was assumed but not confirmed, or "none"]
```

For BLOCKED:
```
## BLOCKED
- Task: [what was assigned]
- Blocker: [specific reason]
- Tried: [what was attempted]
- Need: [what would unblock]
```

For FAILED:
```
## FAILED
- Task: [what was assigned]
- Strategies tried: [list of approaches attempted]
- Root cause: [best understanding of why]
- Recommendation: [what to try next or who to ask]
```

## Handoff Elements
1. **Asked → Delivered** — what was requested vs what was produced
2. **State change** — what's different now (before/after)
3. **Files** — what was created/modified/deleted
4. **Issues filed** — follow-up work logged
5. **Next steps** — what to do next (actionable, specific)

## Anti-Patterns
- ❌ "Ready to push when you are" — push NOW
- ❌ Marking done without verification evidence
- ❌ Closing without documenting current state
