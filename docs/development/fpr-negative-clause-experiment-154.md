# FPR negative-clause experiment (ticket 154) — BLOCKED by activation detection on Windows/Git Bash

**Date:** 2026-09-17
**Ticket:** 154 (gates ticket 151's negative-clause tactic)
**Status:** Blocked — cannot produce a valid verdict on this environment. Not a null result; a measurement-instrument failure.

## Goal

Measure whether adding a keywords-first negative ("Not for … (see other-skill)") clause to a
broad-vocabulary skill's description lowers its false-positive activation rate (FPR) WITHOUT
lowering true-positive rate (TPR), using `tools/evals/harness/run-activation.sh`. Ticket 157
had expanded code-review + 5 others to 10 negatives (FPR quantum 0.10) to make a sub-gate
delta measurable.

## What happened

Baseline run on `activation-code-review` (positive-only description, 15 tasks):

```
Results: TP=0 FP=1 TN=9 FN=5 (total=15)
TPR (recall): 0    FPR: 0.10 (1/10)    Verdict: PASS (spuriously — TPR=0)
```

**TP=0 / FN=5 is the tell.** Every positive task scored as a false negative — the harness
believes code-review never activated on any of its 5 on-target prompts. That is not possible
behaviorally, so the detector is wrong.

## Root cause (confirmed by controlled repro)

Reproduced one positive task exactly as the harness does (temp workdir, skill copied to
`.kiro/skills/code-review/SKILL.md`, `kiro-cli chat --no-interactive -a --wrap never "<query>"`).
The agent **behaviorally performed code review** — it asked for the PR, ran
`git status && git branch -a && git log`, inspected the directory, and explained exactly what
it needed to proceed. That IS the skill activating.

But `tools/evals/harness/check-activation.sh` scored it "not activated" because **all three
detection strategies fail on this Windows/Git Bash environment**:

| Strategy | Mechanism | Why it fails here |
|----------|-----------|-------------------|
| 1. Output grep | greps captured output for the literal `skills/code-review/SKILL.md` load-line | kiro-cli does **not emit a skill-load log line** to stdout in `--no-interactive -a` mode on this env. Confirmed: `grep -c "skills/code-review/SKILL.md" → 0` despite correct behavior. |
| 2. Session DB | greps `$HOME/.local/share/kiro-cli/data.sqlite3` (Linux path) | Under Git Bash the DB is at `$LOCALAPPDATA/kiro-cli/data.sqlite3` (Windows path). The Linux path is **MISSING** → strategy skipped. Path mismatch. |
| 3. Artifacts | checks for skill-produced files | Only wired for `handoff` (HANDOFF.md) and `init-project` (CONTEXT.md). No case for code-review. |

The lone `FP=1` ("Review all new work since the last review marker…", an adjacent-skill decoy
for review-new-work) is almost certainly a spurious detection artifact, not a real signal —
with the detector reading ~0 activation across the board, single counts are noise.

## Why this blocks 154

The experiment compares FPR between two description variants. If the detector reports ~0
activation **regardless of the description** (because it can't see activation at all for a
behavioral skill on this env), then baseline and treatment both collapse to noise and the
delta is uninterpretable. Running the full baseline-vs-treatment matrix (code-review +
docs-audit × 2 variants ≈ 60 live model invocations, ~30–45 min, real token spend) would
produce an uninterpretable result. Stopped after the baseline to avoid the spend.

**No experimental description edits were made** (treatment phase not started), so there is
nothing to revert. The candidate defs from ticket 157 remain committed and correct.

## What would unblock it

1. **Fix `check-activation.sh` Strategy 2 path** to resolve the DB cross-platform
   (`${LOCALAPPDATA}/kiro-cli/data.sqlite3` on Windows/Git Bash, `$HOME/.local/share/…` on
   Linux/macOS). This is the most reliable detector (it reads the real conversation store).
2. **OR** a behavioral-marker detector for code-review in Strategy 1 (e.g. output contains a
   git-diff/review action or the two-axis Standards/Spec framing) — but behavioral markers are
   skill-specific and brittle.
3. **OR** run the eval on Linux/macOS or WSL where Strategy 1/2 paths hold (untested — verify
   kiro-cli emits the load-line there before assuming).
4. This is likely the same "steering shadow / detection artifact" limitation already noted in
   the glossary and observed on prior activation runs — worth a dedicated harness ticket since
   it caps ALL behavioral-skill activation evals on Windows, not just this experiment.

## Bearing on ticket 151

151 already ships the negative-clause tactic as **optional + unproven + eval-gated** — that
framing is CORRECT and unchanged. This blocker means the "promote to recommended" revisit
trigger cannot fire yet on this environment; 151's guidance stays as-is. No verdict for or
against negative clauses was produced (neither supports nor refutes — the instrument couldn't
measure it).
