---
id: "19"
title: "recall skill activates on memory questions"
status: done
blocked_by: []
spec: "t09-baseline-followups"
---

# recall skill activates on memory questions

## What to build

The recall skill activates when the user asks about past decisions or prior sessions. Currently TPR 0/5 — the only live activation failure in the t09 baseline.

## Context

- **Evidence:** `activation-recall` TPR 0/5, FPR 0/5 in t09 baseline (`results/activation-2026-07-17T22-18-29Z`) AND in the 2026-07-18 verify run (`results/activation-2026-07-18T13-30-42Z`)
- **Ruled out:** YAML folded-scalar description formatting — flattened to single-line quoted scalar (commit pending), re-ran, still 0/5. Description content has trigger phrases matching the task phrasings ("what did we decide", "last session", "remind me") and STILL doesn't activate.
- **Hypotheses to test:**
  1. The agent prefers answering memory questions via file reads / its own context over loading a skill — task inputs reference project specifics ("coordinate system for play data") that look file-answerable
  2. kiro-cli's matcher ranks the recall skill low for question-form inputs (other passing defs use imperative-form tasks)
  3. The always-on `recall-check` steering (deployed in real environments) already owns this trigger space — in the eval workdir without that steering, nothing routes memory questions to the skill; in production with it, the skill is redundant
- **If hypothesis 3 holds:** the right fix may be retiring the activation def (steering owns the behavior, measured by field compliance instead — currently 21%, see t09 recommendations item 1) rather than fighting the matcher
- **Related:** t09 rec #1 (recall-check steering gate strengthening) — same problem space, decide together

## Acceptance criteria

- [x] Root cause identified with evidence (per-hypothesis test results)
- [x] Fix applied: skill description/body rework, OR def retired with rationale + steering-side measurement plan
- [x] If skill reworked: `activation-recall` TPR ≥ 3/5, FPR ≤ 1/5 on a fresh run (N/A — def retired, not reworked)

## Resolution (2026-07-18)

**Root cause: hypothesis 3 confirmed with a causal pair.** Eval workdirs inherit the global `~/.kiro/steering/` — including `recall-check.md`, deployed always-on by the same extension that ships the recall skill. The steering owns the trigger space, so the matcher (correctly) never loads the redundant skill.

**Evidence:**
- Probe WITH steering (eval + production reality): agent ran `recall search` twice and suggested `recall add` — desired behavior — but skill content never entered the conversation (0 hits for its H1 in the session DB). This is exactly what the eval scores as FN ×5.
- Identical probe WITHOUT steering (temporarily hidden): skill loaded (H1 in conversation: 1 hit) and agent ran recall search. TPR would pass in an environment that never exists in production.
- Both environments produce the correct behavior; the def measures a mechanism that is structurally shadowed wherever the extension is actually deployed.

**Hypotheses 1–2 rejected:** the agent doesn't prefer file reads (it ran recall CLI in both probes), and question-form inputs match fine when the steering isn't present.

**Fix: def retired** to `definitions/retired/activation-recall.yaml` with rationale in the file header (excluded from `--all` runs by the existing retired/ filter).

**Steering-side measurement plan:** the behavior is owned by `recall-check` steering; measure field compliance via `mise run session:skills` (session-skill-usage reports). Baseline 21% (`session-skill-usage-2026-07-17.md`). Strengthening the steering gate is t09 baseline rec #1 — tracked there, decided together with this per ticket context, implemented separately.

**Incidental finding (no action):** activation detection Strategy 1 (`.eval-output`) never fires — run-activation.sh discards agent output; all activation defs are actually detected via the session-DB marker (SKILL.md H1 grep). Worked as intended in both probes; noted for whoever next touches the harness.
