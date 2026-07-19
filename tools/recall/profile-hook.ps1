# tools/recall/profile-hook.ps1 — PowerShell profile staleness hook for recall
#
# Add to your $PROFILE:
#   . C:\Users\<you>\code\crew-research\tools\recall\profile-hook.ps1
#
# Or copy this function into your $PROFILE directly.
#
# Fires recall ingestion as a background job on shell open if >4h stale.

function Invoke-RecallIngestIfStale {
    $stampFile = Join-Path $env:USERPROFILE ".recall-last-ingest"
    $staleHours = 4

    # Check if recall is available
    if (-not (Get-Command recall -ErrorAction SilentlyContinue)) { return }

    # Check staleness
    if (Test-Path $stampFile) {
        $lastRun = (Get-Item $stampFile).LastWriteTime
        $elapsed = (Get-Date) - $lastRun
        if ($elapsed.TotalHours -lt $staleHours) { return }
    }

    # Touch stamp immediately to prevent concurrent runs
    Set-Content -Path $stampFile -Value (Get-Date -Format o)

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
