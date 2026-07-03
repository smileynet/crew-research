# Context

## Architecture

**Split Disassembly**: The 17-file reassemblable disassembly in `disasm/split/`. Every byte of the ROM is represented as `dc.w` (code with disassembly comments) or `dc.b` (data). Assembles byte-identically with vasm.

**dc.w Baseline**: The approach of emitting all code as raw word constants (`dc.w $4E75 ; rts`) rather than mnemonics. Required because vasm may optimize instruction encodings differently than the original assembler.

**vasm**: The assembler used for reassembly verification. Built from source at `resources/vasm/vasm/vasmm68k_mot`. Motorola syntax, 68000 mode, binary output.

**Musashi Executor**: The headless 68000 CPU emulator (`resources/musashi/m68k_genesis.so`). Runs the ROM at ~30M insn/sec with VDP stub, controller input, and coverage tracking.

**VBlank Cycling**: The VDP status register ($C00004) bit 3 must toggle per frame — set during VBlank (lines 224-261), cleared during active display (lines 0-223). Without this, the ROM's wait loops hang.

## ROM Layout

**Code Region**: $000200–$05FFFF. Contains 68000 instructions, jump tables, inline data. 6162 functions identified.

**RAM Region**: $FF0000–$FFFFFF. 64KB work RAM. Game variables, stack, dynamic buffers.

**VDP Ports**: $C00000 (data), $C00004 (control/status). Memory-mapped I/O for the video display processor.
