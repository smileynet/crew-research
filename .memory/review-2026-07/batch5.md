# Skill Review — Batch 5 (Steering / Always-On)

Reviewed: ai-generation-hygiene, context-budget-awareness, source-authority, verification-protocol, project-conventions, subagent-reliability.

**Critical deployment finding:** when deployed as steering, `references/` files do NOT progressively load — every file under `~/.kiro/steering/references/` was observed loaded in the live session context on every turn. "Effective cost" below = SKILL.md + all references. The progressive-loading design intent is broken for steering deployment. This inflates project-conventions from 92 → ~318 lines and subagent-reliability from 137 → 181 lines per turn.

## Verdict Table

| Skill | Verdict | Lines (SKILL / effective) | Issues | Recommended Fix |
|-------|---------|---------------------------|--------|-----------------|
| ai-generation-hygiene | FIX | 93 / 93 | Triple restatement; useless trigger section; stale external-repo pointers | Collapse Required+Banned+Self-Check into one table (~40 lines); delete Trigger Conditions and References sections |
| context-budget-awareness | FIX | 44 / 44 | "When to Restart" conflicts with kiro system prompt; missing `metadata.practice` | Drop/reframe restart guidance as compression guidance; add practice field |
| source-authority | KEEP | 67 / 67 | Research Gates only apply during research tasks; minor overlap with research-methodology skill | Optionally move Research Gates into research-methodology; otherwise keep as-is (dense, no fat) |
| verification-protocol | KEEP | 63 / 109 | strReplace Recovery is off-topic; overlaps kiro `<verification>` system prompt (adds structure, so earns its place) | Move strReplace Recovery to a tool-use/troubleshooting home; keep the rest |
| project-conventions | FIX | 92 / 318 | Grab-bag; commit-policy conflicts with system prompt git_safety; Tool-Over-Shell + Autonomy duplicate system prompt; 173-line global tool-installation ref is crew-research-specific; weak description | Cut duplicated sections (~30 lines saved); resolve commit conflict explicitly; move tool-installation.md to project-level steering |
| subagent-reliability | FIX | 137 / 181 | Over 100-line limit; core rule stated 3×; references/tool-limitations.md never linked from body | Condense to <100 lines (merge redundant sections); link tool-limitations.md from Batching Strategy |

## Per-Skill Detail

### 1. ai-generation-hygiene — FIX (93 lines)

**Purpose:** Ban nine common AI-generated code bloat patterns (redundant checks, gratuitous logging, restating comments, etc.) at generation time.

**Frontmatter:** Complete (`name`, `description`, `metadata.type: protocol`, `invocation: both`, `practice: null`).

**Verbosity — the file says the same nine rules three times:**
- "Required Patterns" (9 prose paragraphs)
- "Banned Patterns" (same 9, renamed P1–P9 with examples)
- "Self-Check Before Commit" (same 9 as questions)

Example — the null-check rule appears as:
> "**Trust the type system.** MUST NOT add null/type checks on values the type system already guarantees."
then again as:
> "**Redundant defensive checks (P1).** `if x is None: raise` when x is typed non-Optional."
then again as:
> "1. Null checks on non-optional parameters?"

One table (Pattern | Rule | Example | Keep-when) covers all three uses in ~30 lines.

**Dead weight for steering:** The "Trigger Conditions" section ends with "Always active — this skill applies to all code generation" — for always-on steering, the whole section is a no-op. Delete.

**Stale:** Two pointers to external repos that don't exist in this project's layout (AGENTS.md says practices live in `docs/development/`):
> "Source practice: `docs/practices/ai-generation-hygiene.md` (in best_practices repo)"
> "Origin: `agent-crews/shared/steering/ai-generation-hygiene.md`"
The source line appears twice (line 12 and References section). Delete both or update.

**System-prompt overlap:** kiro's `default_to_action` already says "Don't add error handling, fallbacks, or validation for scenarios that cannot happen; trust internal code... only validate at system boundaries." The skill's specificity (named patterns, self-check gate) still adds value per the eval-proven "gates > suggestions" pattern — but the overlap justifies aggressive trimming, not retirement.

**Fix:** rewrite as one banned-pattern table + trust-boundary exception + self-check gate. Target ~40 lines. Earns always-on status after the diet.

### 2. context-budget-awareness — FIX (44 lines)

**Purpose:** Treat context as finite — compress between phases, re-anchor objectives in long sessions, restart when quality degrades.

**Frontmatter:** Missing `metadata.practice` (AGENTS.md requires it). Otherwise fine.

**Conflict with system prompt (the main problem):** The skill's opening premise and "When to Restart" section:
> "Context is finite and depletable. Fresh context produces better results than accumulated context."
> "## When to Restart — Phase transitions... Quality degradation..."

directly contradicts kiro's `context_awareness` system section: "Your context window will be automatically compacted... Continue working through context budget limits... do not stop, summarize, or suggest a new session on account of context limits." An agent told both "restart at phase transitions" and "never suggest a new session" gets conflicting instructions — and per the AGENTS.md cross-model note, process-instruction conflicts are a known hazard.

**What still earns its place:** Decaying Resolution table, Context Reinforcement ("After 5+ tool calls without progress, pause and re-anchor"), and the Anti-Patterns list — these are compression/attention guidance the system prompt doesn't cover.

**Fix:** delete or reframe "When to Restart" (e.g., "when the human can restart sessions, suggest it at phase boundaries; otherwise compress"), add `practice` field. Result ~35 lines, KEEP-worthy.

### 3. source-authority — KEEP (67 lines)

**Purpose:** Six-level source authority hierarchy with conflict-resolution rules, citation tags, and confidence labels for all factual claims.

**Frontmatter:** Complete (`type: steering`, `invocation: passive`, `practice: null`).

**Density:** Best-written file in the batch — almost entirely tables, no restatement. Little to cut.

**Always-on cost question:** Confidence labels and citation rules apply broadly (any claim the agent makes), so passive deployment is defensible. The weakest section for always-on is "Research Gates" (G1–G3) — it only fires during research/recommendation tasks and overlaps the territory of the `research-methodology` and `grill-with-docs` on-demand skills. The line "G2 findings MUST appear in the Con column with source" assumes a pros/cons table exists — that's grill-with-docs vocabulary leaking into global steering.

**No staleness. No system-prompt duplication** (kiro's `search_first` and `investigate_before_answering` are adjacent but don't cover source ranking or confidence labels).

**Optional trim:** move Research Gates (~9 lines) into research-methodology. Not required — verdict is KEEP either way.

### 4. verification-protocol — KEEP (63 lines + 46-line reference = 109 effective)

**Purpose:** Gate workflow (identify → run → read → verify → claim) that requires fresh evidence before reporting any task done.

**Frontmatter:** Complete, and the only one in the batch using `params` (build/test/lint command slots) — good pattern.

**References:** `references/project-checks.md` IS linked from the body ("For detailed check commands per project, see [references/project-checks.md]") ✅. But per the deployment finding, it loads always-on anyway — its 46 lines are mostly a build-command lookup table, cheap and broadly useful, acceptable.

**System-prompt overlap:** kiro's `<verification>` section already mandates "run the project's build... run relevant tests... fix them before presenting." The skill adds what the system prompt lacks: checks-by-task-type table, the scope check (`git diff` limited to the task), banned excuses ("should pass"), and the Evidence format. This is the repo's eval-proven core ("gates > suggestions"); the structure earns the overlap.

**Off-topic section:** "strReplace Recovery" —
> "After strReplace failure ('oldStr not found'): 1. Re-read the target file immediately..."
Useful rule, wrong home. It's tool-use error recovery, not verification. Move to troubleshooting-protocol or a tool-use steering note. Minor; doesn't block KEEP.

### 5. project-conventions — FIX (92 lines + 226 reference lines = ~318 effective)

**Purpose:** Grab-bag of always-enforced workspace rules: glossary maintenance, document placement, git discipline, long-running commands, tool installation, tool-over-shell, autonomy.

**Frontmatter:** Missing `metadata.practice`; description is the weakest in the batch: `"Project behavioral rules enforced every turn."` — says nothing about content. (Low impact for passive steering, but fails the repo's own "description doubles as activation trigger" rule.)

**Effective cost is the batch's worst.** All three references load always-on:
- `tool-installation.md` — **173 lines**, and it's crew-research-specific content deployed as GLOBAL steering: its Required Tools table lists `jq`/`bc` as "Required by: eval harness" and `yq` "Required by: init.sh, doctor.sh" — those are this repo's tools, meaningless in other projects. A 40-line Windows `bc` Python-shim heredoc rides along on every turn of every project.
- `windows.md` (40 lines) — dead weight on Linux/macOS sessions; the body even says "See references/windows.md **or** references/unix.md based on your OS", intending conditional loading that doesn't happen.
- `unix.md` (13 lines) — fine.

**Direct conflict with system prompt git_safety:** the skill says
> "Commit after each logical unit of work — don't accumulate uncommitted changes. Push after committing"
while kiro's git_safety says "Only create commits when the user explicitly asks. If unclear, ask first." One of these must yield; today the agent gets both.

**Duplication with system prompt:**
- "Tool Over Shell (strict)" — kiro `<tool_use>` already says use file tools "rather than sed, awk, or echo redirection" and reserve terminal for genuine terminal ops. The skill adds only the `cd`/`working_dir` and mkdir points (kiro rules already cover `cd` too).
- "Autonomy Within Plans" — kiro `<autonomy>` + `<default_to_action>` cover this ("Do not ask 'shall I proceed?'" ≈ "execute sequential steps without pausing").
- "Never amend a commit that has been pushed" / force-push permission — restates git_safety.

**Duplication with other steering/skills:** git discipline overlaps the `git-protocol` on-demand skill.

**What earns its place:** glossary maintenance, document placement (.scratch vs .memory vs docs), Validation Contract, the push-rejection procedure (more specific than system prompt).

**Fix:** (1) cut Tool-Over-Shell to the 2 novel lines, cut Autonomy section, cut amend/force-push restatements (~25 lines saved); (2) resolve commit-policy conflict explicitly (e.g., "in crew-research-convention projects, proactive commits are authorized"); (3) demote `tool-installation.md` to project-level steering in crew-research only; (4) gate windows.md/unix.md on OS at deploy time or merge unix.md's 13 lines inline; (5) add practice field + real description.

### 6. subagent-reliability — FIX (137 lines + 44-line reference = 181 effective)

**Purpose:** Design subagent dispatch around known failure modes — small stages, batching, write-then-read for large data, never silently absorb failures.

**Frontmatter:** Missing `metadata.practice`; has a useful `tools: [kiro-cli, codex]` field (correctly scoping — reference file proves agy/crush don't support subagents).

**Over the repo's own limit:** 137 lines vs AGENTS.md "Do NOT create skills over 100 lines without justification." No justification recorded.

**The core rule is stated three times:**
> "**The rule:** Never put large data inline in a subagent prompt. If the subagent needs data, write it to a file..."
> Task Shape table: "Transform provided text → new structure | ❌ No | Large inline prompt overflows subagent context"
> Write-Then-Read Pattern: "Write the data to a temp file... The subagent's prompt stays small"

And "Detecting Degraded Reliability" (§ last) restates Batching Strategy's "If a batch has 2+ failures, STOP" as "If 2+ stages in a batch return empty: 1. STOP dispatching subagents."

**References not linked:** `references/tool-limitations.md` is never referenced from the SKILL.md body. It contains the validated per-tool data (kiro-cli 4-concurrent limit, codex sandbox issue, agy/crush non-support) that the body's "sized by the tool's concurrency limit" line depends on. Add a link from Batching Strategy. (It loads always-on anyway under steering, but the source-repo cross-link contract should still hold, and matters for on-demand deployments.)

**Not stale** — reference file updated Jul 10 with proof results; frequencies ("~50% empty", "~40% research success") are labeled as observed.

**Always-on justification:** genuinely earned — the reference file itself documents that "the steering prevents the failure pattern" (Proof S2: agent read the steering and refused inline synthesis). On-demand would activate too late, after a bad dispatch design. But 181 always-on lines is heavy for behavior only relevant when dispatching.

**Fix:** merge Detecting Degraded Reliability into Batching Strategy; merge Write-Then-Read + root-cause paragraph into one section; tighten Rules 1–5 prose. Target ≤95 lines. Link tool-limitations.md from the body.

## Cross-Batch Observations

1. **Steering defeats progressive loading.** All 5 reference files (272 lines) load every turn. Either the generator should inline-trim references for steering targets, or references should be deployed outside the steering dir with explicit read-on-demand pointers (the ADR-0002 pointer pattern the repo already uses elsewhere).
2. **Two direct system-prompt conflicts** need resolution: commit policy (project-conventions vs git_safety) and session restart (context-budget-awareness vs context_awareness). Conflicting process instructions are a documented cross-model hazard in this repo's own eval notes.
3. **Frontmatter inconsistency:** 3 of 6 missing `metadata.practice`; `type` values vary without obvious system (protocol / steering / reference) — worth a lint rule.
4. **Total always-on cost of this batch: ~812 lines.** Post-fix target: ~450 lines with no behavior loss.
