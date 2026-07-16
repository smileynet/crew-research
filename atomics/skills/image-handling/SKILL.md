---
name: image-handling
description: How to process images in kiro-cli sessions (workaround for context compaction losing inline images).
metadata:
  type: reference
  invocation: agent-only
  practice: null
  tool: kiro-cli
---

# Image Handling (kiro-cli)

In long sessions or after context compaction, inline image processing may be unavailable. Dispatch a fresh session to analyze images:

```bash
kiro-cli chat --no-interactive "<specific question> /path/to/image.png"
```

## Size constraints

- **Min 200×200 px** — below this, vision hallucinates
- **Max 2000 px long edge** — above this, wasted tokens (model downscales internally)
- **Formats:** JPEG, PNG, GIF, WebP only

## Resize if needed

```bash
convert image.png -resize '2000x2000>' resized.png   # shrink if over
convert image.png -resize '200x200<' resized.png     # enlarge if under
```

## Token cost

~`width × height / 750` tokens per image. Ask specific questions, not "analyze this."
