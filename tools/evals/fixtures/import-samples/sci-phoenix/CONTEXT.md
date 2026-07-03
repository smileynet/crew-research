# Domain Glossary

## Engine architecture

- **SCI0** — Sierra Creative Interpreter version 0 (1988–1990). Parser-driven, EGA, 320×200. LSL2's runtime.
- **PMachine** — the SCI bytecode virtual machine. Stack-based with accumulator, executes compiled SCI Script.
- **reg_t** — the universal value type: `(segment: u16, offset: u16)`. Segment 0 = numeric value in offset. Nonzero segment = pointer into that segment.
- **Segment** — a typed memory region managed by the segment manager. Types: script, locals, stack, clones, lists, nodes, dynmem.
- **Kernel** — C-side (host-side) primitives callable from scripts via `callk` opcode. ~120 functions; LSL2 uses a subset.
- **Send** — the object dispatch mechanism. `send`/`self`/`super` opcodes look up selectors on a receiver and invoke methods or read/write properties.

## Object model

- **Class** — a script-defined object template. Lives in a script resource. Has properties and methods.
- **Instance** — a script-defined object created at script load time (static). Has its own property values, inherits methods from its class.
- **Clone** — a runtime copy of an instance or class, allocated in the clone table. Created by `kClone`, freed by `kDisposeClone`.
- **Selector** — a named property or method identifier (16-bit index). Resolved via `vocab.997`.
- **Species** — the class number an object belongs to. Used for method lookup and `super` dispatch.

## Resources

- **Resource manager** — loads and caches game resources from RESOURCE.MAP + RESOURCE.001..NNN files.
- **Script resource (type 82)** — contains class definitions, instances, local variables, and bytecode.
- **Heap resource** — SCI1+ only. Separates heap data from script code.
