# Plan: Render Harness Implementation

## Objective

Automate batch rendering of game assets with consistent lighting, camera angles, and output format. The render harness takes a list of GLB files and produces standardized preview images for the asset catalog.

## Requirements

1. Headless Blender execution (no GUI)
2. Consistent 3-point studio lighting setup
3. 8 camera angles per asset (cardinal + diagonal, 30° elevation)
4. Transparent background (RGBA PNG)
5. Auto-framing: camera distance adjusts to asset bounding box
6. Batch processing: accept directory of GLBs, output to parallel directory structure

## Architecture

```
render_harness/
├── __main__.py          # CLI entry point
├── scene_setup.py       # Lighting, camera, world settings
├── asset_loader.py      # GLB import + centering + scaling
├── camera_rig.py        # 8-angle orbital camera
└── batch_runner.py      # File discovery + subprocess Blender calls
```

## Key Decisions

- **Subprocess per asset** rather than batch-loading in one Blender session — isolates crashes, memory leaks from problematic assets
- **EEVEE** for previews (fast, good enough for catalog), Cycles for hero shots only
- **Normalized scale**: all assets scaled to fit within a 2m bounding cube before rendering

## Status

- [x] scene_setup.py — lighting validated
- [x] camera_rig.py — 8 angles working
- [ ] batch_runner.py — needs error handling for malformed GLBs
- [ ] Integration with QUASAR for auto-quality-gating rendered outputs
