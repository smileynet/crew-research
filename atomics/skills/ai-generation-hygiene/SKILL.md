---
metadata:
  type: protocol
  invocation: both
  practice: null
name: ai-generation-hygiene
description: "Code quality rules that catch common AI-generation artifacts. Apply when writing code, generating functions, implementing features, creating scripts, or producing any code output. Catches: redundant defensive checks, gratuitous logging, restating comments, unnecessary casts, over-abstraction, verbose implementations. Always relevant during code generation tasks."
---

# AI Generation Hygiene

Every line of generated code must earn its place. Cut until cutting would lose meaning.

## The Nine Banned Patterns

Before presenting or committing code, scan for these. Each hit is a line that doesn't earn its place — fix before presenting.

| # | Pattern | Rule | Example of violation |
|---|---------|------|----------------------|
| P1 | Redundant defensive checks | MUST NOT null/type-check values the type system already guarantees | `if x is None: raise` when x is typed non-Optional |
| P2 | Catch-everything | MUST NOT catch, log, and re-raise unchanged — only catch what you can handle (recover, degrade, or transform to a domain exception) | `except Exception as e: logger.error(e); raise` |
| P3 | Restating comments | MUST NOT comment what the code already says — comments document WHY: constraints, rejected alternatives, non-local coupling | `counter += 1  # increment counter` |
| P4 | Gratuitous logging | MUST NOT add entry/exit logging or parameter echoing — log state transitions, business decisions, errors | `logger.info("Entering process_payment")` |
| P5 | Redundant casts | MUST NOT cast values to types they already are | `str(f"hello")`, `list([1,2,3])`, `int(len(x))` |
| P6 | Single-use abstractions | SHOULD NOT create classes, factories, or wrappers used exactly once — direct code beats indirection without reuse | factory class instantiated once |
| P7 | Defensive copies without mutation | SHOULD NOT copy data structures nothing in the call chain mutates | `.copy()` when nothing mutates the original |
| P8 | Verbose conditionals | SHOULD reduce to direct expressions | `if x: return True else: return False` instead of `return x` |
| P9 | Unused imports | MUST NOT leave imports never referenced — each import is a dependency claim | `import os` in a file that never uses it |

## The Exception: Trust Boundaries

Keep defensive code where values enter from outside your control:

- User input, form data, request bodies
- API responses, webhook payloads
- Deserialized data (JSON, YAML, config files)
- Shared library public APIs (callers you don't control)

The test: "Who would violate this contract and how?" If the answer is "no one, the type system prevents it," remove the check.
