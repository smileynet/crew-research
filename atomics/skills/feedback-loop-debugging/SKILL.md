---
name: feedback-loop-debugging
description: "Build a pass/fail signal BEFORE attempting fixes. Use when debugging, diagnosing failures, tests failing, errors recurring, or when a fix didn't work. Trigger: debug, failing test, broken, not working, TypeError, error output, diagnose."
metadata:
  type: protocol
  invocation: both
  practice: null
---

# Feedback Loop Debugging

The #1 debugging technique: construct a reliable pass/fail signal, then iterate against it.

## Rule

**Do NOT modify source code until you have a feedback loop that fails.**
A feedback loop = a command you can run that outputs PASS or FAIL for the specific bug.

## Constructing the Loop (ordered by simplicity)

Try each until one works:

1. **Existing failing test** — `npx vitest run path/to/test` — already have it? Use it.
2. **Targeted new test** — write a test that exercises exactly the broken behavior.
3. **CLI invocation** — `node -e "require('./src/mod').fn(badInput)"` or equivalent one-liner.
4. **curl/HTTP** — `curl -s localhost:3000/endpoint | jq .field` for API bugs.
5. **Script harness** — 5-line script that sets up state, calls the function, checks output.
6. **REPL probe** — interactive session to isolate the behavior, then capture as script.
7. **Bisection** — `git bisect run <test-command>` when you know it worked before.
8. **Differential** — run same input on working version vs broken version, diff output.
9. **Property/fuzz** — when the failure is non-deterministic, generate random inputs until it triggers.
10. **HITL script** — when automated checking is impossible, script that prints state for human verdict.

## Using the Loop

Once you have a loop, **tighten it** — make it faster, sharper, more deterministic. A tight loop is a debugging superpower. For optimization strategies, read [references/tighten.md](references/tighten.md).

```
1. Run loop → FAIL (confirms bug exists)
2. Make ONE change
3. Run loop → PASS or FAIL?
   - PASS → verify full test suite, done
   - FAIL → revert change, try different approach
```

## Cannot Build a Loop?

If after 3 attempts you cannot construct a feedback loop:
1. STOP attempting fixes
2. State what you tried and why it didn't produce a signal
3. Ask for: access, reproduction steps, environment details, or logs

## Phase Gates

- **Do not proceed to fixing** until the loop demonstrates FAIL
- **Do not declare fixed** until the loop demonstrates PASS
- **Do not modify multiple things** between loop runs

## Anti-Patterns

- Reading code and guessing at a fix without reproducing
- Running the full test suite as your loop (too slow, too noisy)
- Modifying the code, then writing a test that passes (proves nothing)
- Retrying the same fix hoping for a different result
