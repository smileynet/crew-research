---
id: "17"
title: "Explore: script-file rule for bash invocations in windows steering"
status: open
blocked_by: []
spec: "field-feedback"
---

# Explore: script-file rule for bash invocations from PowerShell

Feature suggestion from an archwright/ExposeAR working session (2026-07-17).
`references/windows.md` covers Start-Process hazards but nothing about invoking
Git bash — which bit the same session twice EVEN THOUGH the failure mode was
already recorded in that project's lessons file.

## Observed failures

1. `& bash.exe -lc "...$PATH...$?..."` — PowerShell interpolates `$PATH`, `$?`,
   `$@` inside double-quoted strings BEFORE bash sees them. Symptoms range from
   loud (`unexpected EOF while looking for matching '`) to silent-and-wrong
   (`echo rc=$?` printing `rc=True` — a corrupted verdict that could be trusted).
2. Windows-native Python inside a Git-bash heredoc can't see bash's `/tmp` — a
   `python - <<EOF` test asserted on files written to `/tmp/...` and failed with
   a misleading assertion error, not a path error. Repo-local paths work.

## Suggested exploration

Would `references/windows.md` benefit from a "Git Bash Invocation" section, e.g.:

- NEVER pass `$`-containing or multi-line commands via `bash -c "..."` from
  PowerShell — write a `.sh` script file (`.scratch/`) and invoke
  `& "C:\Program Files\Git\bin\bash.exe" script.sh`
- Single-quoted PowerShell strings (`'...'`) are safe for short commands but
  fail as soon as the command itself needs single quotes — script file is the
  robust default
- Windows-native interpreters called from bash don't share bash's `/tmp` —
  use repo-relative paths for cross-interpreter temp files

## Evidence

Two live failures in one session despite prior documentation in project lessons —
suggests steering-level (always-loaded) placement earns its budget here.
