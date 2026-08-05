---
id: "84"
title: "Evaluate deterministic prose linter (ste-lint.py pattern)"
status: open
blocked_by: ["87"]
spec: "eval-harness"
---

# Evaluate deterministic prose linter (ste-lint.py pattern)

## What to build

Evaluate whether a deterministic prose linter (Python, no deps) should be added to `tools/lint/`. The linter would catch the mechanical subset of prose hygiene rules — em dashes, sentence length, passive voice markers, filler phrases.

## Context

- Reference implementation: `.references/woosal-blog/videos/ep01-the-cure-for-ai-slop/ste-lint.py`
- Measures violations per 100 words (deterministic, no LLM needed)
- Could gate eval outputs, run in `mise run validate`, or be a standalone check
- Follows enforcement-hierarchy: Level 2 (automated validation) for mechanical rules

## Acceptance criteria

- [ ] Spike: run ste-lint.py against 3-5 sample skill/doc files to calibrate noise
- [ ] Decision: adopt as-is, adapt, or reject (with rationale)
- [ ] If adopt: tool at `tools/lint/prose-lint.py` with usage in eval README
- [ ] If reject: document why in ticket Resolution

## Research / Spikes

- Does the linter produce false positives on technical docs (code examples, CLI output)?
- What's the right threshold for crew-research content vs general prose?
- Should it run on skill SKILL.md files, docs/, or both?

## Out of scope

- LLM-based prose judging (that's what the eval harness does)
- Rewriting ste-lint.py from scratch (adapt or reject)
