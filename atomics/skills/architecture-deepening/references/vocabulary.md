# Architecture Vocabulary

Precise definitions for architecture deepening discussions. Use these terms exactly — don't drift into "component," "service," "API," or "boundary."

## Core Terms

**Module**: Anything with an interface and an implementation. A function, class, package, or slice. Scale-independent.

**Interface**: Everything a caller must know to use the module — types, invariants, error modes, ordering constraints, configuration. Not just the type signature.

**Implementation**: The code inside the module. Hidden from callers.

**Depth**: Leverage at the interface. A lot of behavior behind a small interface = deep. Interface nearly as complex as implementation = shallow.

**Shallow module**: One where the interface is nearly as complex as the implementation. Callers must understand almost everything to use it. Low leverage.

**Deep module**: One where a simple interface hides significant complexity. Callers get a lot for free. High leverage.

## Structural Terms

**Seam**: Where an interface lives. A place behavior can be altered without editing in place. The point where you can swap one implementation for another.

**Adapter**: A concrete thing satisfying an interface at a seam. The "plug" that fits the "socket."

**Pass-through**: A module that adds no value — just forwards calls. Fails the deletion test.

## Value Terms

**Leverage**: What callers get from depth. "I call one method and complex things happen correctly."

**Locality**: What maintainers get from depth. Change, bugs, and knowledge concentrated in one place rather than scattered across callers.

## Decision Heuristics

**Deletion test**: Imagine deleting the module entirely.
- Complexity vanishes → it was a pass-through (shallow, consider removing)
- Complexity reappears across N callers → it was earning its keep (deep, worth preserving)

**Interface = test surface**: If you can't test the module through its public interface alone, the interface is wrong — not the tests.

**Adapter count rule**:
- Zero adapters = no seam exists (just direct coupling)
- One adapter = hypothetical seam (might be premature abstraction)
- Two+ adapters = real seam (the abstraction is earning its keep)
