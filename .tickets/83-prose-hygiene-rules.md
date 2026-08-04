---
id: "83"
title: "Add prose hygiene rules to writing-style (STE-inspired)"
status: open
blocked_by: []
spec: "ticket-cli-spec"
---

# Add prose hygiene rules to writing-style (STE-inspired)

## What to build

Add prose-specific banned patterns to `writing-style` skill, complementing the code-focused `ai-generation-hygiene`. Based on ASD-STE100 findings (woosal/blog ep01: 50-74% slop reduction measured).

## Context

- Source: `.references/woosal-blog/videos/ep01-the-cure-for-ai-slop/ste-writing-skill.md`
- Analysis: `.scratch/research/woosal-before-after-analysis.md`
- Gap: Our ai-generation-hygiene covers CODE patterns only (P1-P9). Zero prose coverage.
- writing-style has subjective self-checks but no mechanical banned patterns.

## Acceptance criteria

- [ ] writing-style SKILL.md or references/ has explicit prose banned patterns (em dashes, marketing adjectives, filler phrases, sentence length cap)
- [ ] Top 4 rules are concrete and lintable (not subjective)
- [ ] Stays under 100 lines (use references/ for the full pattern list)
- [ ] No regression on writing-style activation eval

## Out of scope

- Building a linter tool (ticket 84)
- Multi-mode support (ticket 85)
- Full ASD-STE100 vocabulary lockdown (too restrictive for general use)

## What to build

TBD

## Acceptance criteria

- [ ] TBD
