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
