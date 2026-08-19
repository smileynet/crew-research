# DEPRECATED: Use `recall sync` directly. This script remains for users
# with scheduled tasks pointing here — it still works, but new installs
# should use the Rust binary directly in the scheduled task action.
#
#Requires -Version 5.1
<#
.SYNOPSIS
    Regular ingestion for recall — imports project .memory/ dirs and ingests kiro-cli session transcripts.

.DESCRIPTION
    Native Windows equivalent of tools/recall/ingest-all.sh.
    Auto-discovers projects with .memory/ under one or more root directories, imports each into recall,
    then ingests kiro-cli session transcripts.

.PARAMETER DryRun
    Show what would run without executing.

.PARAMETER ProjectsRoot
    Root directories to scan for projects. Accepts multiple paths.
    Default: $env:USERPROFILE\code and D:\code (if D:\code exists).

.PARAMETER SessionsDir
    Kiro session transcripts directory. Default: $env:USERPROFILE\.kiro\sessions\cli

.EXAMPLE
    .\Invoke-RecallIngestAll.ps1
    .\Invoke-RecallIngestAll.ps1 -DryRun
    .\Invoke-RecallIngestAll.ps1 -ProjectsRoot D:\projects
    .\Invoke-RecallIngestAll.ps1 -ProjectsRoot C:\Users\me\code, D:\code
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [string[]]$ProjectsRoot,
    [string]$SessionsDir = (Join-Path $env:USERPROFILE ".kiro\sessions\cli")
)

$ErrorActionPreference = "Continue"
$LogPrefix = "[recall-ingest $(Get-Date -Format 'yyyy-MM-dd HH:mm')]"

# Verify recall is available (dry-run may proceed without it)
if (-not (Get-Command recall -ErrorAction SilentlyContinue)) {
    if ($DryRun) {
        Write-Warning "recall not found on PATH — showing plan only. Install: uv tool install <crew-research>/tools/recall"
    } else {
        Write-Error "recall not found on PATH. Install: uv tool install <crew-research>/tools/recall"
        exit 1
    }
}

# ─── Discover projects ─────────────────────────────────────────
# Default roots: ~/code + D:\code (if it exists). Override with -ProjectsRoot.
if (-not $ProjectsRoot) {
    $ProjectsRoot = @((Join-Path $env:USERPROFILE "code"))
    if (Test-Path "D:\code") { $ProjectsRoot += "D:\code" }
}

$Projects = @()
foreach ($root in $ProjectsRoot) {
    if (Test-Path $root) {
        Get-ChildItem -Path $root -Directory -Depth 1 -Filter ".memory" -ErrorAction SilentlyContinue |
            ForEach-Object {
                $wing = $_.Parent.Name -replace '-', '_'
                # Deduplicate: first root wins if same wing name exists
                if ($Projects.Wing -notcontains $wing) {
                    $Projects += @{ Path = $_.FullName; Wing = $wing }
                }
            }
    }
}

Write-Host "$LogPrefix Starting recall ingestion"
Write-Host "  Projects roots: $($ProjectsRoot -join ', ')"
Write-Host "  Sessions dir:   $SessionsDir"
Write-Host "  Projects found: $($Projects.Count)"
Write-Host ""

# ─── Import project knowledge ─────────────────────────────────
foreach ($entry in $Projects) {
    $path = $entry.Path
    $wing = $entry.Wing

    if (-not (Test-Path $path)) {
        Write-Host "  ⚠️  Skipped $wing — $path not found"
        continue
    }

    if ($DryRun) {
        Write-Host "  [dry-run] recall import $path --wing $wing"
    } else {
        Write-Host "  Importing $wing..."
        $output = & recall import $path --wing $wing 2>&1
        $output | ForEach-Object { Write-Host "    $_" }
    }
}

Write-Host ""

# ─── Ingest session transcripts ───────────────────────────────
if (Test-Path $SessionsDir) {
    if ($DryRun) {
        Write-Host "  [dry-run] recall ingest $SessionsDir"
    } else {
        Write-Host "  Ingesting kiro-cli sessions..."
        $output = & recall ingest $SessionsDir 2>&1
        $output | ForEach-Object { Write-Host "    $_" }
    }
} else {
    Write-Host "  ⚠️  No sessions dir: $SessionsDir"
}

Write-Host ""
Write-Host "$LogPrefix Done."
