# ADR 0002: Nuked-OPL3 via opl3-rs for AdLib synthesis

## Status: Accepted

## Context

SCI0 games use the AdLib (OPL2) FM synthesizer for music and sound effects. We need an OPL2 emulator that produces cycle-accurate audio output. Options considered:

1. **Nuked-OPL3** (C, LGPL-2.1) — bit-perfect, consensus best OPL emulator
2. **opl-emu** (Rust, GPL-3.0) — pure Rust but GPL-incompatible with our license
3. **Custom implementation** — months of work for diminishing returns

## Decision

Use the `opl3-rs` crate (Rust bindings to Nuked-OPL3). Nuked-OPL3 provides bit-perfect accuracy and is adopted by DOSBox Staging and MartyPC. The pure-Rust option (`opl-emu`) is GPL-3.0, incompatible with our MIT/Apache-2.0 license.

## LGPL compliance

Nuked-OPL3 is LGPL-2.1. We satisfy this by:
- Keeping its C source as a separate compilation unit
- Including its own license file
- Providing the object files for relinking (via the crate's build artifacts)

## Consequences

- Audio output is reference-quality from day one
- Tiny C dependency (single .c file) in an otherwise pure-Rust project
- Must maintain LGPL compliance in distribution
