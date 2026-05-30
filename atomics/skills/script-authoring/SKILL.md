---
name: script-authoring
description: >
  Best practices for writing tool and helper scripts. Use when creating
  bash scripts, automation tools, CLI utilities, or any executable that
  will be run repeatedly by humans or agents.
metadata:
  type: reference
  invocation: both
  practice: null
---

# Script Authoring

Scripts are infrastructure. They run repeatedly, fail unexpectedly, and get inherited by people who didn't write them. Build for the second run, not the first.

## Core Principles

### 1. Idempotent
Run twice, get the same result. Check state before acting.
```bash
# Bad: fails on second run
mkdir output/

# Good: safe to re-run
mkdir -p output/
```
Pattern: check-then-act. `[[ -f "$file" ]] || create_it`. Never assume clean state.

### 2. Resumable
If interrupted, pick up where it left off. Use checkpoints for multi-step work.
```bash
# Checkpoint pattern
DONE_FILE=".state/${STEP}.done"
if [[ ! -f "$DONE_FILE" ]]; then
  do_expensive_work
  touch "$DONE_FILE"
fi
```
For long operations: write progress to a state file. On restart, read state and skip completed steps.

### 3. Progress Visible
The user must always know: what's happening, how far along, and whether it's stuck.
```bash
echo "Step 2/5: Installing dependencies..."
# For loops:
echo "  Processing $i/$total: $name"
```
Rules: announce each phase, show counts for loops, emit timing for slow operations.

### 4. Fail Loudly
```bash
set -euo pipefail  # Always. No exceptions.
```
- `-e`: exit on error
- `-u`: error on undefined variables
- `-o pipefail`: catch failures in pipes

Add `trap cleanup EXIT` for temp file cleanup on any exit path.

### 5. Self-Documenting
```bash
#!/bin/bash
# tools/my-script.sh — One-line description of what this does
# Usage: ./my-script.sh [--flag value] [--dry-run]
```
Every script starts with: shebang, description comment, usage comment. If it takes flags, show them.

## Required Patterns

| Pattern | Why |
|---------|-----|
| `set -euo pipefail` | Fail fast, fail loud |
| Usage comment in header | Discoverable without reading code |
| `--dry-run` flag for destructive scripts | Safe to test |
| Temp dirs with `trap` cleanup | No orphaned files |
| Absolute paths for key dirs (`SCRIPT_DIR`) | Works from any cwd |
| Exit codes: 0=success, 1=error, 2=usage | Composable with other tools |

## Anti-Patterns

- `cd` then relative paths → compute absolute paths from `SCRIPT_DIR`
- Silent failures (`|| true` everywhere) → let errors propagate, handle specifically
- Wall of output → structured phases with indented details
- Hardcoded paths → variables at top or flags
- Retry without backoff → exponential backoff or fail after N

## Output Conventions

```
Phase header (what's about to happen)
  ✅ Success detail
  ⚠️  Warning (non-fatal)
  ❌ Error (fatal)
---
Summary line (totals, timing)
```

## Cross-Platform (bash on Windows)

Scripts target bash. On Windows, Git Bash provides bash + coreutils. Key compatibility rules:

- **Prefix with `bash`** in task runners (mise, Makefiles) — Windows won't find shebangs
- **Use `/tmp/` for temp files** — Git Bash maps this correctly on all platforms
- **Avoid `sed -i` without backup suffix** — macOS sed requires `sed -i ''`, GNU doesn't. Use: `sed -i'' -e 's/...' file` or write to temp + mv
- **Use `diff -q` not `cmp`** — more portable for content comparison
- **Avoid `realpath`** — not available on macOS by default. Use `cd "$(dirname "$0")" && pwd`
- **Avoid `timeout` in user-facing scripts** — not available on macOS. Use for CI/eval only
- **Path separators**: bash on Windows handles `/` fine. Never hardcode `\`
- **Line endings**: add `.gitattributes` with `*.sh text eol=lf` to prevent CRLF corruption

### mise.toml pattern for Windows compatibility

```toml
# Passthrough tasks (user provides all args after --)
[tasks.init]
raw = true
run = "bash tools/generator/init.sh"

# Tasks with defined args (mise parses, script receives)
[tasks.generate]
usage = 'arg "[tool]" default="kiro-cli"'
run = "bash tools/generator/generate.sh ${usage_tool?}"
```
