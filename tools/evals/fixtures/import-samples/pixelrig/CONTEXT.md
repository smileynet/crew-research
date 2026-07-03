# Context

**Console**: The complete system — hardware, OS, and game ecosystem as a vertically integrated product. A real game console.
_Avoid_: fantasy console, dev kit, emulator

**PixelRig**: The working title. Pixel (what you see) + Rig (hardware you built).

**Cartridge**: A self-contained game artifact. Two physical forms: flash-based cartridge (premium/collectible, custom PCB in shell) and SD card (everyday/dev, standard microSD). Same file format on both.
_Avoid_: ROM, binary, app

**Engine**: The runtime that executes games on the console hardware. Written in Rust. Provides the API games are written against.
_Avoid_: VM, emulator, interpreter

**Game language**: Lua 5.4 for game scripting. Engine exposes API to Lua. Native Rust extensions available for performance-critical code.

**MCU**: STM32H750 (480MHz Cortex-M7, 1MB SRAM, LTDC + DMA2D). Hardware LCD controller eliminates display driving from CPU. Hardware blitter for sprite compositing.
_Avoid_: RP2040/RP2350, ESP32-S3

**Form factor**: Handheld-first. 4.3" display, PSP-like ergonomics. Self-contained with built-in screen, SNES controls, speaker, headphone jack, battery.

**Display pipeline**: LTDC reads framebuffer from SRAM → LCD panel. DMA2D (Chrom-ART) accelerates blits, fills, and alpha blending. The engine composes a 480×272 framebuffer each frame.

**Audio subsystem**: I2S DAC (PCM5102A) driven by DMA from a ring buffer. Engine mixes 8 channels in software at 22050 Hz, 16-bit stereo.

**Embassy**: The async Rust embedded framework used for all firmware. Provides tasks, timers, and hardware abstraction without RTOS overhead.
