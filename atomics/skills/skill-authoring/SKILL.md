---
name: skill-authoring
description: "Write and improve agent-loadable skills. Use when creating a new skill, improving an existing skill's activation, restructuring a skill that's too broad, writing skill frontmatter, or diagnosing why a skill doesn't trigger. Trigger: new skill, write a skill, skill format, skill template, activation trigger, skill description, SKILL.md."
metadata:
  type: reference
  invocation: both
  practice: null
---

# Skill Authoring

## Format

```yaml
---
name: slug-name
description: "Trigger-rich description. Use when [situations]. Trigger: keyword1, keyword2."
metadata:
  type: protocol | reference | process | reasoning-mode | decision
  invocation: both | user-only | agent-only
  practice: slug-or-null
---
```

Body: Markdown. No hard line/token limit — the Agent Skills spec validates only frontmatter (name ≤64, description ≤1024) and naming; the spec's <500-line / <5000-token figure is a SOFT guardrail, not a gate. Size is a symptom: judge the body by effectiveness (below), not a line count.

## Rules

1. **One concern per skill** — if it covers two topics, STOP and split. Never combine.
2. **Description IS the trigger** — kiro-cli matches tasks against this field. Generic = never activates
3. **Process, not knowledge dump** — tell the agent what to DO, not everything to KNOW
4. **Effective structure over short length** — activation-critical steps up front; push detail (long tables, code templates, edge-case catalogs, incident logs) to `references/`. Length is fine if it's payload (copy-paste JSON, hard-won gotchas) that's well-ordered; length is a problem only when it BURIES the workflow. Don't split just to hit a number — splitting exact output conventions, numeric thresholds, or a linear pipeline can hurt (progressive-disclosure "fanout tax"; there's also a compression floor below which accuracy drops).
5. **Progressive loading** — SKILL.md is the entry point; link `references/*.md` for detail, ONE level deep (nested refs get partial-read via `head`; add a table of contents to any reference >100 lines so a partial read still surfaces scope).
6. **Non-redundant** — add only what the model doesn't already know, and don't duplicate a rule that lives in another skill/AGENTS.md/steering. One owner per rule; others link. Cross-skill duplication drifts and is a bigger effectiveness risk than length.
7. **Dispatched skills stay monolithic** — if a skill is invoked by a subagent told to "read this file," keep everything it needs INLINE. A partial-reading subagent can silently skip content moved to a reference.

## Creation Gates (mandatory for new skills)

Before presenting a new skill as complete, verify ALL gates pass:

| # | Gate | Fail action |
|---|------|-------------|
| G0 | Invocation model confirmed WITH the requester before authoring: who triggers it (user `/name`, agent description-match, or both) and when (during work, after work, periodically) | Ask — this determines `metadata.invocation`, trigger vocabulary, and workflow tense (incident: guidance-sync authored as post-work sync when the user wanted an in-session probe, 2026-07-19) |
| G1 | Description contains "Use when" + 3+ trigger keywords | Rewrite description |
| G2 | Body is steps/process (not a list of facts) | Restructure as imperative |
| G3 | Scope boundary declared ("Does NOT cover: ...") | Add scope section |
| G4 | Workflow is not buried: activation-critical steps are up front; reference-grade detail (long tables, templates, incident logs) is in `references/` OR is well-ordered payload that doesn't interrupt the steps | Reorder; extract the interrupting block to references/ (keep a one-line pointer) |
| G4b | No rule duplicated from another skill/AGENTS.md/steering (one owner + links) | Consolidate to one owner |
| G4c | If dispatched by a subagent, everything it needs is inline (not behind a reference hop) | Inline it |
| G5 | Single concern (would you split this into two skills?) | Split now |

If G0-G5 don't all pass, the skill is not done. Fix before presenting.

## Writing a Good Description

The description must contain:
- What it does (one clause)
- "Use when" clause with specific situations
- Trigger keywords (words users actually say)

Bad: `"Helps with code quality"` — matches everything, activates on nothing.

Good: `"Code review standards and checklist. Use when reviewing code, PRs, or implementations for correctness, security, and quality."` — clear situations, specific terms.

### Leading Words

Use compact pretrained concepts to anchor behavior in few tokens. "tight" recruits more behavior than "fast, deterministic, low-overhead, clear signal" — in 1 token instead of 8. For the full pattern, read [references/leading-words.md](references/leading-words.md).

## Anti-Patterns

| Problem | Symptom | Fix |
|---------|---------|-----|
| Too broad | Covers 5+ topics | Split into focused skills |
| Knowledge dump | Lists facts, no actions | Rewrite as steps/process |
| Generic trigger | Activates on everything or nothing | Add "Use when" + keywords |
| Workflow buried under reference detail | Reader can't find the steps; disclosure fails | Reorder; extract the interrupting block to references/ |
| Rule duplicated from another skill/AGENTS.md | Drifts out of sync; agents get conflicting guidance | One owner + link |
| No frontmatter | Won't be discovered | Add complete YAML header |

## Companion Files

Place in `references/` within the skill directory:
- Examples, lookup tables, extended patterns
- Loaded only when agent needs more depth
- Keep each companion file focused (one topic)

## Testing Activation

After writing, verify the skill would activate by checking:
- Does the description contain words a user would say when they need this?
- Is it distinct from other skills' descriptions? (no overlap)
- Would you find it by searching for the problem it solves?

## Critique Checklist

When reviewing an existing skill:
1. Single concern? (one thing done well)
2. Description has "Use when" + trigger keywords?
3. Body is process/steps, not reference material?
4. Workflow up front, detail in references/ (not buried); no duplication of another skill's rules?
5. Scope declared? (what it does NOT cover)

Does NOT cover: writing steering files (see enforcement-hierarchy), eval design (see eval-criteria), or AGENTS.md authoring (see agents-md-authoring).
