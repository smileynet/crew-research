# PBR Texture Pipeline — End-to-End Reference

## Decision Tree: Which Approach?

```
Asset has < 200 faces?
├── YES → Flat materials (2-4 colors per object). Skip textures.
│         Exception: if asset is a hero/featured item, use textures.
└── NO → Does it need unique detail (character, weapon)?
    ├── YES → Unique painted texture (Flux hand-painted LoRA or TEXGen)
    └── NO → Tileable material (StableMaterials + stylize post-process)
```

## Pipeline Steps

### Step 1: Asset Categorization

| Object | Parts | Strategy | UV Method |
|--------|-------|----------|-----------|
| Tree | trunk, foliage | trunk=tileable bark, foliage=flat green | trunk=cylinder, foliage=sphere |
| Rock | single | tileable stone | sphere |
| Barrel | body, bands | body=tileable wood, bands=flat metal | body=cylinder, bands=cylinder |
| Character | body, head, accessories | unique painted | manual unwrap |

### Step 2: UV Unwrapping

For tileable materials, use projection UVs (cube/cylinder/sphere) with scale calibrated to world-space tiling density (1 tile = 1 meter).

For unique textures, use Smart UV Project with island margin 0.01, angle limit 66°.

### Step 3: Material Generation

**Tileable path:**
1. Generate with StableMaterials: `prompt="mossy stone wall, stylized game texture"`
2. Post-process: run through style LoRA for hand-painted look
3. Validate seamlessness: tile 3×3, check edges visually

**Unique path:**
1. Render depth/normal pass from 4 cardinal views
2. Generate with TEXGen using depth ControlNet
3. Project back onto mesh UVs
4. Inpaint seams where projections overlap

### Step 4: Quality Gate (QUASAR)

Every generated texture passes through QUASAR scoring:
- Score ≥ 0.0: accept
- Score < 0.0 and > -0.15: flag for manual review
- Score < -0.15: reject and regenerate

## Export

Final textures exported as PNG (albedo, normal) and EXR (height, roughness) at 1024×1024 for game use. Source 2048×2048 kept in `raw/` for future upscaling.
