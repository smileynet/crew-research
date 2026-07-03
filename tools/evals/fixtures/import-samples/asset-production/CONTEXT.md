# Context

**geonodes**:
Python library (al1brn) that creates Blender Geometry Nodes programmatically. Not a runtime — builds node groups that Blender evaluates. Installed at `~/.config/blender/5.1/scripts/modules/geonodes` on flamingdragon.
_Avoid_: "geometry nodes library" (ambiguous with Blender's built-in feature)

**GeoNodes group**:
A reusable node tree created with `GeoNodes("Name", is_group=True)`. Called via `Group("Name")` or `G().snake_case_name()`. Produces a separate `bpy.data.node_groups` entry.
_Avoid_: "function", "component"

**QUASAR**:
Quality scoring method using CLIP-RN50 anchor centroids. Score = sim(good_centroid) - sim(bad_centroid). Threshold ≥ 0.0 = accept. Centroids at `data/quality/quasar_centroids.npz`.
_Avoid_: "CLIP score", "quality metric"

**StableMaterials**:
Diffusion model that generates tileable PBR texture sets (albedo + normal + roughness + height) from a text prompt. Produces 512×512 seamless tiles. Self-hosted on flamingdragon via ComfyUI.
_Avoid_: "texture generator" (too generic)

**TEXGen**:
Texture generation pipeline that projects generated images onto UV-unwrapped meshes. Uses depth-conditioned ControlNet to maintain geometric alignment. Produces unique (non-tiling) textures per object.
_Avoid_: "painting", "projection mapping"

**flamingdragon**:
The local GPU workstation (RTX 4090, 64GB RAM). Runs ComfyUI, Blender rendering, and all ML inference locally.
_Avoid_: "server", "cloud"
