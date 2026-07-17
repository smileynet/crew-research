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

# Require yq
if ! command -v yq &>/dev/null; then
  echo "Error: yq required (brew install yq / apt install yq)" >&2
  exit 2
fi

TOOL_NAME=$(yq '.tool' "$ADAPTER_FILE")
VERSION_CMD=$(yq '.version_command' "$ADAPTER_FILE")
INVOKE_CMD=$(yq '.invoke.command' "$ADAPTER_FILE")
INVOKE_NO_AGENT_CMD=$(yq '.invoke.command_no_agent' "$ADAPTER_FILE")
DEFAULT_TIMEOUT=$(yq '.invoke.timeout // 90' "$ADAPTER_FILE")
AGENT_FORMAT=$(yq '.agent.format' "$ADAPTER_FILE")
AGENT_LOCATION=$(yq '.agent.location' "$ADAPTER_FILE")
SKILL_LOCATION=$(yq '.skill.location' "$ADAPTER_FILE")
EAGER_LOCATION=$(yq '.eager_context.location' "$ADAPTER_FILE")
EAGER_MERGE=$(yq '.eager_context.merge_strategy // "file"' "$ADAPTER_FILE")

# Get tool version
TOOL_VERSION=$($VERSION_CMD 2>/dev/null | head -1 || echo "unknown")
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

PASS=0
FAIL=0
declare -a RESULTS=()

strip_ansi() {
  sed 's/\x1B\[[0-9;]*[a-zA-Z]//g'
}

# Deploy eager files based on adapter strategy
deploy_eager_file() {
  local workdir="$1"
  local filename="$2"
  local content="$3"
  local agent_name="$4"

  if [[ "$EAGER_MERGE" == "append" ]]; then
    # Claude Code: append to CLAUDE.md
    local target="$workdir/$EAGER_LOCATION"
    mkdir -p "$(dirname "$target")"
    echo "$content" >> "$target"
  else
    # kiro-cli: create file, reference added to agent resources
    local filepath="$workdir/context-files/$filename"
    mkdir -p "$(dirname "$filepath")"
    echo "$content" > "$filepath"
  fi
}

# Deploy agent based on adapter format
deploy_agent() {
  local workdir="$1"
  local def_file="$2"
  local agent_name="$3"

  local agent_path="$workdir/$(echo "$AGENT_LOCATION" | sed "s/{name}/$agent_name/")"
  mkdir -p "$(dirname "$agent_path")"

  local tools=$(yq -o=json ".fixtures.agents[\"$agent_name\"].tools" "$def_file")
  local resources=$(yq -o=json ".fixtures.agents[\"$agent_name\"].resources // []" "$def_file")
  local skills=$(yq -o=json ".fixtures.agents[\"$agent_name\"].skills // []" "$def_file")
  local prompt=$(yq ".fixtures.agents[\"$agent_name\"].prompt" "$def_file")
  local eager_ctx=$(yq ".fixtures.agents[\"$agent_name\"].eager_context // []" "$def_file")

  if [[ "$AGENT_FORMAT" == "json" ]]; then
    # kiro-cli: JSON agent with file:// resources for eager files
    local full_resources="$resources"
    # Add eager file references
    for ef in $(yq -r ".fixtures.eager_files | keys | .[]" "$def_file" 2>/dev/null); do
      full_resources=$(echo "$full_resources" | yq -o=json ". + [\"file://context-files/$ef\"]")
    done
    # Add skill references
    for sk in $(yq -r ".fixtures.skills | keys | .[]" "$def_file" 2>/dev/null); do
      local sk_path=$(echo "$SKILL_LOCATION" | sed "s/{name}/$sk/")
      full_resources=$(echo "$full_resources" | yq -o=json ". + [\"skill://$sk_path\"]")
    done

    cat > "$agent_path" << EOF
{
  "name": "$agent_name",
  "description": "Proof test agent",
  "tools": $tools,
  "allowedTools": $tools,
  "resources": $full_resources,
  "prompt": "$prompt"
}
EOF
  elif [[ "$AGENT_FORMAT" == "markdown-frontmatter" ]]; then
    # Claude Code: markdown agent with skills field
    local skills_list=""
    for sk in $(yq -r ".fixtures.skills | keys | .[]" "$def_file" 2>/dev/null); do
      skills_list="${skills_list}  - $sk\n"
    done

    local tools_str=$(echo "$tools" | yq -r '.[]' | paste -sd', ' -)

    cat > "$agent_path" << EOF
---
name: $agent_name
description: Proof test agent
tools: $tools_str
$(if [[ -n "$skills_list" ]]; then echo -e "skills:\n$skills_list"; fi)---

$prompt
EOF
  fi
}

# Deploy skill based on adapter
deploy_skill() {
  local workdir="$1"
  local skill_name="$2"
  local skill_content="$3"

  local skill_path="$workdir/$(echo "$SKILL_LOCATION" | sed "s/{name}/$skill_name/")"
  mkdir -p "$(dirname "$skill_path")"
  echo "$skill_content" > "$skill_path"
}

run_proof() {
  local def_file="$1"
  local id=$(yq '.id' "$def_file")
  local query=$(yq '.query' "$def_file")
  local timeout=$(yq ".timeout // $DEFAULT_TIMEOUT" "$def_file")

  # Create isolated workspace
  local workdir=$(mktemp -d -t "proof-${id}-XXXX")
  trap "rm -rf $workdir" RETURN

  # Deploy eager files
  local eager_count=$(yq '.fixtures.eager_files | length // 0' "$def_file")
  if [[ $eager_count -gt 0 ]]; then
    for ef in $(yq -r '.fixtures.eager_files | keys | .[]' "$def_file"); do
      local content=$(yq ".fixtures.eager_files[\"$ef\"]" "$def_file")
      deploy_eager_file "$workdir" "$ef" "$content" ""
    done
  fi

  # Legacy: deploy files (backward compat with old format)
  local file_count=$(yq '.fixtures.files | length // 0' "$def_file")
  if [[ $file_count -gt 0 ]]; then
    for f in $(yq -r '.fixtures.files | keys | .[]' "$def_file"); do
      local content=$(yq ".fixtures.files[\"$f\"]" "$def_file")
      mkdir -p "$workdir/$(dirname "$f")"
      echo "$content" > "$workdir/$f"
    done
  fi

  # Deploy skills
  local skill_count=$(yq '.fixtures.skills | length // 0' "$def_file")
  if [[ $skill_count -gt 0 ]]; then
    for sk in $(yq -r '.fixtures.skills | keys | .[]' "$def_file"); do
      local content=$(yq ".fixtures.skills[\"$sk\"]" "$def_file")
      deploy_skill "$workdir" "$sk" "$content"
    done
  fi

  # Deploy agents
  local agent_name=""
  local agent_count=$(yq '.fixtures.agents | length // 0' "$def_file")
  if [[ $agent_count -gt 0 ]]; then
    for an in $(yq -r '.fixtures.agents | keys | .[]' "$def_file"); do
      agent_name="$an"
      deploy_agent "$workdir" "$def_file" "$an"
    done
  fi

  # Invoke
  local cmd
  if [[ -n "$agent_name" ]]; then
    if [[ -z "$INVOKE_CMD" || "$INVOKE_CMD" == "null" ]]; then
      echo "  SKIP: adapter '$TOOL_NAME' has no invoke.command (agent invocation unsupported)" >&2
      return 2
    fi
    cmd=$(echo "$INVOKE_CMD" | sed "s/{agent}/$agent_name/" | sed "s|{query}|$query|")
  else
    if [[ -z "$INVOKE_NO_AGENT_CMD" || "$INVOKE_NO_AGENT_CMD" == "null" ]]; then
      echo "  SKIP: adapter '$TOOL_NAME' has no invoke.command_no_agent (agentless invocation unsupported)" >&2
      return 2
    fi
    cmd=$(echo "$INVOKE_NO_AGENT_CMD" | sed "s|{query}|$query|")
  fi

  local output=""
  local tmpfile=$(mktemp)

  # Retry once on empty output
  for attempt in 1 2; do
    cd "$workdir"
    timeout "$timeout" bash -c "$cmd" > "$tmpfile" 2>&1 || true
    output=$(cat "$tmpfile" | strip_ansi)
    if [[ -n "$(echo "$output" | tr -d '[:space:]')" ]]; then
      break
    fi
    [[ $attempt -eq 1 ]] && sleep 1
  done
  rm -f "$tmpfile"

  # Grade
  local status="PASS"
  local reason=""

  for val in $(yq -r '.expect.present[]' "$def_file" 2>/dev/null); do
    if ! echo "$output" | grep -qi "$val"; then
      status="FAIL"
      reason="Expected '$val' not found"
      break
    fi
  done

  if [[ "$status" == "PASS" ]]; then
    for val in $(yq -r '.expect.absent[]' "$def_file" 2>/dev/null); do
      if echo "$output" | grep -qi "$val"; then
        status="FAIL"
        reason="Unexpected '$val' found"
        break
      fi
    done
  fi

  # Log inspection (structural validation via session logs)
  if [[ "$status" == "PASS" ]]; then
    local log_check_count=$(yq '.log_checks | length // 0' "$def_file")
    if [[ $log_check_count -gt 0 ]]; then
      local inspect_args="--adapter $ADAPTER"
      for lc in $(yq -r '.log_checks[]' "$def_file" 2>/dev/null); do
        inspect_args="$inspect_args --check $lc"
      done
      local inspect_result
      inspect_result=$("$SCRIPT_DIR/inspect-session.sh" $inspect_args 2>&1) || true
      if echo "$inspect_result" | grep -q "FAIL:"; then
        status="FAIL"
        reason="Log check: $(echo "$inspect_result" | grep "FAIL:" | head -1)"
      elif echo "$inspect_result" | grep -q "SKIP:"; then
        echo "    ⚠️  log inspection skipped (no session log found)"
      fi
    fi
  fi

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
