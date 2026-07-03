# Spec: Save/Restore System

## Overview

SCI0 save/restore serializes the entire game state to a single file. The kernel functions
`kSave` and `kRestore` handle the actual I/O; the game script orchestrates the UI.

## What gets saved

1. **All script locals** — every loaded script's local variable block
2. **All clones** — runtime-created objects (clone table dump)
3. **Global variables** — the global variable block (script 0 locals)
4. **Heap state** — object property values for all instances and clones
5. **Call stack** — NOT saved. Restore always returns to the game's main loop.

## File format

```
[header: 32 bytes]
  magic: "SCI0" (4 bytes)
  game_id: u16
  save_slot: u16
  description: 24 bytes (null-padded ASCII)

[global_vars: num_globals * 2 bytes]
  Raw dump of global variable values

[scripts: for each loaded script]
  script_id: u16
  num_locals: u16
  locals: num_locals * 2 bytes

[clones: for each active clone]
  clone_id: u16
  species: u16
  num_properties: u16
  properties: num_properties * 2 bytes

[terminator: 0xFFFF]
```

## Restore sequence

1. Game calls `kRestoreGame(filename)`
2. Kernel reads file, validates header
3. All existing scripts are unloaded
4. Global variables restored from file
5. Scripts reloaded as encountered in save data, locals restored
6. Clone table rebuilt from save data
7. Kernel returns to caller — game script must then reinitialize rooms/views

## Key constraint

Restore does NOT reconstruct the call stack. The game's restore handler must be
callable from the main loop only. This means save/restore always goes through
`Game:restore` → which reloads the current room from scratch.
