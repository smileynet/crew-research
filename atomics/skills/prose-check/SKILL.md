---
name: prose-check
description: "Dispatch a fresh subagent to review written content against prose hygiene and writing style criteria. Use after writing docs, READMEs, changelogs, or any user-facing prose. Trigger: check the writing, review prose, prose check, is this well written, slop check, review for AI writing, quality check the docs."
metadata:
  type: process
  invocation: both
  practice: null
---

# Prose Check

Dispatch a subagent to review prose with fresh context. The working session is biased — it wrote the text and won't see its own patterns.

## When to Run

- After writing or rewriting a README, changelog, or docs
- After generating any user-facing prose longer than a paragraph
- Before presenting docs to the user for review
- When something reads "off" but you can't pinpoint why

## Process

### 1. Identify the target

What file(s) need review? Collect the paths.

### 2. Dispatch a review subagent

The subagent reads the file(s) and checks against these criteria:

> Read {file path}. Review the prose for quality. Check:
>
> **Vocabulary:** Any kill-on-sight words? (delve, utilize, leverage, facilitate, robust, comprehensive, seamless, innovative, cutting-edge, landscape, realm, tapestry, myriad)
>
> **Filler:** Any zero-information phrases? ("It's worth noting", "Let's dive into", "Furthermore", "In today's world", "When it comes to")
>
> **Structure:** Uniform sentence length? "Not just X but Y" constructions? Recap conclusion that restates the intro? Symmetric sections (always 3 or 5 items)? Em dash overload (>1 per paragraph)?
>
> **Imperatives:** "You should..." instead of bare imperatives? "It's important to..." wrapping simple statements? "Make sure to..." before instructions?
>
> **Hyperbole:** Unmeasured claims? ("powerful", "game-changing", "revolutionary") Replace with what it actually does or a measurement.
>
> **Voice:** Relentlessly positive (no tradeoffs mentioned)? Uniform enthusiasm? Every paragraph same structure?
>
> Report: findings table (line/section, issue, fix), overall verdict (CLEAN / MINOR ISSUES / REWRITE NEEDED), and proposed rewrites for any flagged passages.

### 3. Apply fixes

Review subagent findings. Apply fixes directly for clear issues (vocabulary swaps, filler deletion). Propose rewrites for structural issues that need judgment.

### 4. Verify

Re-read the fixed text. Does it pass the writing-style self-check?
1. First sentence delivers value?
2. Any sentence cuttable without loss?
3. Kill-on-sight words gone?
4. Sentence lengths varied?

## When NOT to Dispatch

- Content < 5 lines (just review it yourself inline)
- Code comments and commit messages (too short to warrant dispatch)
- Content you didn't write (reviewing someone else's file — read it directly)

## Recommended After

- `/readme-writing` — check the generated README
- `/changelog-discipline` — check the changelog entries
- Major AGENTS.md rewrites
- Any docs/ file creation
