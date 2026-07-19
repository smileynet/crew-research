# Recall CLI Reference

## Installation

```bash
uv tool install ./tools/recall                # from a crew-research clone (PyPI "recall" is squatted — never install from PyPI)
```

**Verify:** `recall --version` should print `recall 0.1.0`

## Scheduled Ingestion

Recall needs periodic ingestion of project knowledge and session transcripts. The `Invoke-RecallIngestAll.ps1` (Windows) or `ingest-all.sh` (Unix) script auto-discovers projects and ingests everything.

### Windows (native — recommended)
```powershell
# One-time: register scheduled task (every 4h)
$action = New-ScheduledTaskAction -Execute "pwsh.exe" `
  -Argument "-NoProfile -NonInteractive -File `"$env:USERPROFILE\code\crew-research\tools\recall\Invoke-RecallIngestAll.ps1`""
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 4)
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName "RecallIngest" -Action $action -Trigger $trigger -Settings $settings

# Profile hook (add to $PROFILE — fires on shell open if >4h stale)
. $env:USERPROFILE\code\crew-research\tools\recall\profile-hook.ps1
```

### macOS
```bash
cat > ~/Library/LaunchAgents/com.recall.ingest.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.recall.ingest</string>
  <key>ProgramArguments</key><array>
    <string>recall</string><string>ingest</string>
    <string>~/.kiro/sessions/cli</string>
  </array>
  <key>StartCalendarInterval</key><dict>
    <key>Hour</key><integer>3</integer>
    <key>Minute</key><integer>0</integer>
  </dict>
</dict></plist>
EOF
launchctl load ~/Library/LaunchAgents/com.recall.ingest.plist
```

### Linux
```bash
(crontab -l 2>/dev/null; echo "0 */4 * * * ~/.local/bin/recall-ingest-all.sh >> /tmp/recall-ingest.log 2>&1") | crontab -

# .bashrc staleness hook (fires on shell open if >4h stale)
cat tools/recall/bashrc-hook.sh >> ~/.bashrc
```

### Verify schedule
- Windows: `Get-ScheduledTask -TaskName "RecallIngest" | Select State`
- macOS: `launchctl list | grep recall`
- Linux: `crontab -l | grep recall`

## Staleness Check

After each ingestion, the scripts write a stamp file (`~/.recall-last-ingest`). The profile hook checks this on shell open and fires background ingestion if >4h stale.

To manually check staleness:
- Windows: `Get-Item $env:USERPROFILE\.recall-last-ingest | Select LastWriteTime`
- Unix: `stat ~/.recall-last-ingest`

To manually run full ingestion:
- Windows: `pwsh -File tools/recall/Invoke-RecallIngestAll.ps1`
- Unix: `bash tools/recall/ingest-all.sh`

## Commands

```bash
recall search "query"                         # search all wings
recall search "query" --wing name             # scoped to project
recall search "query" --room decisions        # scoped to room
recall search "query" --results 10            # more results

recall add "text" --wing X --room Y --type T  # persist a fact
recall add "text" --type decision             # wing auto-detects from cwd

recall ingest ~/.kiro/sessions/cli            # auto-tag wings from cwd
recall ingest <path> --project ~/code/myapp   # filter to one project

recall prime --wing name                      # session-start context
recall prime                                  # wing auto-detects from cwd
recall status                                 # show indexed content
```

## Types for write-back

| Type | Use for |
|------|---------|
| `decision` | Choices made, options rejected, rationale |
| `fact` | Stable truths about the project |
| `lesson` | What was tried and failed, anti-patterns discovered |
| `preference` | User preferences, conventions, style choices |

## Storage

- Database: `~/.recall/recall.sqlite3`
- Config: `~/.recall/config.json` (optional, for custom topic_keywords)
- Model: `bge-base-en-v1.5` int8 ONNX (~105MB, cached in ~/.cache/huggingface/)

## Scoping

- **Wing** = project (auto-derived from cwd for `add` and `prime`; cross-project for `search`)
- **Room** = topic (auto-classified by keyword matching during ingest)
- Omit `--wing` on search to find content across all projects
- Omit `--wing` on add/prime to use cwd-based auto-detection
- Pass `--wing name` to override auto-detection
