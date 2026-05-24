---
metadata:
  type: protocol
  invocation: both
  practice: null
name: ai-generation-hygiene
description: Eliminate common AI-generation artifacts from produced code. Always active during code generation — catches redundant checks, gratuitous logging, restating comments, unnecessary casts, and over-abstraction before they enter the codebase.
---
metadata:
  type: protocol
  invocation: both
  practice: null

# AI Generation Hygiene

Source of truth: `/home/sam/code/best_practices/docs/practices/ai-generation-hygiene.md`

Every line of generated code must earn its place. Cut until cutting would lose meaning.

## Trigger Conditions

Activate when:
- Writing new code (any language)
- Modifying existing code
- Reviewing AI-generated code before commit
- Refactoring or cleaning up generated output

Always active — this skill applies to all code generation, not just explicit review.

## Required Patterns

**Trust the type system.** MUST NOT add null/type checks on values the type system already guarantees. If a parameter is typed non-optional, it cannot be None. Check only at trust boundaries (user input, network data, deserialization).

**Catch specific, handle meaningful.** MUST NOT wrap code in broad try/except that catches, logs, and re-raises unchanged. Only catch exceptions you can handle — recover, degrade gracefully, or transform to domain exceptions.

**Comments explain why.** MUST NOT add comments that restate the code. Comments earn their place by documenting: non-obvious constraints, regulatory requirements, rejected alternatives, coupling that isn't visible locally.

**Log events, not presence.** MUST NOT add entry/exit logging or parameter echoing. Log state transitions, business decisions, errors — things that answer "what happened?" during an incident.

**No redundant casts.** MUST NOT cast values to types they already are. `str(f"...")` is redundant. `list([...])` is redundant. `int(len(...))` is redundant.

**No single-use abstractions.** SHOULD NOT create classes, factories, or wrappers for things used exactly once. Direct code is clearer than indirection without reuse.

**No defensive copies without mutation.** SHOULD NOT copy data structures when nothing in the call chain mutates them.

**Direct expressions over verbose conditionals.** SHOULD prefer `return value > 0` over `if value > 0: return True else: return False`.

**Import only what you use.** MUST NOT leave unused imports. Each import is a dependency claim — false claims confuse readers and tools.

## Banned Patterns

**Redundant defensive checks (P1).** `if x is None: raise` when x is typed non-Optional.

**Catch-everything (P2).** `except Exception as e: logger.error(e); raise` — adds noise, helps no one.

**Restating comments (P3).** `counter += 1  # increment counter` — the code already says this.

**Gratuitous logging (P4).** `logger.info("Entering process_payment")` — entry/exit logging is debugging scaffolding.

**Redundant casts (P5).** `str(f"hello")`, `list([1,2,3])`, `int(len(x))`.

**Single-use abstractions (P6).** Factory classes instantiated once. Wrapper functions called once.

**Unnecessary defensive copies (P7).** `.copy()` when nothing mutates the original.

**Verbose conditionals (P8).** `if x: return True else: return False` instead of `return x`.

**Unused imports (P9).** Importing modules or symbols never referenced in the file.

## Self-Check Before Commit

Scan generated code for these 9 patterns. Each "yes" is a line that doesn't earn its place:

1. Null checks on non-optional parameters?
2. Try/except that only logs and re-raises?
3. Comments restating the line below?
4. Entry/exit logging?
5. Type casts on values already of that type?
6. Abstractions used exactly once?
7. Defensive copies where nothing mutates?
8. Verbose conditionals reducible to expressions?
9. Unused imports?

## When to Keep It

Keep defensive code at **trust boundaries** — where values enter from outside your control:
- User input, form data, request bodies
- API responses, webhook payloads
- Deserialized data (JSON, YAML, config files)
- Shared library public APIs (callers you don't control)

The test: "Who would violate this contract and how?" If the answer is "no one, the type system prevents it," remove the check.

## References

- Source practice: [`docs/practices/ai-generation-hygiene.md`](../../../docs/practices/ai-generation-hygiene.md)
- Origin: `agent-crews/shared/steering/ai-generation-hygiene.md`
