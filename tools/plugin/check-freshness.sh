#!/usr/bin/env bash
# check-freshness.sh — Check if deployed skills match their source repo
#
# Usage: bash tools/plugin/check-freshness.sh <tool-name> <deployed-path> <source-path>
# Exit: 0 = fresh, 1 = stale/missing, 2 = error
#
# Called by doctor.sh for each known tool with deployed skills.
set -euo pipefail

TOOL_NAME="${1:-}"
DEPLOYED="${2:-}"
SOURCE="${3:-}"

if [[ -z "$TOOL_NAME" || -z "$DEPLOYED" || -z "$SOURCE" ]]; then
  echo "Usage: check-freshness.sh <tool-name> <deployed-skill-path> <source-skill-path>" >&2
  exit 2
fi

# --- Check deployed exists ---
if [[ ! -d "$DEPLOYED" ]]; then
  echo "❌ $TOOL_NAME: deployed skill missing at $DEPLOYED"
  echo "   run: bash $(dirname "$SOURCE")/../tools/deploy-skills.sh"
  exit 1
fi

# --- Check source exists ---
if [[ ! -d "$SOURCE" ]]; then
  echo "⚠️  $TOOL_NAME: source repo not found at $SOURCE"
  echo "   (cannot check freshness without source)"
  exit 1
fi

# --- Compute content hashes ---
hash_dir() {
  # Hash all .md files in a skill directory (content that matters)
  find "$1" -name "*.md" -type f -exec sha256sum {} \; 2>/dev/null | sort | sha256sum | cut -d' ' -f1
}

deployed_hash=$(hash_dir "$DEPLOYED")
source_hash=$(hash_dir "$SOURCE")

if [[ "$deployed_hash" == "$source_hash" ]]; then
  echo "✅ $TOOL_NAME: deployed matches source (${deployed_hash:0:7})"
  exit 0
else
  echo "⚠️  $TOOL_NAME: stale (deployed: ${deployed_hash:0:7}, source: ${source_hash:0:7})"
  # Check if it's a symlink (would auto-update)
  if [[ -L "$DEPLOYED" ]]; then
    link_target=$(readlink "$DEPLOYED")
    echo "   symlink → $link_target"
    echo "   (symlink should be live — check if source repo was rebased or force-pushed)"
  else
    echo "   run: bash $(dirname "$SOURCE")/../tools/deploy-skills.sh"
  fi
  exit 1
fi
