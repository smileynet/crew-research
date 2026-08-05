---
id: "86"
title: "Explore: explicit slop word substitution table for writing-style"
status: open
blocked_by: ["88"]
spec: "eval-harness"
---

# Explore: explicit slop word substitution table

## What to build

Evaluate whether an explicit "say X not Y" substitution table for common LLM slop words would improve writing quality. The table would live in `writing-style/references/` and be consulted during prose generation.

## Context

- STE-100 uses a controlled vocabulary dictionary (approved words only)
- Woosal experiment showed banned-words lists are unreliable (3-40% inconsistent across models)
- But substitution tables (X→Y mappings) are more reliable than bans (gives the model an alternative)
- Common LLM slop: leverage→use, utilize→use, facilitate→help, streamline→simplify, robust→strong, cutting-edge→new

## Acceptance criteria

- [ ] Compile initial substitution table (10-20 entries) from observed LLM slop patterns
- [ ] Test: does providing the table reduce slop word usage vs just banning them?
- [ ] Decision: integrate into writing-style references, add to ai-generation-hygiene, or reject
- [ ] If adopt: document when to apply (always? only in strict mode?)

## Research / Spikes

- Do substitution tables work better than ban lists? (STE data says yes for structure, unclear for vocabulary)
- What's the minimal table size that produces measurable improvement?
- Should the table be mode-dependent (strict: enforced, flavored: suggested)?

## Out of scope

- Full STE-100 dictionary adaptation (thousands of entries — too restrictive)
- Linter enforcement (ticket 84 covers that)
