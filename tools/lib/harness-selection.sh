#!/usr/bin/env bash
# tools/lib/harness-selection.sh — the ONE shared reader for "does tool <name>
# participate on this machine?" (ticket 144, ADR 0011). Sourced by every harness
# (eval, judge, dispatch-review, proof) so the CREW_ENV floor + enable-map live in
# exactly one place instead of being re-implemented per script.
#
# Usage (source, don't exec):
#   source "$REPO_ROOT/tools/lib/harness-selection.sh"
#   verdict=$(tool_verdict agy)        # → enabled | policy-blocked | disabled | unavailable
#   reason=$(tool_reason agy)          # → canonical human reason string ("" when enabled)
#   if tool_enabled agy; then ... ; fi # → exit 0 iff verdict == enabled
#
# Precedence (deny-wins, staged): floor(1) → enable-map(2) → availability(3).
# Callable BEFORE `command -v` — the policy-vs-access distinction is preserved because
# the floor and enable-map are checked before availability.
#
# Env:
#   CREW_ENV            corp | personal | unset (the policy floor axis, ticket 36)
#   HARNESS_TOOLS_YAML  override the enable-map path (default: compositions/harness-tools.yaml)

# Resolve repo root relative to this file if the caller didn't set REPO_ROOT.
if [[ -z "${_HS_LIB_DIR:-}" ]]; then
  _HS_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
: "${REPO_ROOT:=$(cd "$_HS_LIB_DIR/../.." && pwd)}"
: "${HARNESS_TOOLS_YAML:=$REPO_ROOT/compositions/harness-tools.yaml}"

# Canonical reason string for the CREW_ENV policy floor (ticket 36). Kept here so all
# consumers emit byte-identical text — doctor.sh drifted from this before consolidation.
hs_policy_reason() { echo "policy-blocked (CREW_ENV=corp)"; }

# Is a tool forbidden by the Stage-1 CREW_ENV floor? Extensible: today only agy on corp.
# opencode / claude-code / codex / crush / kiro-cli are unrestricted in all environments.
hs_policy_blocked() {
  local tool="$1"
  [[ "${CREW_ENV:-}" == "corp" && "$tool" == "agy" ]]
}

# True CREW_ENV unset (for init.sh's "proceeding with a notice" path).
hs_env_unset() { [[ -z "${CREW_ENV:-}" ]]; }

# Map an adapter/tool NAME to its PATH binary. Most match 1:1; claude-code's binary is
# `claude`. Extend here if another tool's adapter name diverges from its executable.
hs_binary() {
  case "$1" in
    claude-code) echo "claude" ;;
    *)           echo "$1" ;;
  esac
}

# Stage-2 enable-map lookup. Default-OFF: a tool absent from the map, or enabled:false,
# is `disabled`. Requires yq; if yq or the file is missing we FAIL CLOSED to disabled
# (never silently treat an unreadable map as all-enabled).
hs_map_enabled() {
  local tool="$1" val
  command -v yq &>/dev/null || return 1
  [[ -f "$HARNESS_TOOLS_YAML" ]] || return 1
  val=$(yq -r ".tools.\"$tool\".enabled // false" "$HARNESS_TOOLS_YAML" 2>/dev/null)
  [[ "$val" == "true" ]]
}

# Structured verdict for a tool. Stages are strictly ordered (deny-wins): a floor block
# short-circuits before the map; a disable short-circuits before availability.
#   enabled | policy-blocked | disabled | unavailable
tool_verdict() {
  local tool="$1"
  if hs_policy_blocked "$tool"; then echo "policy-blocked"; return; fi
  if ! hs_map_enabled "$tool"; then echo "disabled"; return; fi
  if ! command -v "$(hs_binary "$tool")" &>/dev/null; then echo "unavailable"; return; fi
  echo "enabled"
}

# Canonical reason string for a verdict ("" when enabled).
tool_reason() {
  local tool="$1"
  case "$(tool_verdict "$tool")" in
    enabled)        echo "" ;;
    policy-blocked) hs_policy_reason ;;
    disabled)       echo "disabled (harness-tools.yaml)" ;;
    unavailable)    echo "unavailable (not on PATH)" ;;
  esac
}

# Boolean convenience: exit 0 iff the tool is fully enabled (all three stages pass).
tool_enabled() { [[ "$(tool_verdict "$1")" == "enabled" ]]; }
