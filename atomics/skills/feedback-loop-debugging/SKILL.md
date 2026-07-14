---
name: feedback-loop-debugging
description: "Build a pass/fail signal BEFORE attempting fixes. Use when debugging, diagnosing failures, tests failing, errors recurring, or when a fix didn't work. Trigger: debug, failing test, broken, not working, TypeError, error output, diagnose."
metadata:
  type: protocol
  invocation: both
  practice: null
---

# Feedback Loop Debugging

**This is the skill.** A tight feedback loop that goes red on the bug is 90% of debugging. Everything else is mechanical.

## The Gate (non-negotiable)

**You MUST have a running, failing command before you touch source code.**

If you catch yourself reading code to build a theory before a failing command exists — STOP. That impulse is the exact failure this skill prevents. No failing command, no fix attempt.

## Phase 1: Build the Loop (spend disproportionate effort here)

Try each until one works:

1. **Existing failing test** — `npx vitest run path/to/test` — already have it? Run it now.
2. **Targeted new test** — write one that exercises exactly the broken behavior.
3. **CLI one-liner** — `node -e "require('./src').fn(badInput)"` reproducing the symptom.
4. **Script harness** — 5-line script: setup → call → assert → exit 0/1.
5. **Bisection** — `git bisect run <test-command>` when you know it worked before.

Be aggressive. Be creative. Refuse to give up on getting a loop.

### Phase 1 is DONE when:

- [ ] You can name ONE command that goes red on this bug
- [ ] You have ALREADY RUN IT and seen it fail (paste the output)
- [ ] It asserts the user's EXACT symptom (not "didn't crash" — the specific error)
- [ ] It runs in seconds, not minutes

All four must be true. If any is missing, you're still in Phase 1.

## Phase 2: Red → Green Loop

```
1. Run loop → FAIL (confirms bug exists)
2. Make ONE change (single variable)
3. Run loop → check result
   - PASS → verify full test suite, done
   - FAIL → revert, try different hypothesis
```

**One change at a time.** If you change two things and it passes, you don't know which fixed it.

## Phase 3: Verify

- Original symptom no longer reproduces
- Full test suite passes (not just your loop)
- No debug artifacts left behind

## Cannot Build a Loop?

After 3 genuine attempts: STOP. Do not guess at fixes. State:
1. What you tried (specific commands)
2. Why each didn't produce a signal
3. What you need (access, repro steps, environment, logs)

## Anti-Patterns (immediate score 1 in any review)

- Reading code and guessing at a fix without reproducing
- Saying "I think the issue is..." without a failing command
- Running full test suite as your loop (too slow, too noisy)
- Modifying code then writing a passing test (proves nothing)
- Changing multiple things between loop runs
