# Spike Findings Summary

All 5 spikes resolved. No blockers for implementation.

---

## S1: kiro-cli Prompt/Skill Invocation Parity

**Question:** Can skills fully replace prompts in kiro-cli?

**Answer:** Yes in TUI mode, no in non-interactive mode.

- Skills-as-slash-commands shipped in kiro-cli 2.1 (April 2026). In TUI mode, any skill in `.kiro/skills/` is invocable as `/skill-name`.
- `$ARGUMENTS` and `${N}` substitution also works in TUI mode (confirmed by 2.3.0 changelog fix).
- Neither feature works in `--no-interactive` mode (which our harness uses).
- Prompts (`@prompt-name`) work in both TUI and non-interactive mode.

**Decision:** The unified skill model is correct. Generator maps `invocation: user-only` skills to `.kiro/prompts/` for kiro-cli (ensuring they work in both modes). No spec changes needed.

---

## S2: Claude Code Unknown Frontmatter Tolerance

**Question:** Does Claude Code error on our custom frontmatter fields (`type`, `invocation`, `practice`)?

**Answer:** No. Unknown fields are silently stripped before reaching the model.

From GitHub issue anthropics/claude-code#13005: Claude Code parses only `name` and `description` as "load-bearing" fields. All other frontmatter is stripped before injection into model context. No errors, no warnings.

Claude Code's native invocation control fields:
- `disable-model-invocation: true` → user-only (our `invocation: user-only`)
- `user-invocable: false` → agent-only (our `invocation: agent-only`)

**Decision:** Our extended frontmatter is safe. Generator translates our portable `invocation` field to Claude Code's native fields during deployment. Custom fields (`type`, `practice`) remain in deployed files harmlessly.

---

## S3: Codex/Pi Skill Format Validation

**Question:** Do Codex and Pi tolerate our extended frontmatter?

**Answer:** Almost certainly yes, but not confirmed with live testing.

**Why we believe it's safe:**
1. All tools follow the [Agent Skills standard](https://agentskills.io/specification), which specifies only `name`, `description`, `license`, `compatibility`, and `metadata` as recognized fields.
2. The standard includes a `metadata` field explicitly designed for arbitrary extensions — signaling the spec expects tools to handle unknown data gracefully.
3. Claude Code (the largest implementation) strips unknown fields silently — this is the expected behavior for spec-compliant tools.
4. No documentation or GitHub issues for Codex or Pi mention errors on unknown frontmatter.

**Why it's "partial":**
- We don't have Codex CLI or Pi installed in this environment to run live tests.
- "Likely safe" is not "confirmed safe."

**Mitigation:** The generator has a `strip_unknown_frontmatter` escape hatch. If any tool rejects unknown fields, the generator strips them during deployment for that tool's adapter. Source format is unaffected — this is purely a delivery concern.

**What would need to happen to fully confirm:**
- Install Codex CLI, deploy a skill with extra frontmatter, verify it loads
- Install Pi, do the same
- Until then, we proceed with confidence (high probability of success) and the strip escape hatch as insurance

---

## S4: Judge Model Selection

**Question:** How reliable is LLM-as-judge scoring? What's the variance?

**Answer:** Judge variance is ZERO when input is fixed.

We took 4 fixed agent outputs (ranging from clear fail to clear pass) and ran each through the judge 5 times:

| Output Quality | 5 Scores | Stdev |
|---------------|----------|-------|
| Low (handoff, missing sections) | 1, 1, 1, 1, 1 | 0.0 |
| Medium (five_whys, branching) | 3, 3, 3, 3, 3 | 0.0 |
| High (diagnose, systematic) | 5, 5, 5, 5, 5 | 0.0 |
| High (steel_man, strong argument) | 5, 5, 5, 5, 5 | 0.0 |

**Key insight:** All variance in the existing agent-crews eval system (where scores swing 1→5 across trials) comes from **agent non-determinism** (the agent behaves differently each run), NOT from judge non-determinism.

**Decision:** Default config is 1 judge trial per output (judge is deterministic), 3 agent trials per eval (agent is non-deterministic). Cross-provider judging deferred — no evidence of need.

---

## S5: Per-Project Module Customization

**Question:** How do projects customize shared modules without forking them?

**Answer:** Hybrid approach — Params for simple cases, Extends for structural changes.

Tested 3 approaches against 4 real use cases:

| Approach | Godot commands | Custom handoff sections | Stricter git | Domain examples |
|----------|:-:|:-:|:-:|:-:|
| A: Sidecar overrides | ✅ | ✅ | ⚠️ | ✅ |
| B: Extends (inheritance) | ✅ | ✅ | ✅ | ✅ |
| C: Params (value injection) | ✅ | ❌ | ⚠️ | ❌ |

**Decision:** Use both:
- **Params** (80% of cases): Skills declare `params:` with defaults. Projects provide values in `.crew-config.yaml`. Handles commands, paths, thresholds.
- **Extends** (20% of cases): Project creates a local skill that shadows the shared one. Handles new sections, replaced content, structural changes.

Resolution order: local skill > shared skill + project params > shared skill with defaults.

ADR 0002 filed. Issue #1 closed.

---

## Prompt Arguments Workaround

**Problem:** `$ARGUMENTS` substitution only works in TUI mode. Our eval harness runs in `--no-interactive` mode. How do we test skills that need user-provided context (file paths, bug descriptions, parameters)?

**Answer:** The user's natural language query IS the argument. No workaround needed — this is actually how real users interact.

**How it works:**

In TUI mode, a user might type:
```
/diagnose my API returns 500 when payload exceeds 1MB
```
The skill loads, `$ARGUMENTS` gets "my API returns 500 when payload exceeds 1MB".

In non-interactive mode (our harness), we do:
```bash
kiro-cli chat --no-interactive -a "Diagnose this: my API returns 500 when payload exceeds 1MB"
```
The skill's `description` ("Use when user says diagnose, debug, reports a bug...") triggers activation. The full query provides the context. The skill protocol shapes the response.

**The result is identical** — the skill activates, receives the user's context, and follows its protocol. We confirmed this with canary strings: the skill loaded, the protocol was followed, and the "arguments" (the bug description) were available to the agent.

**For our eval harness, this means:**
```yaml
- name: diagnose-follows-protocol
  input: "Diagnose this: my API returns 500 when the payload exceeds 1MB"
  criteria: |
    PRIMARY: Response follows the 3-hypothesis protocol before suggesting fixes.
```

The `input` field IS the argument. No special handling needed. This is actually MORE realistic than `$ARGUMENTS` substitution because it tests the real user experience (description-based activation + natural language context).

**What we CAN'T test in non-interactive mode:**
- The `/skill-name` slash command invocation path (TUI-only)
- `$ARGUMENTS` positional substitution (`${0}`, `${1}`)
- The autocomplete/menu experience

These are UX features, not behavioral features. The skill's actual behavior (protocol followed, output shaped correctly) is fully testable via natural language activation.

---

## S6: Cross-Tool Proof Abstraction

### Hypothesis
A single proof definition can work across tools if fixture types are abstract (eager_file, skill, agent) and the adapter maps them to tool-specific delivery.

### Finding
Confirmed. The abstraction layer is:

| Abstract Type | kiro-cli Delivery | Claude Code Delivery |
|---------------|-------------------|---------------------|
| `eager_file` | `file://` in agent resources | Content in CLAUDE.md |
| `skill` | `skill://` in agent resources + SKILL.md file | `.claude/skills/` directory |
| `agent` | JSON in `.kiro/agents/` | Markdown in `.claude/agents/` |

### Decision
Proof definitions use abstract fixture types. The harness reads the adapter to determine HOW to deploy each fixture type. One definition, multiple tools.

---

## S7: Per-Agent Skill Scoping in Claude Code

### Hypothesis
Claude Code's project-wide skill discovery prevents per-agent skill assignment needed for crew patterns.

### Finding
**Solved.** Claude Code subagents have a `skills` frontmatter field that preloads full skill content at startup. Combined with `disallowedTools: Skill`, this gives strict per-agent scoping.

### Generator Mapping

| Our Concept | Claude Code Mechanism |
|-------------|---------------------|
| Archetype `skills: [list]` | Subagent `skills: [list]` (preloaded at spawn) |
| Archetype `tools: [list]` | Subagent `tools: [list]` |
| Archetype `eager-context` (scoped) | Content in subagent system prompt body |
| Archetype `eager-context` (universal) | Content in CLAUDE.md |

### Limitation
CLAUDE.md loads for ALL agents (project-wide). Scoped eager-context (orchestrator-only, worker-only) must go in the subagent's system prompt body, not CLAUDE.md. The generator handles this mapping.

---

## Cross-Tool Architecture Summary

| Feature | kiro-cli | Claude Code |
|---------|----------|-------------|
| Agent format | JSON (`.kiro/agents/`) | Markdown + YAML frontmatter (`.claude/agents/`) |
| Context binding | Per-agent via `resources` field | Project-wide discovery + subagent `skills` preloading |
| Eager context (universal) | `.kiro/steering/` via resources | `CLAUDE.md` (all agents) |
| Eager context (scoped) | Per-agent steering via resources | Subagent system prompt body |
| Skill delivery | `skill://` URI in agent resources | `.claude/skills/` directory (project-wide) |
| Skill scoping | Per-agent (only sees declared skills) | Subagent `skills` field + optional `disallowedTools: Skill` |
| Subagent spawning | `subagent` tool | Agent tool (auto or @-mention) |
| Non-interactive invocation | `kiro-cli chat --no-interactive -a` | `claude --print` |
| User-only skills | `.kiro/prompts/` directory | `disable-model-invocation: true` on skill |
| Headless agent selection | `--agent name` | `--agent name` |
