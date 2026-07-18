---
id: "19"
title: "recall skill activates on memory questions"
status: open
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

- [ ] Root cause identified with evidence (per-hypothesis test results)
- [ ] Fix applied: skill description/body rework, OR def retired with rationale + steering-side measurement plan
- [ ] If skill reworked: `activation-recall` TPR ≥ 3/5, FPR ≤ 1/5 on a fresh run
