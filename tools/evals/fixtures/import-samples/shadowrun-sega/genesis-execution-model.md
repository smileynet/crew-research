---
studied_at: 2026-05-29T20:23:00-07:00
source: resources/genesis-hardware-manual
---

# Sega Genesis Hardware Execution Model

## Power-On Sequence

### Electrical Reset
- On power-on, the RESET line is held low by the reset circuit (RC network, ~100ms).
- While RESET is asserted:
  - 68000 tri-states all bus outputs
  - All internal registers are undefined except: SR is set to $2700 (supervisor mode, all interrupts masked)
  - VDP is in reset state (display disabled, registers zeroed)
  - Z80 is held in reset via $A11200

### Vector Fetch
- When RESET deasserts, the 68000 performs two long-word reads:
  1. Address $000000: Initial Supervisor Stack Pointer (SSP) → loaded into A7
  2. Address $000004: Initial Program Counter (PC) → execution begins here
- These are standard ROM reads with wait states (~5 wait states each)
- Total reset sequence: ~518 clock cycles before first instruction executes

## MC68000 Execution Model

### Instruction Timing
- Minimum instruction: 4 cycles (NOP, MOVEQ)
- Memory access: 4 cycles per word (2 wait states on Genesis)
- Branch taken: +2 cycles for pipeline refill
- DIVS/DIVU: 140-158 cycles (variable based on operands)

### Interrupt Priority
| Level | Source | Vector |
|-------|--------|--------|
| 6 | VBlank | $0078 |
| 4 | HBlank | $0070 |
| 2 | External (active low on cart connector) | $0068 |

### Bus Arbitration
The Z80 and 68000 share the bus. The 68000 can request Z80 bus via $A11100:
- Write $0100 → request bus
- Read bit 0 → 0 when bus granted
- Write $0000 → release bus
