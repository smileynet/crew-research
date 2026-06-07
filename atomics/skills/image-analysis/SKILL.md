---
name: image-analysis
description: "Analyze an image file using vision capabilities. Use when asked to describe, analyze, extract text from, or interpret an image. Trigger: analyze image, describe image, what's in this image, screenshot, OCR, read this image."
---

# Image Analysis

Analyze an image by dispatching a kiro-cli session with the image path in the prompt.

## Process

1. Confirm the image path exists (use glob or read to verify)
2. Invoke kiro-cli with the image path included directly in the prompt:

```bash
kiro-cli chat --no-interactive "Analyze this image: /path/to/image.png"
```

3. Report the results back to the user

## Examples

```bash
# Describe what's in a screenshot
kiro-cli chat --no-interactive "Describe what you see in this image: ./screenshots/error.png"

# Extract text from an image
kiro-cli chat --no-interactive "Extract all visible text from this image: ~/Downloads/receipt.jpg"

# Analyze a diagram
kiro-cli chat --no-interactive "Explain the architecture shown in this diagram: docs/architecture.png"
```

## Notes

- Supports common formats: PNG, JPG, JPEG, GIF, WebP
- The image path must be accessible from the current working directory or absolute
- For multiple images, invoke once per image or list them in a single prompt
