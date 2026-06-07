---
name: image-analysis
description: "Analyze an image file using vision capabilities. Use when asked to describe, analyze, extract text from, or interpret an image. Trigger: analyze image, describe image, what's in this image, screenshot, OCR, read this image."
metadata:
  type: process
  invocation: both
---

# Image Analysis

Analyze an image by dispatching a kiro-cli session with the image path in the prompt.

## Process

1. Determine what the user needs from the image
2. Confirm the image path exists
3. Check image dimensions and resize if needed (see below)
4. Invoke kiro-cli with the specific question and the prepared image path:

```bash
kiro-cli chat --no-interactive "<specific question> /path/to/image.png"
```

## Image Size Requirements

| Constraint | Value | Reason |
|-----------|-------|--------|
| Minimum | 200×200 px | Below this, Claude hallucinates or misreads |
| Maximum (long edge) | 2000 px | Beyond this, tokens wasted on resolution Claude downscales anyway |
| Formats | JPEG, PNG, GIF, WebP | Only supported types |

**If the image doesn't meet these parameters, resize it first:**

```bash
# Check dimensions
identify -format "%wx%h" image.png

# Resize in a temp folder if needed
TMPDIR=$(mktemp -d)
convert image.png -resize '2000x2000>' "$TMPDIR/resized.png"   # shrink if over 2000px
convert image.png -resize '200x200<' "$TMPDIR/resized.png"     # enlarge if under 200px

# Use the resized image in the prompt
kiro-cli chat --no-interactive "<question> $TMPDIR/resized.png"

# Clean up
rm -rf "$TMPDIR"
```

If `imagemagick` is not installed, use `ffmpeg`:
```bash
ffmpeg -i image.png -vf "scale='min(2000,iw)':min(2000,oh)':force_original_aspect_ratio=decrease" "$TMPDIR/resized.png"
```

## Examples

```bash
# Ask what's in a screenshot
kiro-cli chat --no-interactive "What error message is shown in this screenshot? ./screenshots/error.png"

# Extract specific text
kiro-cli chat --no-interactive "What is the total amount on this receipt? ~/Downloads/receipt.jpg"

# Understand a diagram
kiro-cli chat --no-interactive "What components are shown and how do they connect? docs/architecture.png"
```

## Notes

- Ask a specific question — don't just say "analyze this"
- Images before 200px: unreliable OCR and object identification
- Images over 2000px: Claude downscales internally, wasting upload time and tokens
- Token cost: approximately `width × height / 750` tokens per image
