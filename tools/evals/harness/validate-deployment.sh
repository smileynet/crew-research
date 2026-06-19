#!/bin/bash
# tools/evals/harness/validate-deployment.sh — End-to-end deployment validation
# Tests: global deploy → project scaffold → @init-project → prompts/skills work
# Usage: ./validate-deployment.sh [--tier basic|full]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
TIER="${1:-basic}"
[[ "${1:-}" == "--tier" ]] && TIER="${2:-basic}"
MOCK_PROJECT=$(mktemp -d -t "validate-XXXX")
TIMEOUT=60
PASS=0
FAIL=0

cleanup() { rm -rf "$MOCK_PROJECT"; }
trap cleanup EXIT

pass() { echo "  ✅ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ❌ $1"; FAIL=$((FAIL + 1)); }

echo "Deployment Validation (tier: $TIER)"
echo "Mock project: $MOCK_PROJECT"
echo ""

# ─── Step 1: Global deploy ───────────────────────────────────────
echo "Step 1: Global deploy"
rm -rf ~/.kiro/steering ~/.kiro/skills ~/.kiro/prompts
"$ROOT_DIR/tools/generator/init.sh" --global --tier "$TIER" > /dev/null 2>&1

[[ -d ~/.kiro/steering ]] && pass "steering/ created" || fail "steering/ missing"
[[ -d ~/.kiro/skills ]] && pass "skills/ created" || fail "skills/ missing"
[[ ! -d ~/.kiro/prompts ]] && pass "prompts/ not created (skills-only)" || fail "prompts/ exists (should not)"

# Check no {{params}} remain
if grep -r '{{params' ~/.kiro/skills/ 2>/dev/null | grep -q .; then
  fail "unresolved {{params}} in deployed files"
else
  pass "all params resolved"
fi

# ─── Step 2: Project scaffold ────────────────────────────────────
echo ""
echo "Step 2: Project scaffold"
echo '{"name":"validate-app","scripts":{"build":"echo ok","test":"echo ok","lint":"echo ok"}}' > "$MOCK_PROJECT/package.json"
cd "$MOCK_PROJECT" && git init -q && git add -A && git commit -q -m "init"
"$ROOT_DIR/tools/generator/init.sh" --project "$MOCK_PROJECT" > /dev/null 2>&1

[[ -f "$MOCK_PROJECT/AGENTS.md" ]] && pass "AGENTS.md created" || fail "AGENTS.md missing"
[[ -f "$MOCK_PROJECT/.memory/CONTEXT.md" ]] && pass ".memory/CONTEXT.md created" || fail ".memory/CONTEXT.md missing"
[[ -d "$MOCK_PROJECT/.scratch" ]] && pass ".scratch/ created" || fail ".scratch/ missing"
[[ ! -d "$MOCK_PROJECT/.kiro/skills" ]] && pass "no local .kiro/skills (correct)" || fail ".kiro/skills exists (should be global only)"
[[ ! -d "$MOCK_PROJECT/.kiro/prompts" ]] && pass "no local .kiro/prompts (correct)" || fail ".kiro/prompts exists (should be global only)"

# ─── Step 3: @init-project in unscaffolded project ───────────────
echo ""
echo "Step 3: @init-project in fresh project"
FRESH=$(mktemp -d -t "fresh-XXXX")
echo '{"name":"fresh"}' > "$FRESH/package.json"
cd "$FRESH" && git init -q && git add -A && git commit -q -m "init"

output=$(timeout "$TIMEOUT" kiro-cli chat --no-interactive --trust-all-tools "@init-project" 2>/dev/null | sed 's/\x1B\[[0-9;]*[a-zA-Z]//g')
if echo "$output" | grep -qi "scaffold\|memory\|CONTEXT\|workspace\|AGENTS"; then
  pass "@init-project recognized and executed"
else
  fail "@init-project not recognized"
fi
rm -rf "$FRESH"

# ─── Step 4: @handoff works from scaffolded project ──────────────
echo ""
echo "Step 4: @handoff from scaffolded project"
cd "$MOCK_PROJECT"
timeout "$TIMEOUT" kiro-cli chat --no-interactive --trust-all-tools "@handoff" > /dev/null 2>&1

if [[ -f "$MOCK_PROJECT/.scratch/HANDOFF.md" ]] || [[ -f "$MOCK_PROJECT/.scratch/handoff.md" ]]; then
  pass "@handoff created handoff file"
else
  fail "@handoff did not create handoff file"
fi

# ─── Step 5: Skill activation ────────────────────────────────────
echo ""
echo "Step 5: Skill activation (planning-cycles)"
cd "$MOCK_PROJECT"
output=$(timeout "$TIMEOUT" kiro-cli chat --no-interactive --trust-all-tools "I need to plan a new feature for user authentication. Help me break this down." 2>/dev/null | sed 's/\x1B\[[0-9;]*[a-zA-Z]//g')
if echo "$output" | grep -qi "phase\|brainstorm\|scope\|plan"; then
  pass "planning-cycles skill activated"
else
  fail "planning-cycles skill did not activate"
fi

# ─── Step 6: Steering enforcement ────────────────────────────────
echo ""
echo "Step 6: Steering (research-dispatch)"
cd "$MOCK_PROJECT"
output=$(timeout "$TIMEOUT" kiro-cli chat --no-interactive --trust-all-tools "Research these two topics: 1) JWT vs session tokens 2) bcrypt vs argon2. Write findings to .scratch/research/" 2>/dev/null | sed 's/\x1B\[[0-9;]*[a-zA-Z]//g')
if echo "$output" | grep -qi "subagent\|parallel\|dispatch"; then
  pass "research-dispatch steering followed"
else
  fail "research-dispatch steering not followed"
fi

# ─── Summary ─────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════"
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && echo "✅ All checks passed" || echo "❌ $FAIL checks failed"
exit $FAIL
