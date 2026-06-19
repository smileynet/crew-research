---
name: project-audit
description: "Drift analysis — check if deployed skills, steering, and AGENTS.md still match project reality. Use periodically or after major refactors."
metadata:
  type: process
  invocation: user-only
  practice: null
---

# Project Audit

Check whether the crew-research deployment still matches project reality.

## Checks

### 1. Verification Commands
- Read `.kiro/steering/verification-protocol.md`
- Run each command (build, test, lint) — do they succeed?
- Compare against `package.json` scripts / `Makefile` / `Cargo.toml`
- If mismatched: update steering file with correct commands

### 2. AGENTS.md Accuracy
- Do listed commands still work?
- Do referenced paths (`.memory/`, `.scratch/`, `.kiro/`) exist?
- Are listed workflows still available as skills?
- Is the project layout description current?

### 3. Steering Freshness
- Do `.kiro/steering/` files reference paths/tools that exist?
- Is any steering content outdated or contradicted by current practice?

### 4. Skill Relevance
- List deployed skills — are any clearly irrelevant to this project?
- Are there recurring tasks where a skill would help but none exists?

### 5. CONTEXT.md Currency
- Are all terms still accurate?
- Any terms used in recent work but not yet defined?
- Any stale definitions that should be removed?

### 6. AGENTS.md Commands
- Do build/test/lint commands still work?
- Are any new commands missing?

### 7. References Directory
- Is `.references/` used consistently (not `resources/` or bare `references/`)?
- If `resources/` or `references/` exists and is gitignored → flag for rename to `.references/`
- Is `.references/` in `.gitignore`?
- Are reference repos documented in AGENTS.md?

### 8. Unprocessed Decisions
- Check for `decisions.md`, `DECISIONS.md`, `docs/decisions.md`
- If found: flag for processing into `.memory/adr/` (ADR-worthy) or `.memory/CONTEXT.md` (terms)
- Check `.memory/decisions.md` — should entries be promoted to ADRs?

## Output

```
## Audit Results
- Verification: ✅/❌ (commands work?)
- AGENTS.md: ✅/❌ (accurate?)
- Steering: ✅/❌ (references valid?)
- Skills: N deployed, N relevant, N gaps
- CONTEXT.md: N terms, N stale, N missing
- Config: ✅/❌ (matches reality?)
- References: ✅/❌ (consistent naming, gitignored?)
- Decisions: ✅/❌ (all processed?)

## Actions Taken
- [fixes applied]

## Recommended
- [remaining items needing user decision]
```
