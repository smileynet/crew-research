#!/bin/bash
# tools/proofs/harness/run-proof.sh — Run a subagent reliability proof against one or all tools
# Usage: ./run-proof.sh --proof S1 [--tool kiro-cli|codex|agy|crush|all]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROOFS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DEFS_DIR="$PROOFS_DIR/definitions"
RESULTS_DIR="$PROOFS_DIR/results"

PROOF=""
TOOL="all"
TIMEOUT=180

while [[ $# -gt 0 ]]; do
  case "$1" in
    --proof) PROOF="$2"; shift 2 ;;
    --tool) TOOL="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

[[ -z "$PROOF" ]] && { echo "Usage: --proof S1|S2|S3|S4 [--tool kiro-cli|codex|agy|crush|all]"; exit 1; }

TIMESTAMP=$(date -u +%Y-%m-%dT%H-%M-%SZ)
RESULT_DIR="$RESULTS_DIR/proof-${PROOF}-${TIMESTAMP}"
mkdir -p "$RESULT_DIR"

echo "Proof: $PROOF | Tool: $TOOL | Timeout: ${TIMEOUT}s"
echo "Results: $RESULT_DIR"
echo ""

# Determine tools to run
TOOLS=()
if [[ "$TOOL" == "all" ]]; then
  command -v kiro-cli &>/dev/null && TOOLS+=("kiro-cli")
  command -v codex &>/dev/null && TOOLS+=("codex")
  command -v agy &>/dev/null && TOOLS+=("agy")
  command -v crush &>/dev/null && TOOLS+=("crush")
else
  TOOLS+=("$TOOL")
fi

echo "Tools: ${TOOLS[*]}"
echo ""

# Run proof query against each tool WITHOUT global steering
run_query() {
  local tool="$1" query="$2" workdir="$3" outfile="$4"

  case "$tool" in
    kiro-cli)
      # Use isolated KIRO_HOME to avoid loading global steering
      local isolated_home=$(mktemp -d)
      KIRO_HOME="$isolated_home" timeout "$TIMEOUT" \
        kiro-cli chat --no-interactive "$query" > "$outfile" 2>&1 || true
      rm -rf "$isolated_home"
      ;;
    codex)
      timeout "$TIMEOUT" \
        codex exec -C "$workdir" -s danger-full-access --ignore-rules "$query" > "$outfile" 2>&1 || true
      ;;
    agy)
      timeout "$TIMEOUT" \
        agy --print --print-timeout "${TIMEOUT}s" "$query" > "$outfile" 2>&1 || true
      ;;
    crush)
      timeout "$TIMEOUT" \
        crush run --quiet --model glm/glm-5.2 "$query" > "$outfile" 2>&1 || true
      ;;
  esac
}

# Setup proof files
setup_proof_files() {
  local proof_id="$1"
  local workdir=$(mktemp -d -t "proof-${proof_id}-XXXX")

  case "$proof_id" in
    S1)
      for i in 1 2 3 4 5 6; do
        echo "CANARY_S1_FILE$i" > "$workdir/file$i.md"
      done
      ;;
    S2)
      # Generate ~2000 words of structured content
      python3 -c "
lines = []
for i in range(1, 21):
    lines.append(f'## ADR {i:03d}: Decision about component {i}')
    lines.append(f'Context: System requires component {i}. Expected throughput {i*1000} req/s.')
    lines.append(f'Decision: Selected approach {chr(64+i)} for {i*5}x throughput. Trade-off: +{i*100}MB memory.')
    lines.append(f'Consequences: Migration of {i*3} consumers over {i} sprints.')
    lines.append('')
open('$workdir/large-data.md', 'w').write('\n'.join(lines))
"
      ;;
    S3)
      for batch in 1 2 3; do
        for stage in a b c d; do
          echo "CANARY_B${batch}_${stage}" > "$workdir/batch${batch}-${stage}.md"
        done
      done
      ;;
    S4)
      cat > "$workdir/input.md" << 'FORCES'
# Force Inventory
## Player Movement
- Desire: responsive controls (< 100ms)
- Constraint: network latency 50-150ms
- Desire: smooth spectator view
- Constraint: server tick rate 30Hz
## Game Economy
- Desire: rewarding progression each session
- Constraint: cosmetics only (no P2W)
- Desire: long-term engagement
- Constraint: new players not permanently behind
Produce a tension table: for each conflicting pair, name the tension.
FORCES
      ;;
  esac

  echo "$workdir"
}

# Build query for each proof
build_query() {
  local proof_id="$1" workdir="$2" variant="${3:-}"

  case "$proof_id" in
    S1)
      echo "Dispatch 6 subagents in parallel. Each reads one file and returns ONLY the text it contains. File 1: $workdir/file1.md, File 2: $workdir/file2.md, File 3: $workdir/file3.md, File 4: $workdir/file4.md, File 5: $workdir/file5.md, File 6: $workdir/file6.md. Report all 6 values."
      ;;
    S2)
      if [[ "$variant" == "inline" ]]; then
        local content=$(cat "$workdir/large-data.md")
        echo "Dispatch a subagent to analyze this data and produce a table with ADR#, Decision, Risk: $content"
      else
        echo "Dispatch a subagent to: Read $workdir/large-data.md and produce a table with columns: ADR#, Decision (one line), Risk (one line)."
      fi
      ;;
    S3)
      echo "Run 3 sequential batches. Each dispatches 4 subagents reading one file each. Batch 1: $workdir/batch1-a.md through batch1-d.md. Wait. Batch 2: $workdir/batch2-a.md through batch2-d.md. Wait. Batch 3: $workdir/batch3-a.md through batch3-d.md. Report success count per batch."
      ;;
    S4)
      if [[ "$variant" == "inline" ]]; then
        local content=$(cat "$workdir/input.md")
        echo "Dispatch a subagent to produce a tension table from this force inventory: $content"
      else
        echo "Dispatch a subagent to: Read $workdir/input.md and produce a tension table showing conflicting force pairs."
      fi
      ;;
  esac
}

# Execute
WORKDIR=$(setup_proof_files "$PROOF")
echo "Workdir: $WORKDIR"
echo ""

for tool in "${TOOLS[@]}"; do
  echo "--- $tool ---"

  if [[ "$PROOF" == "S2" || "$PROOF" == "S4" ]]; then
    # Two variants: inline vs file-read
    echo "  [file-read]"
    run_query "$tool" "$(build_query "$PROOF" "$WORKDIR" "fileread")" "$WORKDIR" "$RESULT_DIR/${tool}-fileread.txt"

    echo "  [inline]"
    run_query "$tool" "$(build_query "$PROOF" "$WORKDIR" "inline")" "$WORKDIR" "$RESULT_DIR/${tool}-inline.txt"
  else
    run_query "$tool" "$(build_query "$PROOF" "$WORKDIR")" "$WORKDIR" "$RESULT_DIR/${tool}-result.txt"
  fi

  echo "  done"
  echo ""
done

# Analyze results
echo "=== Results ==="
for tool in "${TOOLS[@]}"; do
  case "$PROOF" in
    S1)
      count=$(grep -c "CANARY_S1" "$RESULT_DIR/${tool}-result.txt" 2>/dev/null || echo "0")
      echo "  $tool: $count/6 canaries returned"
      ;;
    S2|S4)
      fr_lines=$(wc -l < "$RESULT_DIR/${tool}-fileread.txt" 2>/dev/null || echo "0")
      in_lines=$(wc -l < "$RESULT_DIR/${tool}-inline.txt" 2>/dev/null || echo "0")
      echo "  $tool: file-read=${fr_lines}L, inline=${in_lines}L"
      ;;
    S3)
      for b in 1 2 3; do
        count=$(grep -c "CANARY_B${b}" "$RESULT_DIR/${tool}-result.txt" 2>/dev/null || echo "0")
        echo "  $tool batch $b: $count/4"
      done
      ;;
  esac
done

# Cleanup
rm -rf "$WORKDIR"
echo ""
echo "Full output: $RESULT_DIR/"
