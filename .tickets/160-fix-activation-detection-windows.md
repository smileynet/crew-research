---
id: "160"
title: "Fix check-activation.sh detection on Windows/Git Bash (DB path + behavioral markers)"
status: done
blocked_by: []
priority: high
---

# Fix check-activation.sh detection on Windows/Git Bash

## Intent source

Discovered running ticket 154 (2026-09-17). The activation harness scored code-review
TP=0/FN=5 (TPR=0) on a controlled run even though the agent behaviorally DID code-review.
Full diagnosis: `docs/development/fpr-negative-clause-experiment-154.md`. High priority
because it caps EVERY behavioral-skill activation eval on Windows — not just 154.

## Problem

`tools/evals/harness/check-activation.sh` cannot detect activation for behavioral skills on
Windows/Git Bash. All three strategies fail:

1. **Strategy 1 (output grep)** looks for the literal `skills/<name>/SKILL.md` load-line in
   captured stdout — kiro-cli does NOT emit that line in `--no-interactive -a` mode on this
   env. Confirmed: agent ran `git status`/`git log` and gave a two-axis review response, but
   `grep -c "skills/code-review/SKILL.md" → 0`.
2. **Strategy 2 (session DB)** reads `$HOME/.local/share/kiro-cli/data.sqlite3` (Linux path).
   Under Git Bash the DB is actually at `$LOCALAPPDATA/kiro-cli/data.sqlite3` (Windows path) —
   the Linux path is MISSING, so the strategy is skipped. **Path mismatch.**
3. **Strategy 3 (artifacts)** only has cases for `handoff` and `init-project`.

Net: for any skill that activates *behaviorally* (no artifact, no load-line) the harness
reports "not activated" → TP=0 → every activation eval is unreliable on this platform.

## What to build

1. **Fix Strategy 2 DB path resolution cross-platform** (highest value — it reads the real
   conversation store):
   ```bash
   if [[ -n "${LOCALAPPDATA:-}" && -f "$(cygpath -u "$LOCALAPPDATA")/kiro-cli/data.sqlite3" ]]; then
     DB="$(cygpath -u "$LOCALAPPDATA")/kiro-cli/data.sqlite3"       # Windows/Git Bash
   elif [[ -f "$HOME/.local/share/kiro-cli/data.sqlite3" ]]; then
     DB="$HOME/.local/share/kiro-cli/data.sqlite3"                  # Linux
   elif [[ -f "$HOME/Library/Application Support/kiro-cli/data.sqlite3" ]]; then
     DB="$HOME/Library/Application Support/kiro-cli/data.sqlite3"   # macOS
   fi
   ```
   (Confirm the actual per-OS locations against kiro-cli docs before hardcoding.)
2. **Verify Strategy 2 actually matches** the skill in the conversation JSON (the current grep
   for the H1 marker is fragile — test it against a known-activated run).
3. **Optionally** add a couple more behavioral-marker cases to Strategy 1 for common skills, or
   document that Strategy 2 is the primary path once the DB resolves.
4. **Re-validate**: run `--definition activation-code-review` and confirm the 5 positive tasks
   now score TP (not FN) when the agent behaves correctly.

## Acceptance criteria

- [x] Strategy 2 resolves the kiro-cli DB on Windows/Git Bash (`$LOCALAPPDATA`), Linux (`$HOME/.local/share`), and macOS (`$HOME/Library/Application Support`) + matches the workspace key in both unix and Windows path forms. NOTE: verified headless `--no-interactive` does NOT persist to `conversations_v2`, so Strategy 2 is a fallback only — the real fix is Strategy 1 behavioral markers.
- [x] A controlled code-review positive task scores TP after the fix (targeted test: 2 positives → ACTIVATED, 2 adjacent decoys → not_activated)
- [x] `activation-code-review` yields a non-zero TPR on this environment → **TPR = 0.80** (full run TP=4 FP=2 TN=8 FN=1; was TPR=0 before the fix). Marker then tightened to drop the 2 adjacent-decoy FPs (verified fixed in targeted re-test).
- [x] No regression on Linux/macOS: the generic `skills/<name>/SKILL.md` load-line grep is retained as a fallback after the behavioral markers; behavioral markers are additive (fire on behavior, not the load-line)
- [x] `mise run validate` passes (+ `bash -n` clean on check-activation.sh)

## Out of scope

- The FPR negative-clause experiment itself (ticket 154 — unblocked by this)
- Rewriting the whole harness (targeted detection fix only)

## References

- Diagnosis: `docs/development/fpr-negative-clause-experiment-154.md`
- Detector: `tools/evals/harness/check-activation.sh`
- Runner: `tools/evals/harness/run-activation.sh`
- Blocks: ticket 154
- Related: "steering shadow / detection artifact" glossary note; ticket 24 (Strategy 1 wiring)

## Resolution (2026-09-18)

Root cause: kiro-cli headless --no-interactive emits NO skill-activation signal (verified: output has no load-line, conversations_v2 not written for headless runs, no log files). Fix: added behavioral-marker detection to check-activation.sh Strategy 1 for code-review + testing-guide/planning-cycles/data-modeling/research-methodology/docs-audit (each marker = behavior the skill uniquely makes the agent do/say); made Strategy 2 DB path cross-platform (LOCALAPPDATA/Linux/macOS) with unix+Windows key matching (fallback only, since headless does not persist). Result: activation-code-review TPR went 0 to 0.80 (full run TP=4 FP=2 TN=8 FN=1); marker then tightened to drop generic review-verbs that echoed adjacent-decoy prompts -> targeted re-test shows 2 positives ACTIVATED, 2 former-FP decoys not_activated. bash -n clean, validate passes. Unblocks 154. Commit eda47ec.
