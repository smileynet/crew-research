# Tool-Specific Vision Dispatch

Per-tool invocation syntax and edge cases for the DETECT and DISPATCH steps.

## Dispatch priority

When multiple tools are available, prefer:
1. The tool you're currently running in (if vision-capable) — avoids cross-tool overhead
2. kiro-cli (Claude vision — most reliable for general analysis)
3. codex (GPT-5.5 vision — strong on text extraction from images)
4. agy (Gemini vision — strongest on charts/diagrams, but print mode may not read files; see Issue #548)

For multi-validator consensus tasks, use ALL available tools regardless of priority.
If a tool produces empty output or errors, note it as unavailable rather than retrying endlessly.

## Per-tool commands

### kiro-cli

```bash
kiro-cli chat --no-interactive "<specific question> /path/to/image.png"
```

- Vision-capable but lost after context compaction in long sessions.
- Dispatch a fresh session to bypass compaction — fresh context sees inline images.
- Pass the image path as a trailing argument; kiro-cli loads it automatically.

### codex

```bash
codex exec --dangerously-bypass-approvals-and-sandbox --ephemeral -C "$(pwd)" "<specific question> /path/to/image.png" < /dev/null
```

- Vision-capable. Strong on OCR and text-in-image tasks.
- `--ephemeral` ensures a clean session (no steering contamination).
- `< /dev/null` prevents interactive hang.

### agy

```bash
agy --print --add-dir "$(pwd)" "<specific question about the image>" > /tmp/agy-vision-out.txt 2>&1
cat /tmp/agy-vision-out.txt
```

- Vision-capable (Gemini). Strongest on charts, diagrams, spatial layout.
- `--add-dir` is required to add the workspace to agy's project scope.
- **Print mode limitation (Issue #548):** agy soft-denies file-reading tools in `--print`
  mode. The agent may not be able to read image files via tool calls. If output is empty
  or shows a permission error, pipe the image content or path differently, or skip agy
  and rely on other vision tools.
- Do NOT use `--dangerously-skip-permissions` — it causes the Gemini model to derail,
  investigating its own flags instead of doing the task.
- Requires 300s timeout for reliability on complex tasks.

### crush (no native vision)

Crush (GLM-5.2) has `supports_vision: false`. It must always shell out to another tool. Skip PROBE entirely and go to DETECT.

If no other vision tool is installed, use the FALLBACK path (OCR + metadata only).

## Multi-validator consensus pattern

When consensus is required (validation, regression checks, spec comparison):

```bash
# Dispatch to each available tool in parallel, collect results
results_dir=$(mktemp -d)

command -v kiro-cli &>/dev/null && \
  kiro-cli chat --no-interactive "<question> /path/to/image.png" > "$results_dir/kiro.txt" 2>&1 &

command -v codex &>/dev/null && \
  codex exec --dangerously-bypass-approvals-and-sandbox --ephemeral "<question> /path/to/image.png" < /dev/null > "$results_dir/codex.txt" 2>&1 &

command -v agy &>/dev/null && \
  agy --print --add-dir "$(pwd)" "<question> /path/to/image.png" > "$results_dir/agy.txt" 2>&1 &

wait

# Read all results, compare
for f in "$results_dir"/*.txt; do
  echo "=== $(basename "$f" .txt) ==="
  cat "$f"
  echo ""
done
```

Then synthesize: agreements = high confidence, disagreements = flag conflict.

## Fallback (no vision tools available)

```bash
# Text extraction
tesseract image.png stdout 2>/dev/null

# Metadata (dimensions, format, color depth)
identify -verbose image.png 2>/dev/null | head -30
# or
exiftool image.png 2>/dev/null
```

Report what was extractable and state: "No vision-capable tool available — analysis limited to OCR text and metadata. Visual layout, colors, and spatial relationships not assessed."
