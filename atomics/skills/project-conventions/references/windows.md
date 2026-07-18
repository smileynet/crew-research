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
