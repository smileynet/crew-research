# Display Pipeline Architecture

## Overview

The display pipeline renders a 480×272 framebuffer at 60fps using hardware acceleration. The CPU never touches individual pixels for standard operations — DMA2D handles all blits.

## Layers

The LTDC supports 2 hardware layers composited in order:
1. **Background layer**: tilemap or solid color (320×272 visible, hardware-scrolled)
2. **Sprite layer**: DMA2D-composited sprite sheet regions blitted to framebuffer

## Framebuffer Layout

```
SRAM1 (320KB): 
  fb0: 480×272×2 = 261,120 bytes (RGB565)
  fb1: 480×272×2 = 261,120 bytes (double buffer)

Remaining SRAM: sprite atlas cache, audio buffers, game heap
```

## Rendering Sequence (per frame)

1. Game logic runs (Lua + Rust), updates sprite positions and tile scroll
2. Engine sorts sprites by Y (painter's algorithm) or priority layer
3. DMA2D blits background tiles to back buffer (hardware handles scrolling offset)
4. DMA2D blits each visible sprite from atlas to back buffer (alpha-keyed)
5. LTDC swap: back buffer becomes front, VSYNC interrupt signals next frame

## Performance Budget

| Operation | Cycles | Time at 480MHz |
|-----------|--------|----------------|
| DMA2D 32×32 blit | ~512 | 1.07µs |
| DMA2D 64×64 blit | ~2048 | 4.27µs |
| Full screen fill | ~130,560 | 272µs |
| Budget per frame (60fps) | — | 16,667µs |
| Available for sprites (after BG) | — | ~15,000µs |
| Max sprites per frame | ~3500 (32×32) | theoretical max |

Practical limit: ~120 sprites (accounting for Lua overhead, audio mixing, game logic).

## Sprite Atlas

Sprites are packed into 1024×1024 atlas pages stored in external QSPI flash.
DMA2D reads source directly from memory-mapped flash (XIP). No RAM copy needed for rendering.
Atlas packing done offline by the SDK toolchain (TexturePacker format).
