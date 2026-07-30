#!/usr/bin/env bash
# identity.sh — component identity hashes for eval result rows (ticket 33).
# Sourced by run.sh (row emission) and check-staleness.sh (recompute+diff) —
# ONE hashing implementation so the two sides can never drift apart.
#
# Contract:
#   - All paths are hashed RELATIVE to the crew-research repo root so hashes
#     are machine-independent (required by ticket 32's cross-machine interchange).
#   - skill_hash: every skill dir + steering file referenced by ANY condition
#     of the def, sorted, content-concatenated with relative-path headers.
#   - def_hash: the def yaml + def-level fixture + every per-task fixture.
#   - env_id: NOT a hash — a readable composed string
#     "{adapter}:{tool_version}:{model|tool-default}:judges={sorted-judge-set}"
#     so drift KIND stays diagnosable from the string itself.
#   - Missing paths contribute a "MISSING:{relpath}" line instead of failing:
#     a deleted skill file must CHANGE the hash, not crash the run.
#
# Known limit (documented, not solved): model identity is the observable id +
# tool version only — server-side silent model updates behind the same id are
# invisible to env_id.

IDENTITY_HASH_VERSION="v1-sha256-12"

# _identity_repo_root: crew-research root (identity.sh lives at tools/evals/harness/)
_identity_repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd
}

# identity_hash_paths <relpath>... : sha256 (12-char prefix) over the sorted
# file contents of the given repo-root-relative paths (dirs recurse).
identity_hash_paths() {
  local root; root=$(_identity_repo_root)
  (
    cd "$root" || exit 1
    local p f
    { for p in "$@"; do
        [[ -z "$p" ]] && continue
        if [[ -d "$p" ]]; then
          find "$p" -type f | sort
        elif [[ -f "$p" ]]; then
          echo "$p"
        else
          echo "MISSING:$p"
        fi
      done
    } | sort | while read -r f; do
      if [[ "$f" == MISSING:* ]]; then
        echo "$f"
      else
        echo "FILE:$f"
        cat "$f"
      fi
    done | sha256sum | cut -c1-12
  )
}

# identity_skill_hash <def_file> : hash of all skills + steering across all conditions
identity_skill_hash() {
  local def_file="$1"
  local paths=() slug st
  # skills across every condition (new format), or top-level skill (legacy)
  while read -r slug; do
    [[ -z "$slug" || "$slug" == "null" ]] && continue
    paths+=("atomics/skills/$slug")
  done < <(yq '.conditions // {} | to_entries | .[].value.skills // [] | .[]' "$def_file" 2>/dev/null; \
           yq '.skill // ""' "$def_file" 2>/dev/null)
  # steering files across every condition (resolved under tools/evals/steering/)
  while read -r st; do
    [[ -z "$st" || "$st" == "null" ]] && continue
    paths+=("tools/evals/steering/$st")
  done < <(yq '.conditions // {} | to_entries | .[].value.steering // [] | .[]' "$def_file" 2>/dev/null)
  if [[ ${#paths[@]} -eq 0 ]]; then
    echo "no-skill"
    return 0
  fi
  # dedupe + stable order
  identity_hash_paths $(printf '%s\n' "${paths[@]}" | sort -u)
}

# identity_def_hash <def_file> : hash of the def yaml + all referenced fixtures
identity_def_hash() {
  local def_file="$1"
  local root; root=$(_identity_repo_root)
  local rel_def="${def_file#"$root"/}"
  local paths=("$rel_def") fx
  while read -r fx; do
    [[ -z "$fx" || "$fx" == "null" ]] && continue
    paths+=("tools/evals/fixtures/$fx.yaml")
  done < <(yq '.fixture // ""' "$def_file" 2>/dev/null; \
           yq '.tasks // [] | .[].fixture // ""' "$def_file" 2>/dev/null)
  identity_hash_paths $(printf '%s\n' "${paths[@]}" | sort -u)
}

# identity_env_id <adapter> <tool_version> <model> <judge...> : composed string
identity_env_id() {
  local adapter="$1" tool_version="$2" model="$3"; shift 3
  local judges="none"
  if [[ $# -gt 0 ]]; then
    judges=$(printf '%s\n' "$@" | sort | paste -sd+ -)
  fi
  echo "${adapter}:${tool_version}:${model:-tool-default}:judges=${judges}"
}

# identity_judge_hash : sha256 (12-char prefix) over the judge template file.
# The template is the fixed structural prompt — variable content (criteria, output)
# is covered by def_hash. Edits to this file register as JUDGE-DRIFT.
identity_judge_hash() {
  identity_hash_paths "tools/evals/harness/judge-template.txt"
}
