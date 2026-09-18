---
name: verification-protocol
description: "Verification steps before reporting work is done. Use when finishing a task, fixing a bug, making changes, confirm your work is correct, reporting done, checking if something works, or validating changes. before committing. Applies to any task where you will report completion."
metadata:
  type: protocol
  invocation: both
  practice: null
  params:
    build_command: ""
    test_command: ""
    lint_command: ""
---

# Verification Protocol

Gate workflow — execute in order before reporting DONE:

## Steps

1. **Identify** — what checks apply to this task type?
2. **Run** — execute the checks (build, test, lint, scope)
3. **Read** — read the output (don't assume pass from exit code alone)
4. **Verify** — output confirms the work is correct
5. **Claim** — report completion only with fresh evidence

## Checks by Task Type

| Task Type | Required Checks |
|-----------|----------------|
| code | build, test, lint, scope |
| config | build, smoke test |
| writing | links, accuracy, formatting |
| research | sources cited, claims verifiable |
| infrastructure | plan review, scope check |

## Scope Check (always applies)

Run `git diff` — changes must be limited to the current task.
Unrelated changes = scope violation. Revert or split.

## Violations (NOT acceptable as verification)

- "Should pass" / "looks fine"
- Trusting a previous run without re-running *(this is about STALE evidence — code changed since; a fresh, read, content-level success signal from an atomic operation is the Calibrated Verification exception below)*
- Skipping checks because "it's a small change" *(size is never the basis; reversibility / blast-radius is — see Calibrated Verification)*
- Claiming done without citing evidence

## Calibrated Verification (narrow, evidence-gated exception)

Scale verification to **reversibility and blast radius — never to diff size** ("it's a small
change" stays a Violation). You MAY skip a redundant re-check ONLY when ALL hold:

- The operation is **atomic / transactional** — it applies fully or not at all AND
  acknowledges completion (an IDE semantic rename, a commit-or-rollback migration). A rebuild
  can't reveal a fault the operation would itself have surfaced.
- Its success signal is **content-level and you READ it** — a terminal event with confirming
  content, never a bare exit code (exit codes lie — see step 3 and the "read the output" rule).
- Pair it with one **high-value anomaly check** where cheap and diagnostic (a rename reporting
  1 site changed when you expected many = wrong target → verify).

This does NOT license skipping build/test/lint on code you authored by hand, and does NOT
license trusting a **stale** prior run. Precedent: enforcement-hierarchy scales the enforcement
*mechanism* by consequence severity; this scales verification *depth* by reversibility.

## Evidence Format

```
Evidence: [command] → [output summary proving correctness]
```

## strReplace Recovery

After strReplace failure ("oldStr not found"):
1. Re-read the target file immediately
2. Find the actual content that needs changing
3. Only then retry with corrected oldStr

Never retry strReplace without re-reading first. After 2 failures on the same file, read it fully and diagnose.

For detailed check commands per project, see [references/project-checks.md](references/project-checks.md).
