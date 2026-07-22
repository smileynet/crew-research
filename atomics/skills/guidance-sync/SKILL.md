---
name: guidance-sync
description: "Probe the current session for self-improvement opportunities — corrections, friction, gotchas, and repetition that should become updates to project-local skills, AGENTS.md, steering, or tool-script guides. Invoke manually (/guidance-sync) periodically during a session or before wrapping up. Trigger: guidance sync, self improvement, what should we update, capture learnings, sync guidance, improvement opportunities, session retro."
metadata:
  type: protocol
  invocation: user-only
  practice: null
---

# Guidance Sync — In-Session Self-Improvement Probe

Mine THIS session for signals that the project's guidance layer should change. Source material is the live conversation — not git history, not session archives (the automated retrospective variant is future work; `session-analysis` owns historical data).

## Probes (run all, report findings per probe)

### P1 — Corrections
Where did the user correct me this session? Each correction is a candidate rule:
- Corrected assumption → steering or AGENTS.md line
- Corrected workflow → skill edit (the skill taught the wrong shape)
- Corrected scope/intent → skill description or trigger vocabulary fix

### P2 — Friction
Where did work stall or need archaeology this session?
- Stale docs hit in practice (wrong flag syntax, dead path, missing step)
- Knowledge that existed only in someone's head or a previous session
- A check or verification that had to be improvised

### P3 — New knowledge
What did this session learn that the next session shouldn't rediscover?
- Gotchas with incidents behind them → guide skill "hard rules" section
- Output-interpretation rules (what a field/verdict actually means)
- Environment facts (access limits, version quirks) → environment notes

### P4 — Repetition
What did I do manually 2+ times this session? Candidates for:
- A tools/ script (follow the validation contract)
- A skill workflow step
- An AGENTS.md command entry

### P5 — Coverage gate
Does every `tools/` script family touched this session have a guide skill covering usage and output interpretation? A family needs one if output requires interpretation, flags are misusable, or misuse has cost. Otherwise an AGENTS.md command entry suffices — don't create ceremony.

### P6 — Prune
What existing guidance did this session ignore, contradict, or work around? Curation is the point: uncurated guidance measurably degrades agents, and net line count only going up means accumulating, not curating.
- A rule I violated to do the job correctly → the rule is wrong; edit or remove it now
- A correction happened DESPITE a covering rule → the prose failed; promote to mechanical enforcement (lint, hook, validation) instead of adding more prose
- Guidance contradicted by observed reality → fix in place now (repair-on-touch — don't defer to a scheduled review that won't happen)
- Two files own the same rule → consolidate to one source of truth, delete the copy

Route removals to their owners — never build a parallel prune mechanism: skill retirement → `compositions/deprecated.yaml` flow; AGENTS.md over budget → agents-md-authoring trim gate; systemic multi-file drift → propose `/project-audit`; doc decay → docs-audit.

## Output Format

```
## Self-Improvement Probe — {date}

| # | Probe | Finding | Proposed change | Target |
|---|-------|---------|-----------------|--------|
| 1 | P1 correction | ... | ... | .kiro/skills/X or AGENTS.md |
| 2 | P3 gotcha | ... | ... | guide skill hard-rules |

Apply now: [items needing no decision]
Needs your call: [items with trade-offs]
Not worth capturing: [signals judged noise, with one-line why]
Net guidance delta: +A / −R lines across applied changes
```

Apply approved items in the same session. Trivial corrections (stale syntax, dead link) apply directly; note them.

## Discipline

- Proposals must trace to a specific moment in this session — no generic "docs could be better"
- Entry filter: capture only what will plausibly change a future outcome — if the model already does it unprompted, or reading the code reveals it, it's noise
- Supersede, don't obliterate: decision records get marked superseded, never deleted; removals go through owned mechanisms; git history + recall are the archive (no quarantine lists — manual status flags rot without a sweep)
- One source of truth: command lines in AGENTS.md, interpretation in guide skills, incidents in hard-rules sections
- Capture into the right layer: glossary terms → `.memory/CONTEXT.md`; decisions → recall/ADR; behavior rules → steering/skills
- Skill budget: <100 lines per SKILL.md; split to `references/` if over
