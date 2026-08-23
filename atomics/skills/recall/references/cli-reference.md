# Recall CLI Reference

## Installation

```bash
cargo install --path ~/code/recall            # from a recall repo clone
```

**Verify:** `recall --version` should print `recall 0.2.0`

## Scheduled Ingestion

Recall needs periodic ingestion of project knowledge and session transcripts. The `recall sync` command auto-discovers projects and ingests everything.

### Windows (native — recommended)
```powershell
# One-time: register scheduled task (every 4h)
$action = New-ScheduledTaskAction -Execute "recall.exe" -Argument "sync"
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 4)
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName "RecallIngest" -Action $action -Trigger $trigger -Settings $settings
```

### macOS
```bash
cat > ~/Library/LaunchAgents/com.recall.ingest.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.recall.ingest</string>
  <key>ProgramArguments</key><array>
    <string>recall</string><string>sync</string>
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
(crontab -l 2>/dev/null; echo "0 */4 * * * recall sync >> /tmp/recall-ingest.log 2>&1") | crontab -
```

### Verify schedule
- Windows: `Get-ScheduledTask -TaskName "RecallIngest" | Select State`
- macOS: `launchctl list | grep recall`
- Linux: `crontab -l | grep recall`

## Staleness Check

After each sync, recall writes a timestamp to `~/.recall/last_ingest`. The `recall-session-start`
steering checks this on session open and warns if >24h stale.

To manually check: `recall health --json | jq .last_ingest`

To manually run: `recall sync`

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


## Known Issues

| Issue | Symptom | Workaround |
|-------|---------|------------|
| `recall status` empty output | Command returns exit 0 but prints nothing, even with indexed data | Use `recall search "test"` to verify DB is populated; status display is cosmetic |
