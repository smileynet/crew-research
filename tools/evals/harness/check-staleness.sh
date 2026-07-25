#!/usr/bin/env bash
# check-staleness.sh <results-dir> [--brief] — which eval results still reflect
# the current tree? (ticket 33)
#
# Recomputes each row's identity hashes against the CURRENT repo state and
# reports drift KIND per def:
#   CURRENT     — all components match; the result describes today's tree
#   SKILL-DRIFT — skill/steering content changed since the row was scored
#   DEF-DRIFT   — def yaml or a fixture changed (history non-comparable)
#   ENV-DRIFT   — tool version changed for the row's adapter (judge-set and
#                 model differences are visible in the env_id string but only
#                 the version segment is recomputed — judges can't be probed
#                 cheaply, and model is a user parameter, not environment)
#   SKIPPED     — row was a SKIP (never executed; informational)
#   UNHASHED    — row predates ticket 33 (null hashes; informational)
#
# Output: JSON per the validation contract (status/findings), --brief for humans.
# Exit: 0 = all executed rows current, 1 = drift found, 2 = crash/bad input.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/identity.sh"

RESULTS_DIR=""
BRIEF=false
for arg in "$@"; do
  case "$arg" in
    --brief) BRIEF=true ;;
    *) RESULTS_DIR="$arg" ;;
  esac
done
[[ -n "$RESULTS_DIR" && -f "$RESULTS_DIR/scores.jsonl" ]] || { echo "usage: check-staleness.sh <results-dir> [--brief] (needs scores.jsonl)" >&2; exit 2; }

EVALS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DEFINITIONS_DIR="$EVALS_DIR/definitions"
ADAPTERS_DIR="$(cd "$EVALS_DIR/../proofs" && pwd)/adapters"

json_field() { sed -n "s/.*\"$2\":\"\([^\"]*\)\".*/\1/p" <<< "$1"; }

# current tool version per adapter, cached
declare -A ADAPTER_VERSION=()
adapter_version() {
  local adapter="$1"
  if [[ -z "${ADAPTER_VERSION[$adapter]:-}" ]]; then
    local vc af="$ADAPTERS_DIR/$adapter.yaml" v="unknown"
    if [[ -f "$af" ]]; then
      vc=$(yq '.version_command' "$af")
      v=$($vc 2>/dev/null | head -1 || echo "unknown")
    fi
    ADAPTER_VERSION[$adapter]="${v:-unknown}"
  fi
  echo "${ADAPTER_VERSION[$adapter]}"
}

current=0 drifted=0 skipped=0 unhashed=0
findings=""

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  name=$(json_field "$line" "name")
  status=$(json_field "$line" "status")
  row_skill=$(json_field "$line" "skill_hash")
  row_def=$(json_field "$line" "def_hash")
  row_env=$(json_field "$line" "env_id")

  if [[ "$status" == "SKIP" ]]; then
    skipped=$((skipped + 1)); continue
  fi
  if [[ -z "$row_skill" || -z "$row_def" ]]; then
    unhashed=$((unhashed + 1))
    findings="$findings{\"name\":\"$name\",\"kinds\":[\"UNHASHED\"],\"detail\":\"row predates identity hashes (pre-ticket-33)\"},"
    continue
  fi

  def_file="$DEFINITIONS_DIR/$name.yaml"
  retired_note=""
  if [[ ! -f "$def_file" ]]; then
    def_file="$DEFINITIONS_DIR/retired/$name.yaml"
    retired_note=" (def is in retired/)"
  fi
  kinds=() detail=""
  if [[ ! -f "$def_file" ]]; then
    kinds+=("DEF-DRIFT"); detail="def file not found under definitions/ or retired/"
  else
    cur_skill=$(identity_skill_hash "$def_file")
    cur_def=$(identity_def_hash "$def_file")
    [[ "$cur_skill" != "$row_skill" ]] && kinds+=("SKILL-DRIFT")
    [[ "$cur_def" != "$row_def" ]] && kinds+=("DEF-DRIFT")
    # env: recompute only the version segment (field 2) for the row's adapter
    adapter=$(json_field "$line" "adapter")
    row_version=$(cut -d: -f2 <<< "$row_env")
    cur_version=$(adapter_version "$adapter")
    [[ "$row_version" != "$cur_version" ]] && kinds+=("ENV-DRIFT")
    detail="skill ${row_skill}->${cur_skill}, def ${row_def}->${cur_def}, version ${row_version}->${cur_version}${retired_note}"
  fi

  if [[ ${#kinds[@]} -eq 0 ]]; then
    current=$((current + 1))
  else
    drifted=$((drifted + 1))
    kinds_json=$(printf '"%s",' "${kinds[@]}"); kinds_json="[${kinds_json%,}]"
    findings="$findings{\"name\":\"$name\",\"kinds\":$kinds_json,\"detail\":\"$detail\"},"
  fi
done < "$RESULTS_DIR/scores.jsonl"

status="pass"; [[ $drifted -gt 0 ]] && status="fail"
findings_json="[${findings%,}]"

if [[ "$BRIEF" == true ]]; then
  # one line per finding + terminal status line (mirrors tkt --brief)
  sed 's/},{/}\n{/g' <<< "${findings_json#[}" | sed 's/^\[//;s/\]$//' | while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    n=$(json_field "$f" "name"); k=$(sed -n 's/.*"kinds":\(\[[^]]*\]\).*/\1/p' <<< "$f")
    echo "$n $k"
  done
  echo "$status (current=$current drifted=$drifted skipped=$skipped unhashed=$unhashed)"
else
  echo "{\"status\":\"$status\",\"hash_version\":\"$IDENTITY_HASH_VERSION\",\"results_dir\":\"$RESULTS_DIR\",\"summary\":{\"current\":$current,\"drifted\":$drifted,\"skipped\":$skipped,\"unhashed\":$unhashed},\"findings\":$findings_json}"
fi

[[ "$status" == "pass" ]] && exit 0 || exit 1
