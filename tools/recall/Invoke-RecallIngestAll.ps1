#Requires -Version 5.1
<#
.SYNOPSIS
    Regular ingestion for recall — imports project .memory/ dirs and ingests kiro-cli session transcripts.

.DESCRIPTION
    Native Windows equivalent of tools/recall/ingest-all.sh.
    Auto-discovers projects with .memory/ under a root directory, imports each into recall,
    then ingests kiro-cli session transcripts.

.PARAMETER DryRun
    Show what would run without executing.

.PARAMETER ProjectsRoot
    Root directory to scan for projects. Default: $env:USERPROFILE\code

.PARAMETER SessionsDir
    Kiro session transcripts directory. Default: $env:USERPROFILE\.kiro\sessions\cli

.EXAMPLE
    .\Invoke-RecallIngestAll.ps1
    .\Invoke-RecallIngestAll.ps1 -DryRun
    .\Invoke-RecallIngestAll.ps1 -ProjectsRoot D:\projects
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$ProjectsRoot = (Join-Path $env:USERPROFILE "code"),
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
$Projects = @()
if (Test-Path $ProjectsRoot) {
    Get-ChildItem -Path $ProjectsRoot -Directory -Depth 1 -Filter ".memory" -ErrorAction SilentlyContinue |
        ForEach-Object {
            $projectDir = $_.Parent.FullName
            $wing = $_.Parent.Name
            $Projects += @{ Path = $_.FullName; Wing = $wing }
        }
}

Write-Host "$LogPrefix Starting recall ingestion"
Write-Host "  Projects root: $ProjectsRoot"
Write-Host "  Sessions dir:  $SessionsDir"
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
        Write-Host "  [dry-run] recall import $path --wing $wing --force"
    } else {
        Write-Host "  Importing $wing..."
        $output = & recall import $path --wing $wing --force 2>&1
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
