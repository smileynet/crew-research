# Design Vocabulary

Precise definitions for architecture deepening discussions. Use these terms exactly — don't drift into "component," "service," "API," or "boundary."

## Core Terms

**Module** — anything with an interface and an implementation. Scale-agnostic: function, class, package, or tier-spanning slice.
_Avoid_: unit, component, service.

**Interface** — everything a caller must know: type signature + invariants + ordering constraints + error modes + configuration + performance. Not just the method signatures.
_Avoid_: API, signature (too narrow — refers only to the type-level surface).

**Implementation** — the code inside the module. Hidden from callers.

**Depth** — leverage at the interface. A module is **deep** when large behavior sits behind a small interface. **Shallow** when the interface is nearly as complex as the implementation.

## Structural Terms

**Seam** (Feathers) — a place where behavior can change without editing in that place. Where the module's interface lives. A design decision independent of what goes behind it.
_Avoid_: boundary (overloaded with DDD bounded contexts).

**Adapter** — a concrete thing satisfying an interface at a seam. Describes role (what slot it fills), not substance (what's inside).

**Pass-through** — a module that adds no value — just forwards calls. Fails the deletion test.

## Value Terms

**Leverage** — what callers get from depth: more capability per unit of interface learned. One implementation pays back across N call sites and M tests.

**Locality** — what maintainers get from depth: change, bugs, knowledge, and verification concentrate in one place rather than scattered across callers.

## Tests

**Deletion test:** Imagine deleting the module entirely.
- Complexity vanishes → it was a pass-through (shallow, consider removing)
- Complexity reappears across N callers → it was earning its keep (deep, worth preserving)

**Interface = test surface:** If you can't test the module through its public interface alone, the interface is wrong (too narrow) or the seam is misplaced — not the tests.

**Adapter count rule:**
- Zero adapters = no seam exists (just direct coupling)
- One adapter = hypothetical seam (might be premature abstraction)
- Two+ adapters = real seam (the abstraction is earning its keep)

Don't introduce seams until the second consumer appears.

## Deep vs Shallow

```
Deep module:              Shallow module (avoid):
┌──────────────┐         ┌─────────────────────────────┐
│ Small iface  │         │      Large interface        │
├──────────────┤         ├─────────────────────────────┤
│              │         │  Thin implementation        │
│ Rich impl    │         └─────────────────────────────┘
│              │
└──────────────┘
```

When designing, ask:
- Can I reduce the number of methods?
- Can I simplify the parameters?
- Can I hide more complexity inside?
