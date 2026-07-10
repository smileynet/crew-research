# Smell Baseline (Fowler)

Apply to every diff regardless of project standards. Each is a heuristic — flag as "possible X", not a hard violation. Skip anything linting/tooling already enforces.

**Repo standards override:** if a documented convention endorses something a smell would flag, suppress it.

## The Smells

- **Mysterious Name** — function, variable, or type whose name doesn't reveal purpose. → Rename; if no honest name comes, the design is murky.

- **Duplicated Code** — same logic shape in multiple hunks or files in the change. → Extract the shared shape, call from both.

- **Feature Envy** — method reaches into another object's data more than its own. → Move the method onto the data it envies.

- **Data Clumps** — same few fields or params keep travelling together. → Bundle into one type.

- **Primitive Obsession** — string or int standing in for a domain concept. → Give the concept its own type.

- **Repeated Switches** — same switch/if-cascade on the same type recurs across the change. → Replace with polymorphism or one shared map.

- **Shotgun Surgery** — one logical change forces scattered edits across many files. → Gather what changes together into one module.

- **Speculative Generality** — abstraction, parameters, or hooks for needs the spec doesn't have. → Delete it; inline until a real need shows.

- **Middle Man** — class or function that mostly just delegates. → Cut it, call the real target direct.

- **Message Chains** — long `a.b().c().d()` navigation the caller shouldn't depend on. → Hide the walk behind one method on the first object.

## Using in Review

For each smell found in the diff:
```
[NIT] file:line — Possible {smell name}: {one-line description of the instance}.
  Request: {specific change}.
  Reason: {why this smell hurts here}.
```

Smells are NITs by default — don't block merges on them unless they compound (3+ smells in the same module = IMPORTANT).
