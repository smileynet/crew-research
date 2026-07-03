---
studied_at: 2026-05-30T14:00:00-07:00
source: resources/z80-ym2612-docs
---

# Z80-YM2612 Timing Reference

## Z80 Clock

The Z80 runs at 3.579545 MHz (NTSC) or 3.546895 MHz (PAL). This is the 68000 clock (7.67 MHz) divided by ~2.14 (not an exact integer ratio — they share a common master clock of 53.69 MHz).

## YM2612 Register Access

The YM2612 is accessed via Z80 address space at $4000-$4003:
- $4000: Address port (Part I)
- $4001: Data port (Part I)
- $4002: Address port (Part II)
- $4003: Data port (Part II)

### Timing constraints

After writing the address port, wait **minimum 4 Z80 cycles** before writing data.
After writing the data port, wait **minimum 24 Z80 cycles** before the next write.

In practice, games use NOPs or memory reads as delay:
```asm
ld  a, reg_number
out ($40), a        ; address port
nop                 ; 4 cycles
nop                 ; 4 cycles (total 8 — safe margin)
ld  a, value
out ($41), a        ; data port
; ... 24 cycle delay before next YM write
```

## FM Synthesis Parameters

Each of the 6 FM channels has 4 operators with:
- Total Level (TL): 0-127, attenuation in 0.75dB steps
- Multiple (MUL): frequency multiplier 0.5, 1, 2, 3... 15
- Detune (DT1): fine frequency adjustment, ±0 to ±7
- Attack/Decay/Sustain/Release rates: 0-31 each
- Key Scale (KS): rate scaling by note, 0-3

## DAC Mode

Channel 6 can be switched to DAC (PCM) mode by setting bit 7 of register $2B.
In DAC mode, 8-bit unsigned PCM samples are written to register $2A at the desired sample rate.
The Z80 typically handles DAC playback in its interrupt routine.
