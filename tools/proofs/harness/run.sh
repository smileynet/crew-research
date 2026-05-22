#!/bin/bash
# tools/proofs/harness/run.sh — Execute proof definitions against a tool adapter
# Usage: ./run.sh [--adapter kiro-cli] [--definition A4-file-resource] [--all]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROOFS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ADAPTERS_DIR="$PROOFS_DIR/adapters"
DEFINITIONS_DIR="$PROOFS_DIR/definitions"
RESULTS_DIR="$PROOFS_DIR/results"

# Defaults
ADAPTER="kiro-cli"
DEFINITION=""
RUN_ALL=false

# Parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --adapter) ADAPTER="$2"; shift 2 ;;
    --definition) DEFINITION="$2"; shift 2 ;;
    --all) RUN_ALL=true; shift ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

# Load adapter
ADAPTER_FILE="$ADAPTERS_DIR/$ADAPTER.yaml"
if [[ ! -f "$ADAPTER_FILE" ]]; then
  echo "Error: adapter not found: $ADAPTER_FILE" >&2
  exit 2
fi

# Extract adapter fields (requires yq)
if ! command -v yq &>/dev/null; then
  echo "Error: yq required (brew install yq / apt install yq)" >&2
  exit 2
fi

TOOL_NAME=$(yq '.tool' "$ADAPTER_FILE")
VERSION_CMD=$(yq '.version_command' "$ADAPTER_FILE")
INVOKE_CMD=$(yq '.invoke.command_no_agent' "$ADAPTER_FILE")
INVOKE_AGENT_CMD=$(yq '.invoke.command' "$ADAPTER_FILE")
DEFAULT_TIMEOUT=$(yq '.invoke.timeout // 90' "$ADAPTER_FILE")
AGENT_LOCATION=$(yq '.agent.location' "$ADAPTER_FILE")
SKILL_LOCATION=$(yq '.skill.location' "$ADAPTER_FILE")

# Get tool version
TOOL_VERSION=$($VERSION_CMD 2>/dev/null || echo "unknown")
TIMESTAMP=$(date -u +%Y-%m-%dT%H-%M-%SZ)

echo "Proof harness: $TOOL_NAME ($TOOL_VERSION)"
echo "Timestamp: $TIMESTAMP"
echo ""

# Collect definitions to run
DEFS=()
if [[ -n "$DEFINITION" ]]; then
  DEFS=("$DEFINITIONS_DIR/$DEFINITION.yaml")
elif [[ "$RUN_ALL" == true ]]; then
  mapfile -t DEFS < <(find "$DEFINITIONS_DIR" -name "*.yaml" | sort)
else
  echo "Specify --definition <id> or --all" >&2
  exit 1
fi

if [[ ${#DEFS[@]} -eq 0 ]]; then
  echo "No definitions found." >&2
  exit 1
fi

echo "Running ${#DEFS[@]} proof(s)..."
echo ""

# Results
PASS=0
FAIL=0
declare -a RESULTS=()

strip_ansi() {
  sed 's/\x1B\[[0-9;]*[a-zA-Z]//g'
}

run_proof() {
  local def_file="$1"
  local id=$(yq '.id' "$def_file")
  local assumption=$(yq '.assumption' "$def_file")
  local query=$(yq '.query' "$def_file")
  local timeout=$(yq ".timeout // $DEFAULT_TIMEOUT" "$def_file")
  local expect_present=$(yq '.expect.present // []' "$def_file")
  local expect_absent=$(yq '.expect.absent // []' "$def_file")

  # Create isolated workspace
  local workdir=$(mktemp -d -t "proof-${id}-XXXX")
  trap "rm -rf $workdir" RETURN

  # Deploy fixtures: files
  local file_count=$(yq '.fixtures.files | length' "$def_file")
  for ((i=0; i<file_count; i++)); do
    local path=$(yq ".fixtures.files | keys | .[$i]" "$def_file")
    local content=$(yq ".fixtures.files[\"$path\"]" "$def_file")
    mkdir -p "$workdir/$(dirname "$path")"
    echo "$content" > "$workdir/$path"
  done

  # Deploy fixtures: agents
  local agent_count=$(yq '.fixtures.agents | length' "$def_file")
  local agent_name=""
  for ((i=0; i<agent_count; i++)); do
    agent_name=$(yq ".fixtures.agents | keys | .[$i]" "$def_file")
    local agent_dir="$workdir/$(dirname "$(echo "$AGENT_LOCATION" | sed "s/{name}/$agent_name/")")"
    local agent_file="$workdir/$(echo "$AGENT_LOCATION" | sed "s/{name}/$agent_name/")"
    mkdir -p "$agent_dir"

    local tools=$(yq -o=json ".fixtures.agents[\"$agent_name\"].tools" "$def_file")
    local resources=$(yq -o=json ".fixtures.agents[\"$agent_name\"].resources" "$def_file")
    local prompt=$(yq ".fixtures.agents[\"$agent_name\"].prompt" "$def_file")

    cat > "$agent_file" << EOF
{
  "name": "$agent_name",
  "description": "Proof test agent",
  "tools": $tools,
  "allowedTools": $tools,
  "resources": $resources,
  "prompt": "$prompt"
}
EOF
  done

  # Deploy fixtures: skills
  local skill_count=$(yq '.fixtures.skills | length // 0' "$def_file")
  for ((i=0; i<skill_count; i++)); do
    local skill_name=$(yq ".fixtures.skills | keys | .[$i]" "$def_file")
    local skill_path="$workdir/$(echo "$SKILL_LOCATION" | sed "s/{name}/$skill_name/")"
    local skill_content=$(yq ".fixtures.skills[\"$skill_name\"]" "$def_file")
    mkdir -p "$(dirname "$skill_path")"
    echo "$skill_content" > "$skill_path"
  done

  # Invoke
  local cmd
  if [[ -n "$agent_name" ]]; then
    cmd=$(echo "$INVOKE_AGENT_CMD" | sed "s/{agent}/$agent_name/" | sed "s/{query}/$query/")
  else
    cmd=$(echo "$INVOKE_CMD" | sed "s/{query}/$query/")
  fi

  local output=""
  local tmpfile=$(mktemp)
  cd "$workdir"
  timeout "$timeout" bash -c "$cmd" > "$tmpfile" 2>&1 || true
  output=$(cat "$tmpfile" | strip_ansi)
  rm -f "$tmpfile"

  # Grade
  local status="PASS"
  local reason=""

  # Check present
  for val in $(yq -r '.expect.present[]' "$def_file" 2>/dev/null); do
    if ! echo "$output" | grep -qi "$val"; then
      status="FAIL"
      reason="Expected '$val' not found"
      break
    fi
  done

  # Check absent
  if [[ "$status" == "PASS" ]]; then
    for val in $(yq -r '.expect.absent[]' "$def_file" 2>/dev/null); do
      if echo "$output" | grep -qi "$val"; then
        status="FAIL"
        reason="Unexpected '$val' found"
        break
      fi
    done
  fi

  # Report
  if [[ "$status" == "PASS" ]]; then
    PASS=$((PASS + 1))
    echo "  ✅ $id"
  else
    FAIL=$((FAIL + 1))
    echo "  ❌ $id: $reason"
  fi

  RESULTS+=("{\"id\":\"$id\",\"status\":\"$status\",\"reason\":\"$reason\"}")
}

# Run all proofs
for def in "${DEFS[@]}"; do
  if [[ -f "$def" ]]; then
    run_proof "$def"
  else
    echo "  ⚠️  Not found: $def"
  fi
done

echo ""
echo "---"
echo "Results: $PASS passed, $FAIL failed (${#DEFS[@]} total)"

# Write results
mkdir -p "$RESULTS_DIR/$TOOL_NAME"
RESULTS_JSON=$(printf '%s,' "${RESULTS[@]}" | sed 's/,$//')
cat > "$RESULTS_DIR/$TOOL_NAME/$TIMESTAMP.json" << EOF
{
  "tool": "$TOOL_NAME",
  "tool_version": "$TOOL_VERSION",
  "timestamp": "$TIMESTAMP",
  "passed": $PASS,
  "failed": $FAIL,
  "total": ${#DEFS[@]},
  "tests": [$RESULTS_JSON]
}
EOF

echo "Results: $RESULTS_DIR/$TOOL_NAME/$TIMESTAMP.json"
exit $FAIL
