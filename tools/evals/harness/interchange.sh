#!/usr/bin/env bash
# interchange.sh — move eval runs between machines (ticket 32).
#
#   export <results-dir> [dest.tar.gz]   bundle meta + scores + outputs into one file
#   import <bundle.tar.gz> [results-root] validate + unpack into results/ with provenance
#
# results/ is gitignored by design; a bundle is the sanctioned way for a
# crush/agy-capable machine's runs to land here and join local runs by def id.
# Import REJECTS bundles whose rows lack the row-level join keys (id, adapter)
# — a tampered or pre-ticket-29 bundle fails loudly, never merges silently.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RESULTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)/results"

usage() { echo "usage: interchange.sh export <results-dir> [dest.tar.gz] | import <bundle.tar.gz> [results-root]" >&2; exit 2; }

# Every non-SKIP row must carry a non-null id and an adapter (the join keys).
validate_scores() {
  local scores="$1" n=0
  while IFS= read -r row; do
    [[ -z "$row" ]] && continue
    n=$((n + 1))
    grep -q '"status":"SKIP"' <<< "$row" && continue
    if ! grep -q '"id":"[^"]' <<< "$row"; then
      echo "row $n: missing/null id key (join key required)" ; return 1
    fi
    if ! grep -q '"adapter":"[^"]' <<< "$row"; then
      echo "row $n: missing adapter key (join key required)" ; return 1
    fi
  done < "$scores"
  [[ $n -gt 0 ]] || { echo "scores.jsonl is empty"; return 1; }
  return 0
}

cmd="${1:-}"; shift || true
case "$cmd" in
  export)
    src="${1:-}"; [[ -n "$src" ]] || usage
    [[ -d "$src" ]] || src="$RESULTS_DIR/$src"
    [[ -f "$src/scores.jsonl" && -f "$src/meta.json" ]] || { echo "Error: not a results dir (needs scores.jsonl + meta.json): $src" >&2; exit 2; }
    if ! reason=$(validate_scores "$src/scores.jsonl"); then
      echo "Error: refusing to export invalid run — $reason" >&2; exit 1
    fi
    base=$(basename "$src")
    dest="${2:-eval-run-$base.tar.gz}"
    tar czf "$dest" -C "$(dirname "$src")" "$base"
    echo "Exported $base -> $dest ($(du -h "$dest" | cut -f1))"
    ;;
  import)
    bundle="${1:-}"; [[ -f "$bundle" ]] || usage
    root="${2:-$RESULTS_DIR}"
    tmp=$(mktemp -d -t "eval-import-XXXX")
    tar xzf "$bundle" -C "$tmp"
    run_dir=$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -1)
    [[ -n "$run_dir" && -f "$run_dir/scores.jsonl" && -f "$run_dir/meta.json" ]] || { echo "Error: bundle missing run dir with scores.jsonl + meta.json — rejected" >&2; rm -rf "$tmp"; exit 1; }
    if ! reason=$(validate_scores "$run_dir/scores.jsonl"); then
      echo "Error: bundle rejected — $reason" >&2; rm -rf "$tmp"; exit 1
    fi
    base=$(basename "$run_dir")
    dest="$root/$base"
    [[ -e "$dest" ]] && { echo "Error: $dest already exists — refusing to overwrite" >&2; rm -rf "$tmp"; exit 1; }
    mkdir -p "$root"
    mv "$run_dir" "$dest"
    rm -rf "$tmp"
    echo "{\"imported_from\":\"$(basename "$bundle")\",\"imported_at\":\"$(date -u +%Y-%m-%dT%H-%M-%SZ)\",\"host\":\"$(hostname)\"}" > "$dest/imported-from.json"
    echo "Imported $base -> $dest (provenance: imported-from.json)"
    echo "Join local + imported rows by def id, e.g.:"
    echo "  grep -h '\"id\":\"<def-id>\"' $root/*/scores.jsonl"
    ;;
  *) usage ;;
esac
