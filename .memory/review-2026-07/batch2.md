# Skill Review — Batch 2 (build quality)

Reviewed: feedback-loop-debugging, troubleshooting-protocol, code-review, testing-guide, script-authoring, architecture-deepening, diagrams
Date: 2026-07-16

## Verdict Table

| skill | verdict | line count | issues found | recommended fix |
|-------|---------|-----------:|--------------|-----------------|
| feedback-loop-debugging | KEEP | 80 (SKILL) + 50 (references/tighten.md) | (6) Trigger-space overlap with troubleshooting-protocol: both activate on debugging/errors ("Use when debugging, diagnosing failures, tests failing" vs "Use when encountering errors, investigating failures") and prescribe different Phase 1s — FLD demands "a running, failing command before you touch source code"; TP demands "Read the actual error... Form ONE hypothesis". An agent hitting both gets conflicting protocols. Otherwise clean: frontmatter complete, tighten.md is pointed to ("read `references/tighten.md`"), no orphans, no stale refs. | Differentiate descriptions: keep FLD as the primary debugging skill; scope TP's description to non-reproducible/systemic investigation, or merge TP into FLD (see next row). |
| troubleshooting-protocol | MERGE | 43 (SKILL) + 42 (references/five-whys.md) | (6) Substantial conceptual duplication with feedback-loop-debugging: TP's "NO FIXES WITHOUT ROOT CAUSE INVESTIGATION" / "Apply single fix (not multiple changes)" / "Verify ALL tests pass" ≈ FLD's gate + "One change at a time" + Phase 3 Verify. TP's escalation policy ("Same approach fails 2x → STOP") also duplicates the system-prompt failure-loop rule. (7) five-whys.md "When to Switch" routes to "cause-mapping", "decision-matrix", and "pre-mortem" — none exist as skills in atomics/skills/ (verified via ls). If these are meant as skill hand-offs they dangle; if generic technique names, they should be labeled as such. (2) Description is generic — "Systematic debugging methodology" has no distinctive keywords not already claimed by FLD. Frontmatter complete; five-whys.md is pointed to. | Merge into feedback-loop-debugging: fold the escalation policy + Red Flags into FLD's Anti-Patterns, move five-whys.md to FLD's references/ (it complements "fix didn't stick" cases). If keeping separate, rewrite description to non-overlapping triggers (e.g., "recurring failures, root cause analysis, five whys, incident postmortem") and fix the three dangling technique routes in five-whys.md. |
| code-review | KEEP | 92 (SKILL) + 38 (smells.md) + 17 (checklist.md) | (5) Both references pointed to from body ("see [references/smells.md]", "see [references/checklist.md]") — no orphans. (7) References `.memory/grill/` and `.memory/specs/` — verified `.memory/grill` is a live convention used by grill-with-docs; not stale. Minor: step 3 hard-wires subagent dispatch ("Dispatch review subagent(s)"), which per tool-limitations steering doesn't apply on agy/crush — a portability caveat, not a defect. Frontmatter complete, purpose clear. | None required. Optional: add a one-line fallback "if subagents unavailable, run both axes sequentially in main context." |
| testing-guide | KEEP | 86 | Clean. Purpose clear, frontmatter complete (type: reference), no references/ dir so no orphan question, no stale refs. (6) Mild overlap: "Before fixing a bug (prove it exists, then prove it's fixed)" restates FLD's core loop, and determinism rules ("no timing, no randomness") echo tighten.md — acceptable, different audience (test authoring vs debugging). | None. |
| script-authoring | FIX | 121 — over the 100-line limit, no justification recorded | (4) 21 lines over budget. The overage is entirely the "Cross-Platform (bash on Windows)" section + "mise.toml pattern" (~35 lines) — progressive-loading material, not core principles. No references/ dir exists to absorb it. Everything else clean: frontmatter complete, distinctive description, no stale refs. | Move the Cross-Platform section and mise.toml pattern to `references/cross-platform.md` and link from body ("For Windows/macOS portability rules, see..."). Brings SKILL.md to ~85 lines. |
| architecture-deepening | FIX | 96 (SKILL) + 44 (vocabulary.md) + 48 (design-vocabulary.md) | (5)+(6) Duplicate reference files: `references/vocabulary.md` and `references/design-vocabulary.md` define the SAME seven terms (module, interface, depth, seam, adapter, leverage, locality) plus the same deletion test and adapter count rule. SKILL.md has TWO "## Vocabulary" sections — the first says "Full definitions in [references/vocabulary.md]", the second (18 lines later) says "see [references/design-vocabulary.md]". Both files are technically pointed to, but this is a copy-paste merge artifact: one section + one file should exist. The duplicated body section also wastes ~8 lines. Cross-link to `../diagrams/SKILL.md` is valid. Frontmatter complete, strong trigger keywords. | Delete the second "## Vocabulary" section from SKILL.md; merge design-vocabulary.md's extras (the _Avoid_ lines and deep/shallow ASCII diagram) into vocabulary.md; delete design-vocabulary.md. SKILL.md drops to ~88 lines. |
| diagrams | KEEP | 99 | (4) At the limit but under. Frontmatter complete though field order is unconventional (metadata block before name/description — parses fine, just inconsistent with siblings). Distinctive triggers, clear purpose, no references/ dir, no stale refs. Cross-referenced FROM architecture-deepening (valid inbound link). | None required. Optional: reorder frontmatter to name/description/metadata for consistency. |

## Per-Skill Detail

### 1. feedback-loop-debugging
- **Purpose (one sentence):** Force construction of a fast, failing reproduction command before any fix attempt, then iterate red→green one change at a time.
- **Triggers:** Yes — "debug, failing test, broken, not working, TypeError, error output, diagnose". Distinctive.
- **Frontmatter:** Complete (name, description, metadata.type: protocol, invocation: both, practice: null).

### 2. troubleshooting-protocol
- **Purpose (one sentence):** Enforce investigate→hypothesize→fix discipline with an escalation policy so agents never patch without root cause.
- **Triggers:** Weak — "errors, investigating failures" collides with feedback-loop-debugging's trigger space.
- **Frontmatter:** Complete.
- **Stale:** five-whys.md routes to cause-mapping / decision-matrix / pre-mortem, none of which exist as skills.

### 3. code-review
- **Purpose (one sentence):** Run a two-axis (standards + spec) review via isolated subagents, ending with a mandatory single-verdict line.
- **Triggers:** Adequate — "reviewing code, PRs, implementations".
- **Frontmatter:** Complete.

### 4. testing-guide
- **Purpose (one sentence):** Reference for what to test, how to structure and name tests, and which anti-patterns to avoid.
- **Triggers:** Adequate — "writing tests, reviewing test quality, deciding what to test".
- **Frontmatter:** Complete.

### 5. script-authoring
- **Purpose (one sentence):** Standards for writing idempotent, resumable, loud-failing, self-documenting shell scripts.
- **Triggers:** Good — "bash scripts, automation tools, CLI utilities".
- **Frontmatter:** Complete.

### 6. architecture-deepening
- **Purpose (one sentence):** Surface shallow modules and propose refactors that concentrate complexity behind small interfaces, using a precise shared vocabulary.
- **Triggers:** Strong — quoted trigger list ("shallow modules", "deepen", "architectural friction").
- **Frontmatter:** Complete.

### 7. diagrams
- **Purpose (one sentence):** Choose the right diagram abstraction (C4 level) and format (ASCII/Mermaid/D2/HTML report) and produce it correctly.
- **Triggers:** Strong — long quoted trigger list.
- **Frontmatter:** Complete (unconventional field order).

## Summary

- KEEP: 4 (feedback-loop-debugging, code-review, testing-guide, diagrams)
- FIX: 2 (script-authoring — over line budget; architecture-deepening — duplicate vocabulary file + duplicate body section)
- MERGE: 1 (troubleshooting-protocol → feedback-loop-debugging, or re-scope its triggers)
- RETIRE: 0
