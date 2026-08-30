#!/bin/bash
# tools/generator/known-tools.sh — Orchestrate known external tools (recall, tkt)
#
# Reads the `orchestration:` block per tool from compositions/known-tools.yaml
# and drives three discrete, cross-platform (Windows/macOS/Linux/WSL) actions:
#
#   deploy     Build + install each tool's binary and refresh its skills.
#              OS-selected build leg (recall: .ps1 on Windows / .sh elsewhere;
#              tkt: cargo install). State-changing.
#   doctor     Aggregate each tool's own runtime health/audit CLI. Read-only.
#   telemetry  Surface each tool's usage/debug telemetry. Read-only.
#
# Usage: ./known-tools.sh <deploy|doctor|telemetry> [tool]
#   tool  Optional — restrict to one tool (e.g. recall). Default: all.
#
# Ownership: crew-research NEVER reimplements a tool's logic — every leg shells
# out to the tool's own script/CLI (command strings live in the registry).
#
# Repo resolution probe order (per tool, first hit wins):
#   $CREW_TOOLS_ROOT/<name>  →  literal repo: value  →  ~/code/<name>
#   →  (WSL) /mnt/c/Users/$WIN_USER/code/<name>
# A tool whose repo/binary isn't found is SKIPPED with a notice (○), never a
# hard failure — matching doctor.sh's "absence is pending-with-reason" rule.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
KNOWN_TOOLS_FILE="$ROOT_DIR/compositions/known-tools.yaml"

ACTION="${1:-}"
ONLY_TOOL="${2:-}"

case "$ACTION" in
  deploy|doctor|telemetry) ;;
  *)
    echo "Usage: $0 <deploy|doctor|telemetry> [tool]" >&2
    exit 2
    ;;
esac

if [[ ! -f "$KNOWN_TOOLS_FILE" ]]; then
  echo "Error: registry not found: $KNOWN_TOOLS_FILE" >&2
  exit 2
fi
if ! command -v yq &>/dev/null; then
  echo "Error: yq required (install: see tool-installation skill)" >&2
  exit 2
fi

# --- OS detection (house style: uname -s case) ---
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) OS=windows ;;   # Git Bash / MSYS2 on Windows-proper
  *)                    OS=unix ;;       # macOS, Linux, WSL (uname=Linux)
esac

# WSL detection (shared with doctor.sh) — under WSL, Windows-side tools read from
# and run against the Windows user home; command execution may need interop.
IS_WSL=false
if [[ -n "${WSL_DISTRO_NAME:-}" || -f /proc/sys/fs/binfmt_misc/WSLInterop ]]; then
  IS_WSL=true
fi

# Resolve the Windows username for WSL /mnt/c path probing.
WIN_USER="${WIN_USERNAME:-}"
if $IS_WSL && [[ -z "$WIN_USER" ]]; then
  WIN_USER=$(cmd.exe /C "echo %USERNAME%" 2>/dev/null | tr -d '\r\n') || true
  [[ -z "$WIN_USER" ]] && WIN_USER="$USER"
fi

errors=0
warnings=0

# --- Run a CLI command with WSL/MSYS interop fallback (mirrors doctor.sh) ---
# Windows-native tools (recall on WSL, uv-installed tools on MSYS) aren't always
# reachable directly. Cascade: direct → cmd.exe → powershell.exe.
run_tool_cmd() {
  local cmd="$1"
  local out
  if out=$(eval "$cmd" 2>/dev/null) && [[ -n "$out" ]]; then
    printf '%s\n' "$out"; return 0
  fi
  if $IS_WSL; then
    if out=$(cmd.exe /C "$cmd" 2>/dev/null | tr -d '\r') && [[ -n "$out" ]]; then
      printf '%s\n' "$out"; return 0
    fi
    if command -v powershell.exe &>/dev/null; then
      if out=$(powershell.exe -NoProfile -NonInteractive -Command "$cmd" 2>/dev/null | tr -d '\r') && [[ -n "$out" ]]; then
        printf '%s\n' "$out"; return 0
      fi
    fi
  elif [[ "$OS" == "windows" ]] && command -v powershell.exe &>/dev/null; then
    if out=$(MSYS_NO_PATHCONV=1 powershell.exe -NoProfile -NonInteractive -Command "$cmd" 2>/dev/null | tr -d '\r') && [[ -n "$out" ]]; then
      printf '%s\n' "$out"; return 0
    fi
  fi
  return 1
}

# --- Resolve a tool's repo dir (probe order documented in header) ---
resolve_repo() {
  local name="$1" literal="$2" cand
  for cand in \
    "${CREW_TOOLS_ROOT:+$CREW_TOOLS_ROOT/$name}" \
    "${literal/#\~/$HOME}" \
    "$HOME/code/$name" \
    "${WIN_USER:+/mnt/c/Users/$WIN_USER/code/$name}"
  do
    [[ -n "$cand" && -d "$cand" ]] && { printf '%s\n' "$cand"; return 0; }
  done
  return 1
}

# --- yq helpers ---
kt() { yq -r "$1" "$KNOWN_TOOLS_FILE" 2>/dev/null; }

echo "Known tools — $ACTION"
echo ""

kt_count=$(kt '.tools | length' || echo 0)
ran_any=false

for ((i=0; i<kt_count; i++)); do
  name=$(kt ".tools[$i].name")
  # orchestration block is optional (archwright has none)
  has_orch=$(kt ".tools[$i].orchestration // \"\" | (. != \"\")")
  [[ "$has_orch" != "true" ]] && continue
  [[ -n "$ONLY_TOOL" && "$name" != "$ONLY_TOOL" ]] && continue

  ran_any=true
  echo "$name:"

  case "$ACTION" in

    doctor)
      # Read-only: run each doctor/audit command, report per-line.
      dc=$(kt ".tools[$i].orchestration.doctor | length" || echo 0)
      if ! command -v "$name" &>/dev/null && ! $IS_WSL && [[ "$OS" != "windows" ]]; then
        echo "  ○  $name not on PATH — skipped"
        echo ""; continue
      fi
      for ((j=0; j<dc; j++)); do
        cmd=$(kt ".tools[$i].orchestration.doctor[$j]")
        if out=$(run_tool_cmd "$cmd"); then
          # Summarize: prefer jq for JSON scalar fields, but jq may be Windows-side
          # and unreachable from WSL — degrade to a normalized one-line preview.
          summary=""
          if command -v jq &>/dev/null && printf '%s' "$out" | jq empty 2>/dev/null; then
            summary=$(printf '%s' "$out" | jq -r '
              if type=="object"
              then [to_entries[] | select(.value|type|(.=="number" or .=="string" or .=="boolean")) | "\(.key)=\(.value)"] | join(" ")
              else tostring end' 2>/dev/null | tr '\n' ' ')
          fi
          if [[ -z "$summary" ]]; then
            # No jq (or not JSON): first meaningful line, or compacted JSON preview
            summary=$(printf '%s\n' "$out" | tr -d '\r' | grep -v '^[[:space:]]*$' \
              | sed 's/^[[:space:]]*//' | grep -v '^[{}]$' | head -1)
          fi
          echo "  ✅ $cmd → $(printf '%s' "${summary:-ok}" | head -c 180)"
        else
          echo "  ⚠️  $cmd → no output / failed"
          warnings=$((warnings + 1))
        fi
      done
      ;;

    telemetry)
      # Read-only: status + stats/show. Never enable/disable/clear.
      tc=$(kt ".tools[$i].orchestration.telemetry | length" || echo 0)
      if ! command -v "$name" &>/dev/null && ! $IS_WSL && [[ "$OS" != "windows" ]]; then
        echo "  ○  $name not on PATH — skipped"
        echo ""; continue
      fi
      for ((j=0; j<tc; j++)); do
        cmd=$(kt ".tools[$i].orchestration.telemetry[$j]")
        if out=$(run_tool_cmd "$cmd"); then
          echo "  ✅ $cmd"
          printf '%s\n' "$out" | grep -v '^[[:space:]]*$' | sed 's/^/       /' | head -12
        else
          echo "  ⚠️  $cmd → no output / failed"
          warnings=$((warnings + 1))
        fi
      done
      ;;

    deploy)
      # State-changing: resolve repo, run OS-selected build leg then skills leg.
      literal=$(kt ".tools[$i].repo")
      repo=$(resolve_repo "$name" "$literal") || {
        echo "  ○  repo not found (probed \$CREW_TOOLS_ROOT, $literal, ~/code/$name) — skipped"
        echo ""; continue
      }
      echo "  repo: $repo"

      # Build leg: may be OS-keyed (windows/unix) or a plain string.
      build_win=$(kt ".tools[$i].orchestration.deploy.build.windows // .tools[$i].orchestration.deploy.build // \"\"")
      build_unix=$(kt ".tools[$i].orchestration.deploy.build.unix // .tools[$i].orchestration.deploy.build // \"\"")
      if [[ "$OS" == "windows" ]]; then build_cmd="$build_win"; else build_cmd="$build_unix"; fi

      if [[ -n "$build_cmd" && "$build_cmd" != "null" ]]; then
        # pwsh availability check for Windows .ps1 legs
        if [[ "$build_cmd" == pwsh* ]] && ! command -v pwsh &>/dev/null; then
          if command -v powershell &>/dev/null; then
            build_cmd="powershell${build_cmd#pwsh}"
          else
            echo "  ⚠️  build: neither pwsh nor powershell found — run manually: (cd $repo && $build_cmd)"
            warnings=$((warnings + 1)); build_cmd=""
          fi
        fi
        if [[ "$build_cmd" == cargo* ]] && ! command -v cargo &>/dev/null; then
          echo "  ⚠️  build: cargo not found — skipping build, run manually in $repo"
          warnings=$((warnings + 1)); build_cmd=""
        fi
        if [[ -n "$build_cmd" ]]; then
          echo "  → build: $build_cmd"
          if ( cd "$repo" && eval "$build_cmd" ); then
            echo "  ✅ build ok"
          else
            echo "  ❌ build failed: $build_cmd"
            errors=$((errors + 1))
          fi
        fi
      fi

      # Skills leg: null = tool doesn't self-deploy a skill (recall's is crew's fallback).
      skills_cmd=$(kt ".tools[$i].orchestration.deploy.skills // \"\"")
      if [[ -n "$skills_cmd" && "$skills_cmd" != "null" ]]; then
        echo "  → skills: $skills_cmd"
        if ( cd "$repo" && eval "$skills_cmd" ) >/dev/null 2>&1; then
          echo "  ✅ skills deployed"
        else
          echo "  ⚠️  skills deploy returned non-zero: $skills_cmd"
          warnings=$((warnings + 1))
        fi
      else
        echo "  ○  skills: none (self-deploy N/A — skill is crew fallback)"
      fi

      # Verify installed version
      if ver=$(run_tool_cmd "$name --version"); then
        echo "  ✅ installed: $(printf '%s\n' "$ver" | head -1)"
      fi
      ;;
  esac

  echo ""
done

if ! $ran_any; then
  if [[ -n "$ONLY_TOOL" ]]; then
    echo "  ○  '$ONLY_TOOL' has no orchestration block in the registry"
  else
    echo "  ○  no tools with an orchestration block"
  fi
fi

echo "---"
echo "Errors: $errors | Warnings: $warnings"
[[ $errors -eq 0 ]] && echo "✅ Done" || echo "❌ Fix errors above"
exit $errors
