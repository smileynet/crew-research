# Skill Review — Batch 6 (recall, recall-check, recall-session-start, git-protocol, skill-authoring, eval-criteria)

Reviewed: 2026-07-16. All SKILL.md + references/ read in full. Line counts from `wc -l`.

## Verdict Table

| Skill | Verdict | Line Count | Issues | Recommended Fix |
|-------|---------|-----------|--------|-----------------|
| recall | FIX | 67 (SKILL.md) + 104 (references/cli-reference.md) | **Orphan reference**: `references/cli-reference.md` (104 lines — install, daily-ingest setup, full command table, storage) is never linked from SKILL.md body. Grep across `atomics/` confirms zero inbound links. Violates progressive-loading rule ("SKILL.md is the entry point; link references/*.md"). Minor: frontmatter lacks `metadata.practice` (other skills carry `practice: null`). | Add a References section to SKILL.md body, e.g. `For installation, ingest scheduling, and the full command table, read [references/cli-reference.md](references/cli-reference.md)`. Add `practice: null` to frontmatter. |
| recall-check | KEEP | 42 | Deployed as always-on steering (confirmed in `compositions/tiers/basic.yaml` + `full.yaml` under extension `steering:`), so the thin description ("When to search cross-session memory before answering.") is acceptable — steering isn't trigger-matched. Duplication with `recall` SKILL.md is by design (steering catches the moment; skill carries detail). One cosmetic inconsistency: its persist example is `recall add "We decided X because Y" --type decision` while recall SKILL.md uses `--room decisions --type decision`. Not a contradiction (room auto-classifies), but harmonizing avoids confusion. Missing `metadata.practice`. | Optional: align the `recall add` example with recall SKILL.md (add `--room decisions` or drop it in both). Add `practice: null`. |
| recall-session-start | KEEP | 19 | Deployed as steering (tier YAML). Tight, single-purpose. No contradictions with siblings (see recall-trio analysis below). Missing `metadata.practice`. | Add `practice: null` for consistency. Nothing else. |
| git-protocol | KEEP | 58 + refs (51, 50) | None found. Both references linked from body. Content consistent with global `project-conventions.md` steering (pre-push fetch gate, no amend-after-push, no `git add .`). | None. |
| skill-authoring | FIX | 95 + ref (48) | Fails its own gate G3: the skill mandates "Scope boundary declared ('Does NOT cover: ...')" and its Critique Checklist asks "Scope declared?", yet **skill-authoring itself has no scope section**. Quote of the self-imposed rule it violates: `G3 | Scope boundary declared ("Does NOT cover: ...") | Add scope section`. At 95 lines it's near the 100-line ceiling, so the fix must be terse. Reference `leading-words.md` properly linked. | Add a one-line scope boundary, e.g. `Does NOT cover: eval criteria (see eval-criteria), steering file authoring, tier composition.` Fits within the 100-line budget (95→~97). |
| eval-criteria | KEEP | 66 + ref (38) | Reference linked from body. Description triggers are adequate but lean — "Use when creating, reviewing, or modifying eval definitions" lacks a `Trigger:` keyword list (compare skill-authoring's style). Possible staleness watch item in `references/session-review.md`: the hardcoded subagent tool blacklist `grep, glob, code, web_search, web_fetch, use_aws, todo_list` is tool-version-specific and will silently rot as kiro-cli evolves. Not wrong today, but unverifiable from the repo. | Optional: append `Trigger: eval definition, criteria, judge, threshold, automatic fail.` to description. Add a "verify against current kiro-cli docs" note next to the subagent tool list. |

## Per-Skill Detail

### 1. recall (FIX)
1. **Purpose**: Protocol for using the `recall` CLI to search cross-session memory before answering about the past and to persist decisions/lessons as they happen.
2. **Triggers**: Yes — excellent. `"what did we decide", "last session", "previously", "recall", "remind me", "continue from where we left off"`.
3. **Frontmatter**: name ✅ description ✅ metadata.type (`protocol`) ✅ metadata.invocation (`both`) ✅. (`practice` absent — minor.)
4. **Lines**: 67 — under 100 ✅.
5. **References linked**: ❌ **`references/cli-reference.md` is orphaned.** No link anywhere in SKILL.md; grep over `atomics/` finds no inbound reference. The 104-line companion (installation incl. Windows Application Control workaround, daily ingest cron/launchd/schtasks, staleness check, full command table) is unreachable via progressive loading.
6. **Stale?**: No — cli-reference.md's `recall 0.1.0` matches `tools/recall/pyproject.toml` (`version = "0.1.0"`).

### 2. recall-check (KEEP)
1. **Purpose**: Always-on steering that tells the agent WHEN to run `recall search` before answering questions about past decisions (and when not to).
2. **Triggers**: Description is generic ("When to search cross-session memory before answering.") — but this deploys as steering, not a trigger-matched skill, so acceptable.
3. **Frontmatter**: name ✅ description ✅ type (`protocol`) ✅ invocation (`agent-only`) ✅.
4. **Lines**: 42 ✅.
5. **References**: none exist, none needed ✅.
7. **Stale?**: No. Matches the deployed copy at `~/.kiro/steering/recall-check.md` verbatim.

### 3. recall-session-start (KEEP)
1. **Purpose**: Always-on steering that runs a staleness check + `recall prime` at session start to load background memory.
2. **Triggers**: Description minimal but agent-only steering — acceptable.
3. **Frontmatter**: name ✅ description ✅ type (`protocol`) ✅ invocation (`agent-only`) ✅.
4. **Lines**: 19 ✅.
5. **References**: none exist ✅.
7. **Stale?**: No. `~/.recall/last_ingest` staleness mechanism is documented identically in recall's cli-reference.md ("After each ingest, recall writes `~/.recall/last_ingest`... The `recall-session-start` steering checks this").

### recall-trio duplication / contradiction analysis (item 6)
Design intent confirmed: `compositions/tiers/{basic,full}.yaml` deploy `recall-session-start` + `recall-check` as **steering** and `recall` as a **skill** under the recall extension.

- **Duplication (by design, acceptable)**: recall-check's trigger patterns and search command are a subset of recall SKILL.md's "When to use" + Search sections. This is the intended pattern — steering is the always-loaded tripwire; the skill carries the full protocol. No action needed.
- **No contradictions found.** Checked specifically:
  - Search command identical: `recall search "query" --results 5` in both.
  - Persist type identical: `--type decision` in both. Cosmetic drift only: recall SKILL.md adds `--room decisions`; recall-check omits it. Rooms auto-classify, so both are correct.
  - Unavailability behavior differs *intentionally by context*: recall SKILL.md fallback (answering about the past) says "Tell the user: 'I can't check past sessions right now'"; recall-session-start (session start) says "If `recall` is not available, skip silently." Different situations, coherent behavior — telling the user is right when they asked about history; silence is right at session start. Not a contradiction.
  - Prime handoff is coherent: recall SKILL.md says prime runs "if instructed by steering"; recall-session-start is that steering. Both say wing auto-detects and output should be internalized, not repeated.

### 4. git-protocol (KEEP)
1. **Purpose**: Solo-workflow git protocol — commit-timing invariants, conventional commit messages, and a mandatory fetch-before-push gate.
2. **Triggers**: Yes — "committing changes, creating branches, pushing to remote, checkpoint work".
3. **Frontmatter**: name ✅ description ✅ type (`protocol`) ✅ invocation (`both`) ✅ practice (`null`) ✅.
4. **Lines**: 58 ✅.
5. **References linked**: ✅ both — `[references/completion.md]` and `[references/commit-messages.md]` linked in a References section.
7. **Stale?**: No. Consistent with global project-conventions steering (fetch gate, never amend pushed, fix-forward, explicit staging).

### 5. skill-authoring (FIX)
1. **Purpose**: Reference for writing and critiquing agent-loadable skills — format, gates, description craft, anti-patterns.
2. **Triggers**: Yes — strong: "new skill, write a skill, skill format, skill template, activation trigger, skill description, SKILL.md".
3. **Frontmatter**: name ✅ description ✅ type (`reference`) ✅ invocation (`both`) ✅ practice (`null`) ✅.
4. **Lines**: 95 — under 100 but only 5 lines of headroom.
5. **References linked**: ✅ `[references/leading-words.md]` linked from the Leading Words section.
7. **Stale?**: No. But **self-violation**: gate G3 demands a scope boundary ("Does NOT cover: ...") and the Critique Checklist asks "Scope declared?", yet the skill itself declares no scope. Quoted rule: `| G3 | Scope boundary declared ("Does NOT cover: ...") | Add scope section |`.

### 6. eval-criteria (KEEP)
1. **Purpose**: Style guide for writing behavioral eval criteria (PRIMARY/AUTOMATIC FAIL structure, thresholds, naming) that LLM judges can score consistently.
2. **Triggers**: Adequate — "creating, reviewing, or modifying eval definitions" — but no explicit `Trigger:` keyword list; weaker than sibling skills.
3. **Frontmatter**: name ✅ description ✅ type (`reference`) ✅ invocation (`both`) ✅ practice (`null`) ✅.
4. **Lines**: 66 ✅.
5. **References linked**: ✅ `[references/session-review.md]` linked in References section.
7. **Stale?**: Watch item — session-review.md hardcodes a subagent tool blacklist (`grep, glob, code, web_search, web_fetch, use_aws, todo_list`) that is kiro-cli-version-specific and unverifiable from this repo; it will rot silently as the tool evolves.

## Summary
- KEEP: recall-check, recall-session-start, git-protocol, eval-criteria
- FIX: recall (orphaned cli-reference.md — one-line link fixes it), skill-authoring (violates its own G3 scope gate — one-line fix)
- MERGE/RETIRE: none. The recall trio's apparent duplication is intentional skill+steering pairing, confirmed by tier compositions; do not merge.
