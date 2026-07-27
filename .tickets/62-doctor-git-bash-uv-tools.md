---
id: "62"
title: "doctor.sh extension prerequisite check fails for uv tools in Git Bash (MSYS2)"
status: open
blocked_by: []
env: either
spec: ""
---

# doctor.sh extension prerequisite check fails for uv tools in Git Bash (MSYS2)

## What to build

Fix doctor.sh's extension prerequisite check so it correctly detects uv-installed Python tools (recall, tkt) when running from Git Bash on Windows. Currently reports false "prerequisite not met" errors even though the tools are installed and functional.

## Context

- **Observed (2026-07-27, personal machine):** `mise run doctor` reports "extension 'recall' prerequisite not met (recall --version)" yet also reports "recall ingest fresh (2h old)" — contradictory.
- **Root cause:** uv's trampoline `.exe` is found on PATH (`which recall` works), the binary launches, but the Python interpreter it spawns hits `ModuleNotFoundError` because MSYS2's environment corrupts `sys.prefix` / `sys.path` resolution — the venv's site-packages aren't found.
- **Works in:** PowerShell, cmd.exe, WSL bash. **Fails in:** Git Bash (MSYS2).
- **Why doctor uses Git Bash:** `mise run doctor` invokes `bash tools/generator/doctor.sh` — on Windows, mise uses Git Bash.
- **Ticket 39 (closed)** fixed the separate WSL `$HOME` vs `DEPLOY_HOME` issue but did not address this.

## Root cause (researched)

uv's trampoline architecture (Win32 PE shim → `GetModuleFileName` → relative path → spawns venv's `python.exe`) works correctly in native Windows shells. From Git Bash (MSYS2):

1. MSYS2's path conversion layer may corrupt environment variables the spawned Python needs for prefix resolution
2. MSYS2's own `/usr/bin/python` may shadow the venv's Python on the spawned process's PATH
3. The venv's `pyvenv.cfg` `home` key uses Windows paths that may resolve differently under MSYS2

Prior art: pipx#1232 (MINGW detection fix), uv#3953 (Cygwin path mixing), uv#1612 (subprocess exe resolution).

## Recommended approaches (pick one)

1. **PowerShell fallback for prerequisite checks on Windows:** When doctor detects it's on Windows (MSYS_NT/MINGW in `uname`), run prerequisite commands via `powershell.exe -NoProfile -Command "recall --version"` instead of directly. Guaranteed correct since uv tools work in PowerShell.

2. **Binary-exists + files-deployed check:** Instead of running `recall --version`, check: (a) `command -v recall` succeeds (binary on PATH), AND (b) the deployed extension files exist at `DEPLOY_HOME`. Avoids Python execution entirely.

3. **MSYS2 path conversion suppression:** Prefix the check with `MSYS_NO_PATHCONV=1` — may not help since the issue is in the spawned Python's environment, not path conversion of arguments.

## Acceptance criteria

- [ ] On a Windows machine with recall installed via `uv tool install`: `mise run doctor` does NOT report "extension recall prerequisite not met" (currently false negative)
- [ ] Same fix applies to tkt prerequisite check
- [ ] On Linux/macOS: behavior unchanged (direct `recall --version` still used)
- [ ] On Windows without recall installed: doctor still correctly reports the prerequisite is missing
- [ ] No false positives (binary exists on PATH but is broken/wrong version)

## Research

See `.scratch/research/uv-cross-shell.md` and `.scratch/research/git-bash-python.md` for full findings including uv issue links, failure mode analysis, and workaround options.
