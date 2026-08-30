---
id: "137"
title: "Build cross-platform known-tools.sh dispatcher core"
status: done
blocked_by: ["136"]
---

# Build cross-platform known-tools.sh dispatcher core

## What to build

TBD

## Acceptance criteria

- [x] TBD

## Resolution (2026-08-30)

known-tools.sh created: SCRIPT_DIR/ROOT_DIR opener, uname -s OS detection (MINGW/MSYS/CYGWIN->windows, else unix), WSL detection + WIN_USER resolution, resolve_repo probe (CREW_TOOLS_ROOT/literal/~code/mnt-c), run_tool_cmd interop cascade (direct->cmd.exe->powershell.exe), yq registry reader. Verified: usage exits 2 on bad action (bad_action_rc=2), 0 on success; runs clean under set -euo pipefail on both WSL and Git Bash.
