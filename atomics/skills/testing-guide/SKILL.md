---
name: testing-guide
description: "Testing patterns and practices for writing effective tests. Use when writing tests, reviewing test quality, or deciding what to test."
metadata:
  type: reference
  invocation: both
  practice: null
---

# Testing Guide

## Phase 0: What Are We Protecting?

Before writing tests, state in user terms what behavior matters:
- "When a user submits a form with invalid email, they see an error — not a crash"
- "When the payment service is down, orders queue instead of failing silently"
- "When config changes, the app picks it up without restart"

These become your test descriptions. If you can't state what you're protecting, you're not ready to test.

## Who Benefits (JTBD)

| When I'm... | I want tests that... | So I can... |
|-------------|---------------------|-------------|
| Refactoring | Prove behavior unchanged | Move fast without fear |
| Fixing a bug | Prove the bug existed and is now fixed | Prevent regression |
| Reviewing a PR | See what's covered | Trust the change |
| Onboarding | Understand the contract | Read tests as documentation |

## What to Test

| Priority | Test Type | What It Catches |
|:--------:|-----------|-----------------|
| 1 | Happy path | Core functionality broken |
| 2 | Error paths | Unhandled failures |
| 3 | Edge cases | Boundary conditions |
| 4 | Integration | Components don't connect |

## Test Structure (AAA)

```
// Arrange — set up preconditions
// Act — perform the action
// Assert — verify the outcome
```

One behavior per test. If a test name needs "and", split it.

## Naming Convention

`{unit}_{scenario}_{expected}` or describe/it blocks:
- `parseConfig_missingFile_throwsError`
- `it("returns empty array when no items match")`

## Rules

- Test behavior, not implementation (don't test private methods)
- Tests must be deterministic (no timing, no randomness, no network)
- Each test independent (no shared mutable state between tests)
- Fast: unit tests <100ms each, suite <10s total
- Readable: a failing test name tells you what broke

## When to Write Tests

- Before fixing a bug (prove it exists, then prove it's fixed)
- After implementing a feature (cover the contract)
- When refactoring (prove behavior unchanged)

## Coverage Targets

| Project Type | Target | Focus |
|-------------|--------|-------|
| Library/SDK | 80%+ | Public API surface |
| Application | 60%+ | Business logic, error paths |
| Script/CLI | Key paths | Happy path + common errors |

## Anti-Patterns

| Pattern | Problem |
|---------|---------|
| Testing implementation details | Breaks on refactor |
| Shared mutable state | Order-dependent failures |
| Sleeping/timing | Flaky in CI |
| Asserting too much | Unclear what failed |
| No assertion at all | Test always passes |
| Mocking everything | Tests prove nothing |
