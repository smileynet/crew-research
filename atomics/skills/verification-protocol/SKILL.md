---
name: verification-protocol
description: >
  Verification steps before reporting work is done. Use when finishing a
  task, fixing a bug, making changes, confirm your work is correct,
  reporting done, checking if something works, or validating changes.
  before committing. Applies to any task where you will report completion.
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
- Trusting a previous run without re-running
- Skipping checks because "it's a small change"
- Claiming done without citing evidence

## Evidence Format

```
Evidence: [command] → [output summary proving correctness]
```

For detailed check commands per project, see [references/project-checks.md](references/project-checks.md).
