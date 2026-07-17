#!/bin/bash
# tools/recall/ingest-all.sh — Regular ingestion for recall
# Imports project .memory/ dirs and ingests kiro-cli session transcripts.
#
# Usage:
#   bash ingest-all.sh              # run all ingestions
#   bash ingest-all.sh --dry-run    # show what would run
#
# Configuration:
#   RECALL_PROJECTS_ROOT  — root dir to scan for projects (default: /mnt/c/Users/$USER/code)
#   RECALL_SESSIONS_DIR   — kiro session transcripts dir (auto-detected)
#   RECALL_STALE_HOURS    — hours before considering stale (default: 4)
#
# Schedule via cron (WSL):
#   0 */4 * * * ~/.local/bin/recall-ingest-all.sh >> /tmp/recall-ingest.log 2>&1

set -euo pipefail

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

LOG_PREFIX="[recall-ingest $(date '+%Y-%m-%d %H:%M')]"

# ─── Configuration ─────────────────────────────────────────────
# Detect Windows user home via WSL mount (works for any user)
if [[ -d "/mnt/c/Users/$USER" ]]; then
  WIN_HOME="/mnt/c/Users/$USER"
elif [[ -n "${WSLENV:-}" || -d "/mnt/c" ]]; then
  # Fallback: find the Windows username from cmd.exe
  WIN_HOME="/mnt/c/Users/$(cmd.exe /C "echo %USERNAME%" 2>/dev/null | tr -d '\r' || echo "$USER")"
else
  WIN_HOME="$HOME"
fi

PROJECTS_ROOT="${RECALL_PROJECTS_ROOT:-$WIN_HOME/code}"
SESSIONS_DIR="${RECALL_SESSIONS_DIR:-$WIN_HOME/.kiro/sessions/cli}"

# Projects to import. Auto-discovers all dirs with .memory/ under PROJECTS_ROOT.
# Override by setting RECALL_PROJECTS as colon-separated "path:wing" pairs.
if [[ -n "${RECALL_PROJECTS:-}" ]]; then
  IFS=';' read -ra PROJECTS <<< "$RECALL_PROJECTS"
else
  PROJECTS=()
  if [[ -d "$PROJECTS_ROOT" ]]; then
    while IFS= read -r mem_dir; do
      project_dir="$(dirname "$mem_dir")"
      wing="$(basename "$project_dir")"
      PROJECTS+=("$mem_dir:$wing")
    done < <(find "$PROJECTS_ROOT" -maxdepth 2 -name '.memory' -type d 2>/dev/null)
  fi
fi

# ─── Import project knowledge ─────────────────────────────────
echo "$LOG_PREFIX Starting recall ingestion"
echo "  Projects root: $PROJECTS_ROOT"
echo "  Sessions dir:  $SESSIONS_DIR"
echo "  Projects found: ${#PROJECTS[@]}"
echo ""

for entry in "${PROJECTS[@]}"; do
  path="${entry%%:*}"
  wing="${entry##*:}"

  if [[ ! -d "$path" ]]; then
    echo "  ⚠️  Skipped $wing — $path not found"
    continue
  fi

  if [[ "$DRY_RUN" == true ]]; then
    echo "  [dry-run] recall import $path --wing $wing --force"
  else
    echo "  Importing $wing..."
    recall import "$path" --wing "$wing" --force 2>&1 | sed 's/^/    /'
  fi
done

echo ""

# ─── Ingest session transcripts ───────────────────────────────
if [[ -d "$SESSIONS_DIR" ]]; then
  if [[ "$DRY_RUN" == true ]]; then
    echo "  [dry-run] recall ingest $SESSIONS_DIR"
  else
    echo "  Ingesting kiro-cli sessions..."
    recall ingest "$SESSIONS_DIR" 2>&1 | sed 's/^/    /'
  fi
else
  echo "  ⚠️  No sessions dir: $SESSIONS_DIR"
fi

echo ""
echo "$LOG_PREFIX Done."

# ─── Show status ──────────────────────────────────────────────
if [[ "$DRY_RUN" == false ]]; then
  echo ""
  recall status
fi
