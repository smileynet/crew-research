---
id: "85"
title: "Explore: strict vs flavored writing modes (STE two-mode concept)"
status: open
blocked_by: ["88"]
spec: "eval-harness"
---

# Explore: strict vs flavored writing modes

## What to build

Investigate whether writing-style should support two modes: **strict** (procedures, error messages, changelogs — full STE rules) and **flavored** (general prose — structural rules without vocabulary lockdown).

## Context

- STE skill uses strict/flavored distinction: strict for mechanical docs, flavored for creative prose
- Our writing-style currently has one mode applied everywhere
- Risk: strict mode on READMEs/blog posts would be too clinical
- Opportunity: strict mode on error messages/CLI help would eliminate slop where precision matters most

## Acceptance criteria

- [ ] Document which content types benefit from strict vs flavored
- [ ] Propose how mode selection would work (explicit parameter? auto-detect from context?)
- [ ] Evaluate: does mode-switching add enough value to justify the complexity?
- [ ] Decision: implement modes, keep single-mode, or defer

## Research / Spikes

- What content does crew-research produce that would benefit from strict mode? (error messages, CLI help, changelog entries, commit messages)
- How do other controlled-language systems handle mode switching?

## Out of scope

- Full ASD-STE100 vocabulary lockdown (too domain-specific)
- Building the implementation (this is exploration only)
