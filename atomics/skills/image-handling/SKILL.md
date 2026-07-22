---
name: image-handling
description: How to process images in kiro-cli sessions — kiro-cli vs Claude multimodal limits, sizing, and the fresh-session workaround for context compaction losing inline images.
metadata:
  type: reference
  invocation: agent-only
  practice: null
  tool: kiro-cli
---

# Image Handling (kiro-cli)

In long sessions or after context compaction, inline image processing may be
unavailable. Dispatch a fresh session to analyze images:

```bash
kiro-cli chat --no-interactive --trust-tools=read "<specific question> /abs/path/to/image.png"
```

Validated 2026-07-22 (archwright visual harness birth run): the fresh session reads
the path via the read tool's Image mode and returns accurate OCR-level analysis.
Headless+image is NOT explicitly documented together by kiro.dev — treat as
field-proven, re-validate on major CLI upgrades.

## Two limit layers — kiro-cli's and Claude's (verified 2026-07-22)

kiro-cli enforces file-level limits; Claude's API enforces pixel/token limits.
Respect BOTH — the binding constraint is usually Claude's resize tier.

| Constraint | kiro-cli (kiro.dev/docs/cli/chat/images/) | Claude API (docs.anthropic.com) |
|------------|-------------------------------------------|--------------------------------|
| Formats | JPEG/JPG, PNG, GIF, WebP | Same (animated: first frame only) |
| File size | < 10 MB per image | 10 MB base64 (5 MB on Bedrock/Vertex) |
| Images per request | ≤ 10 | 20 (claude.ai) / 100+ (API) — kiro-cli's 10 binds first |
| Pixel dims | not documented | 8000×8000 max; resized to tier below |
| Resize tier | n/a (no auto-resize documented) | standard: 1568 px long edge; high-res: 2576 px (Opus 4.7+/Sonnet 5, automatic) |
| Min useful size | not documented | < 200 px risks hallucination (official guidance) |

## Token cost (corrects the old formula)

Patch-based: `⌈w/28⌉ × ⌈h/28⌉` tokens (28-px patches). Example: 1000×1000 ≈ 1296
tokens. The old `w×h/750` estimate is obsolete — do not use it.

## Sizing rule

Pre-resize to ≤ 1568 px long edge and ≥ 200 px short edge YOURSELF — resolution
mismatch with the model's native tier is the #1 documented cause of vision grounding
failure, and pre-resizing keeps the crop-vs-scale choice in your hands:

```bash
convert image.png -resize '1568x1568>' resized.png   # shrink if over tier
```

## Practice notes (measured, 2026-07-22 research pass)

- Label every image with its role in the prompt text ("Image A: rendered section") —
  image blocks are anonymous pixels; unlabeled multi-image prompts scramble referents.
- ≤ 5–10 images per request before recall measurably degrades; decompose bigger
  audits into multiple requests.
- One attribute per question beats compound questions; never embed the expected
  answer (stated expectations shift answers toward the prompt-favored option —
  12–42 pt accuracy drops).
- Claude's spatial coordinates are officially "approximate" and counting is
  unreliable — don't ask for measurements; tiling/coordinate-grid overlays do NOT
  help (Anthropic internal testing).
- /paste is interactive-only (not available headless); oversized clipboard payloads
  can crash the session (GitHub #5781) — prefer file paths.
