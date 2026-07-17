# Recall CLI Reference

## Installation

```bash
uv tool install ./tools/recall                # from a crew-research clone (PyPI "recall" is squatted — never install from PyPI)
```

**Windows (Application Control blocks .exe):** Create `recall.cmd` on PATH:
```cmd
@echo off
python -c "import sys; sys.path.insert(0, r'%APPDATA%\uv\tools\recall\Lib\site-packages'); from recall.cli import main; main()" %*
```
Then rename `recall.exe` → `recall.exe.blocked` so `.cmd` takes priority.

**Verify:** `recall --version` should print `recall 0.1.0`

## Daily Ingest Setup

Recall needs periodic ingestion of session transcripts. Set up a daily task:

### Windows
```powershell
schtasks /Create /SC DAILY /TN "RecallIngest" /TR "cmd /c recall.cmd ingest %USERPROFILE%\.kiro\sessions\cli" /ST 03:00 /F
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
(crontab -l 2>/dev/null; echo "0 3 * * * recall ingest ~/.kiro/sessions/cli") | crontab -
```

### Verify schedule
- Windows: `schtasks /Query /TN "RecallIngest"`
- macOS: `launchctl list | grep recall`
- Linux: `crontab -l | grep recall`

## Staleness Check

After each ingest, recall writes `~/.recall/last_ingest` (unix timestamp). The `recall-session-start` steering checks this at session start and warns the user if >24h stale.

To manually check: `cat ~/.recall/last_ingest`
To manually update: `recall ingest ~/.kiro/sessions/cli`

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
