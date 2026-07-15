# Multi-Agent Validation — Tool Reference

Quick reference for invoking each validation tool from bash.

## codex (OpenAI Codex CLI)

```bash
# Version check
codex --version

# Single image analysis
codex exec -i /path/to/image.png --sandbox read-only "prompt"

# Multiple images
codex exec -i a.png -i b.png --sandbox read-only "Compare these"

# Save output to file
codex exec -i image.png --sandbox read-only --output-last-message result.md "prompt"

# Outside git repo
codex exec -i image.png --sandbox read-only --skip-git-repo-check "prompt"

# Specific model
codex exec -i image.png --sandbox read-only -m gpt-5.5 "prompt"

# Parse clean response
codex exec -i image.png --sandbox read-only "prompt" 2>&1 | tail -15
```

## agy (Google Antigravity CLI)

```bash
# Version check
agy --version

# Visual-only analysis (sandbox — no code reading)
agy -p "Analyze /path/to/image.png - prompt" --sandbox --print-timeout 2m

# Code-aware analysis (reads files, runs scripts)
agy -p "Analyze /path/to/image.png - prompt" --print-timeout 2m

# Specific model
agy -p "Analyze image.png - prompt" --model "Gemini 3.5 Flash (High)" --print-timeout 2m

# List available models
agy models

# With additional directory access
agy -p "Analyze image.png - prompt" --add-dir /path/to/shaders --print-timeout 2m

# Auto-approve all tool use (batch runs)
agy -p "Analyze image.png - prompt" --dangerously-skip-permissions --print-timeout 5m
```

### agy behavioral modes

| Flag | Reads image | Reads code | Runs scripts | Use for |
|------|-------------|------------|-------------|---------|
| `--sandbox` | ✅ | ❌ | ❌ | Visual inspection pass |
| *(no flag)* | ✅ | ✅ | ✅ | Root cause diagnosis |

### agy prompt engineering for styled/NPR content

**Must include:** Context that intentional stylistic choices are desired, not defects.

```
This is an intentional [style] where [feature] is a DESIRED feature (not a bug).
PASS if [positive criteria]. FAIL only if [failure criteria].
```

Without this, agy flags intentional hard edges as aliasing, low variation as broken rendering, etc.

## kiro (Kiro CLI)

```bash
# Non-interactive single-shot (for image analysis from another session)
kiro-cli chat --no-interactive "Analyze /path/to/image.png - criteria"
```

### In TUI (interactive session)

The primary kiro agent reads images directly via the Image tool:
```
[Image read tool is invoked automatically when image paths are referenced]
```

For multiple images or when context is limited:
```
[Dispatch a subagent or use a fresh session to avoid context exhaustion]
```

## Scripting all three together

```bash
#!/bin/bash
# validate-render.sh — Run all three validators on a rendered image
IMAGE="$1"
PROMPT="$2"

echo "=== CODEX ==="
codex exec -i "$IMAGE" --sandbox read-only "$PROMPT" 2>&1 | tail -15

echo ""
echo "=== AGY (visual) ==="
agy -p "Analyze $IMAGE - $PROMPT" --sandbox --print-timeout 2m 2>&1 | tail -20

echo ""
echo "=== AGY (code-aware) ==="
agy -p "Analyze $IMAGE - $PROMPT" --print-timeout 2m 2>&1 | tail -20
```

Usage:
```bash
./validate-render.sh /path/to/render.png "This is toon-shaded. Is banding visible? Gooch hue shift? PASS/FAIL."
```
