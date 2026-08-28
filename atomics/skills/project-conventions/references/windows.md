# Windows Shell Safety

## Start-Process Rules (ABSOLUTE)

**NEVER use these — they ALWAYS block:**
- `-RedirectStandardOutput` or `-RedirectStandardError` — forces pipe handles that block until child exits
- `-NoNewWindow` — shares parent console, blocks
- Any combination of the above with other flags

**Correct pattern (fire-and-forget):**
```powershell
Start-Process -FilePath "<exe>" -ArgumentList "<args>" -WorkingDirectory "<dir>"
```

**If you need logs:** redirect inside the argument string:
```powershell
Start-Process -FilePath "cmd" -ArgumentList "/c", "python script.py > log.txt 2>&1"
```

## Pre-Flight Check

Before ANY Start-Process call, verify:
1. No `-Redirect*` flags present
2. No `-NoNewWindow` flag present
3. No wrapping in `pwsh -Command` (nested shell waits)

## Observing Background Processes

```powershell
netstat -ano | findstr ":PORT.*LISTENING"     # port check
Get-Process -Name "python" -ErrorAction SilentlyContinue  # process exists
Invoke-RestMethod -Uri "http://127.0.0.1:PORT/endpoint"   # API check
```

## Long-Running Commands

For builds, installs, test suites, data processing:
- Launch with Start-Process (no redirects)
- Sleep briefly, then observe via port/process/API check
- Report outcome from observation, not from captured output

## WSL Invocation (from PowerShell)

**Problem:** `wsl bash -c "..."` inherits Windows PATH (with parentheses, spaces). Bash interprets `(` as subshell syntax → `unexpected token` errors.

**Safe patterns:**
```powershell
# Single-quoted string — PowerShell passes literally, no interpolation
wsl bash -c 'export WIN_USERNAME=$(cmd.exe /C "echo %USERNAME%" 2>/dev/null | tr -d "\r") && cd /mnt/c/Users/$WIN_USERNAME/code/project && bash script.sh'

# For complex commands: write to file first
wsl bash /mnt/c/Users/uosmi/code/project/.scratch/task.sh
```

**Key rules:**
- Always single-quote the `-c` argument in PowerShell (prevents `$VAR` interpolation)
- If the bash command itself needs single quotes internally, use a script file instead
- `WIN_USERNAME` is required when WSL user ≠ Windows user (common: WSL defaults to `user`)
- Never rely on `$PATH` inherited from Windows — it contains paths with `(` that break bash. Set PATH explicitly inside the bash command if needed.

## Git Bash Invocation (from PowerShell)

Two live failures in one field session, despite prior documentation (2026-07-17):

**NEVER pass `$`-containing or multi-line commands via `bash -c "..."`:**
- PowerShell interpolates `$PATH`, `$?`, `$@` inside double-quoted strings BEFORE bash sees them
- Symptoms range from loud (`unexpected EOF while looking for matching '`) to silent-and-wrong (`echo rc=$?` printing `rc=True` — a corrupted verdict that reads as plausible)

**The robust default — write a script file:**
```powershell
# Write the command to a .sh file (e.g. .scratch/task.sh), then:
& "C:\Program Files\Git\bin\bash.exe" .scratch/task.sh
```

- Single-quoted PowerShell strings (`'...'`) are safe for short commands, but fail as soon as the command itself needs single quotes — script file wins
- Windows-native interpreters (python.exe) called from bash do NOT share bash's `/tmp` — a `python - <<EOF` heredoc asserting on `/tmp/...` files fails with a misleading assertion error, not a path error. Use repo-relative paths for cross-interpreter temp files.
- **PowerShell `cd`/`Push-Location` CANNOT enter an MSYS `/tmp/...` path** (2026-08-28: codex silently ran in the repo root instead of a `/tmp` fixture, producing a misleading "target unavailable" result — not an error). Keep the whole `cd`+invoke chain INSIDE one `bash -c`; never resolve an MSYS path in PowerShell then hand it to a native exe.

## Bounding hang-prone agent CLIs (Start-Job + Wait-Job)

opencode (`run` has a documented never-exit bug) and kiro-cli/codex can hang or run for minutes. `timeout` alone does NOT catch never-exit (the process still looks "busy"). On Windows the reliable bounded wrapper is a PowerShell job with a hard timeout (field-proven ~6× on 2026-08-28):

```powershell
$j = Start-Job -ScriptBlock { & "C:\Program Files\Git\bin\bash.exe" -c 'cd <dir>; <agent-cli> ... > out.log 2>err.log' }
if (Wait-Job $j -Timeout 240) { Receive-Job $j } else { "TIMED OUT"; Stop-Job $j }
Remove-Job $j -Force
```

- Run the invocation ALONE in the job; inspect the output FILE in a separate call (chaining the CLI with output-reading blocks the whole call).
- Validate success by OUTPUT CONTENT, never exit code — opencode AND codex both exit 0 on failure / nonzero on would-be success.
- `Stop-Job` may leak grandchild MCP procs; for a hard kill of the tree use `taskkill /T /F` on the PID.
