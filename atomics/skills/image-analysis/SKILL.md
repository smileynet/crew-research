---
name: image-analysis
description: "Analyze an image file using vision capabilities. Use when asked to describe, analyze, extract text from, or interpret an image. Trigger: analyze image, describe image, what's in this image, screenshot, OCR, read this image."
---

# Image Analysis

Analyze an image by dispatching a kiro-cli session with the image path in the prompt.

## Process

1. Determine what the user needs from the image (describe, extract text, compare, identify elements, etc.)
2. Confirm the image path exists
3. Invoke kiro-cli with the specific question AND the image path:

```bash
kiro-cli chat --no-interactive "<your question about the image> /path/to/image.png"
```

The question should be specific — ask exactly what you need to know.

## Examples

```bash
# Ask what's in a screenshot
kiro-cli chat --no-interactive "What error message is shown in this screenshot? ./screenshots/error.png"

# Extract specific text
kiro-cli chat --no-interactive "What is the total amount on this receipt? ~/Downloads/receipt.jpg"

# Understand a diagram
kiro-cli chat --no-interactive "What components are shown and how do they connect? docs/architecture.png"

# Compare elements
kiro-cli chat --no-interactive "What changed between these two UI states? before.png after.png"
```

## Notes

- Supports common formats: PNG, JPG, JPEG, GIF, WebP
- The image path must be accessible from the current working directory or absolute
- For multiple images, invoke once per image or list them in a single prompt
