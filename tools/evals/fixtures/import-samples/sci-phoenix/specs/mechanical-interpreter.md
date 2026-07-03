# Spec: Mechanical Interpreter (Phase 2 — Flat Heap)

## Goal

Replace the current interpreter's abstract model (obj_table, parse_objects, code cloning,
HashMap lookups) with a mechanical model that matches the original: one flat memory space
where all values are offsets, and all operations are byte reads/writes at computed positions.

## What gets deleted

### Files removed entirely
- `interpreter.rs` — replaced by `vm2.rs`
- `vm/mod.rs` + `vm/reg.rs` — the `Reg` type (segment+offset) is dead; flat heap has no segments

### Abstractions removed
- `obj_table: Vec<(usize, u16)>` — replaced by raw heap offsets
- `parse_objects()` — no pre-parsing; bytecode navigates data directly
- `lofs_resolve()` — replaced by `heap_base + pc + operand` (arithmetic only)
- `find_property()` — replaced by reading baseVars at a computed offset
- `find_method()` — replaced by walking bytes at computed offsets

## The mechanical model

### Memory layout

```
heap: Vec<u8>   — one contiguous byte array (64KB, matching SCI0's address space)
```

Scripts are loaded into the heap at sequential positions. Each script occupies a
contiguous region. The script's raw decompressed bytes are copied directly into the heap.

## Object access

Objects in the heap are just byte sequences with a known layout:
- `heap[obj + 0..2]` = magic (0x1234)
- `heap[obj + 2..4]` = local_vars_offset
- `heap[obj + 4..6]` = funcsel_offset (method dispatch table)
- `heap[obj + 6..8]` = num_vars
- `heap[obj + 8..]` = property values (2 bytes each)

Property read: `read_u16(heap, obj + 8 + selector_index * 2)`
Property write: `write_u16(heap, obj + 8 + selector_index * 2, value)`

## Send mechanism

```rust
fn send(heap: &mut [u8], obj_offset: u16, selector: u16, argc: u16, argv: &[u16]) {
    let species = read_u16(heap, obj_offset + 8); // property 0 = species
    let class_offset = class_table[species];
    // Walk funcsel table to find method offset
    let funcsel = read_u16(heap, class_offset + 4);
    let num_methods = read_u16(heap, class_offset + funcsel);
    for i in 0..num_methods {
        if read_u16(heap, class_offset + funcsel + 2 + i*4) == selector {
            let code_offset = read_u16(heap, class_offset + funcsel + 4 + i*4);
            // Push call frame and jump
            call(heap, class_offset + code_offset, argc, argv);
            return;
        }
    }
    // Not found → check super
}
```
