# tools/recall/profile-hook.ps1 — PowerShell profile staleness hook for recall
#
# Add to your $PROFILE:
#   . C:\Users\<you>\code\crew-research\tools\recall\profile-hook.ps1
#
# Or copy this function into your $PROFILE directly.
#
# Fires recall ingestion as a background job on shell open if >4h stale.

function Invoke-RecallIngestIfStale {
    # Success marker — written by the recall CLI after each ingest.
    # Same path doctor.sh and recall-session-start steering check.
    $successMarker = Join-Path $env:USERPROFILE ".recall\last_ingest"
    # Attempt stamp — touched when a run is fired; prevents retry storms
    # when ingestion keeps failing (success marker stays stale, correctly).
    $attemptStamp = Join-Path $env:USERPROFILE ".recall-last-ingest"
    $staleHours = 4

    # Check if recall is available
    if (-not (Get-Command recall -ErrorAction SilentlyContinue)) { return }

    # Fresh successful ingest → nothing to do
    if (Test-Path $successMarker) {
        $elapsed = (Get-Date) - (Get-Item $successMarker).LastWriteTime
        if ($elapsed.TotalHours -lt $staleHours) { return }
    }

    # Recent attempt (running or failed) → don't re-fire yet
    if (Test-Path $attemptStamp) {
        $elapsed = (Get-Date) - (Get-Item $attemptStamp).LastWriteTime
        if ($elapsed.TotalHours -lt $staleHours) { return }
    }

    # Touch attempt stamp immediately to prevent concurrent runs
    Set-Content -Path $attemptStamp -Value (Get-Date -Format o)

    # Find the ingest script
    $scriptPath = Join-Path $env:USERPROFILE "code\crew-research\tools\recall\Invoke-RecallIngestAll.ps1"
    if (-not (Test-Path $scriptPath)) {
        # Fallback: run recall commands directly
        $scriptPath = $null
    }

    # Run in background job (non-blocking)
    Start-Job -ScriptBlock {
        param($Script, $UserProfile)
        if ($Script -and (Test-Path $Script)) {
            & pwsh -NoProfile -NonInteractive -File $Script *> (Join-Path $UserProfile "recall-ingest.log")
        } else {
            # Inline fallback: discover and import
            $root = Join-Path $UserProfile "code"
            Get-ChildItem -Path $root -Directory -Depth 1 -Filter ".memory" -ErrorAction SilentlyContinue |
                ForEach-Object {
                    $wing = $_.Parent.Name
                    & recall import $_.FullName --wing $wing --force 2>&1
                }
            $sessions = Join-Path $UserProfile ".kiro\sessions\cli"
            if (Test-Path $sessions) {
                & recall ingest $sessions 2>&1
            }
        }
    } -ArgumentList $scriptPath, $env:USERPROFILE | Out-Null
}

# Run on profile load
Invoke-RecallIngestIfStale
