# Spike Experiment Plans

## S1: kiro-cli Prompt/Skill Invocation Parity

### Hypothesis
Skills with `disable-model-invocation` equivalent behavior (user-only invocation) can fully replace `.kiro/prompts/` for user-triggered workflows, including argument passing and orchestration features.

### What We Need to Validate

1. Can a skill in `.kiro/skills/` be invoked as `/skill-name` from the CLI?
2. Does `$ARGUMENTS` substitution work in skills the same as in prompts?
3. Can a skill reference other skills (progressive loading) when user-invoked?
4. Does a skill with no `description` (or a non-matching description) still appear in the `/` menu?
5. Are there prompt-specific features (e.g., `{{workspace.ephemeral}}` template variables) that don't work in skills?
6. Can a skill be hidden from agent auto-loading while remaining user-invocable?

### Experiment

```bash
# Setup: create test workspace
mkdir -p /tmp/spike-s1/.kiro/skills/test-prompt/
mkdir -p /tmp/spike-s1/.kiro/prompts/

# Test skill (user-only equivalent)
cat > /tmp/spike-s1/.kiro/skills/test-prompt/SKILL.md << 'EOF'
---
name: test-prompt
description: Test skill acting as a prompt. Use only when explicitly invoked.
---
Echo back the following arguments: $ARGUMENTS

Report the workspace path: {{workspace.ephemeral}}
EOF

# Control prompt (existing mechanism)
cat > /tmp/spike-s1/.kiro/prompts/test-prompt-control.md << 'EOF'
---
name: test-prompt-control
description: Control prompt for comparison.
---
Echo back the following arguments: $ARGUMENTS

Report the workspace path: {{workspace.ephemeral}}
EOF
```

**Test cases:**

| # | Test | Command | Pass Condition | Fail Condition |
|---|------|---------|----------------|----------------|
| 1 | Skill appears as slash command | Type `/test-prompt` in kiro-cli | Autocompletes and invokes | Not found or errors |
| 2 | Arguments pass through | `/test-prompt hello world` | Output contains "hello world" | Arguments lost or mangled |
| 3 | Template variables resolve | Check output for workspace path | `{{workspace.ephemeral}}` replaced with actual path | Literal `{{workspace.ephemeral}}` in output |
| 4 | Agent doesn't auto-load for unrelated query | Ask "what is 2+2?" | Skill NOT loaded (no description match) | Skill content appears in unrelated context |
| 5 | Prompt control behaves identically | `@test-prompt-control hello world` | Same behavior as test 2 | Different behavior |

### Pass Criteria (overall)
- Tests 1-4 all pass → prompts can be fully replaced by skills in kiro-cli
- Template variables work in skills → no feature gap

### Fail Criteria (overall)
- Any of tests 1-3 fail → skills cannot replace prompts; maintain separate `atomics/prompts/` concept
- Template variables don't resolve in skills → document as generator responsibility (pre-process before deployment)

### Decision on Failure
If skills can't fully replace prompts in kiro-cli, we keep `invocation: user-only` as a frontmatter field but the generator must emit these to `.kiro/prompts/` rather than `.kiro/skills/`. The source format stays unified; only delivery differs.

---

## S2: Claude Code Unknown Frontmatter Tolerance

### Hypothesis
Claude Code ignores unknown YAML frontmatter fields in SKILL.md files, allowing us to add `type`, `invocation`, and `practice` fields without breaking skill loading or activation.

### What We Need to Validate

1. Does Claude Code load a skill with extra frontmatter fields?
2. Does the `description` still trigger activation correctly?
3. Does `/skill-name` invocation still work?
4. Are there any warnings or errors logged?
5. Does the Agent Skills standard specify behavior for unknown fields?

### Experiment

```bash
# Deploy test skill to Claude Code
mkdir -p ~/.claude/skills/frontmatter-test/

cat > ~/.claude/skills/frontmatter-test/SKILL.md << 'EOF'
---
name: frontmatter-test
description: Test skill with extra frontmatter. Use when asked about frontmatter testing.
type: reference
invocation: both
practice: testing-philosophy
custom_field: arbitrary_value
---

# Frontmatter Test

If you can read this, the skill loaded successfully despite extra frontmatter fields.

The secret phrase is: FRONTMATTER_WORKS_9K2X
EOF
```

**Test cases:**

| # | Test | Method | Pass Condition | Fail Condition |
|---|------|--------|----------------|----------------|
| 1 | Skill loads without error | Start Claude Code session, check for warnings | No errors on startup | Parse error or warning about unknown fields |
| 2 | Description-based activation | Ask "tell me about frontmatter testing" | Skill activates, outputs secret phrase | Skill not activated |
| 3 | Slash command invocation | Type `/frontmatter-test` | Skill invokes, outputs secret phrase | Command not found |
| 4 | Standard fields still work | Check `description` is visible in skill listing | Description appears in `/skills` or equivalent | Description missing or truncated |
| 5 | No field collision | Verify `type` doesn't conflict with any Claude Code internal field | No behavioral change from `type` field | `type` field causes unexpected behavior |

### Pass Criteria (overall)
- All 5 tests pass → our extended frontmatter is safe in Claude Code
- We can ship skills with `type`, `invocation`, `practice` fields without tool-specific stripping

### Fail Criteria (overall)
- Test 1 fails (parse error) → generator must strip unknown fields before deploying to Claude Code
- Test 5 fails (field collision) → rename our field (e.g., `skill-type` instead of `type`)

### Decision on Failure
If Claude Code rejects unknown fields, the generator adds a stripping step: read source SKILL.md, remove non-standard fields, write cleaned version to deployment target. Source format unchanged; delivery is filtered.

---

## S3: Codex/Pi Skill Format Validation

### Hypothesis
Codex CLI and Pi follow the Agent Skills standard and tolerate unknown frontmatter fields, similar to Claude Code. Skills authored with our extended frontmatter will load correctly in both tools.

### What We Need to Validate

1. Does Codex CLI discover skills from `~/.codex/skills/`?
2. Does Pi discover skills from `~/.pi/agent/skills/`?
3. Do both tools ignore unknown frontmatter fields?
4. What fields does each tool require (name? description? both?)?
5. Does the `name` field need to match the directory name in each tool?

### Experiment

```bash
# Codex test
mkdir -p ~/.codex/skills/format-test/
cat > ~/.codex/skills/format-test/SKILL.md << 'EOF'
---
name: format-test
description: Validates extended frontmatter in Codex. Use when asked about format testing.
type: protocol
invocation: both
practice: testing-philosophy
---

# Format Test (Codex)
Secret: CODEX_FORMAT_OK_3M7P
EOF

# Pi test
mkdir -p ~/.pi/agent/skills/format-test/
cat > ~/.pi/agent/skills/format-test/SKILL.md << 'EOF'
---
name: format-test
description: Validates extended frontmatter in Pi. Use when asked about format testing.
type: protocol
invocation: both
practice: testing-philosophy
---

# Format Test (Pi)
Secret: PI_FORMAT_OK_5R2K
EOF
```

**Test cases (per tool):**

| # | Test | Pass Condition | Fail Condition |
|---|------|----------------|----------------|
| 1 | Skill discovered on startup | Appears in skill listing | Not found |
| 2 | Description triggers activation | Ask about "format testing" → skill loads | Not activated |
| 3 | Unknown fields tolerated | No errors or warnings | Parse error on unknown field |
| 4 | Name/directory match enforced? | Document whether mismatch causes issues | — (informational) |
| 5 | Slash command works | `/format-test` invokes skill | Not available as command |

### Pass Criteria (overall)
- Both tools load skills with extended frontmatter without errors
- Activation works based on description field

### Fail Criteria (overall)
- Either tool rejects unknown fields → generator must strip per-tool
- Either tool requires fields we don't include → add to our spec as required

### Decision on Failure
- If one tool rejects fields: generator strips for that tool only
- If a tool requires a field we don't have (e.g., `license`): add as optional to our spec
- If a tool isn't accessible (no Codex/Pi license): defer that adapter, document gap

### Access Prerequisite
This spike requires active Codex CLI and Pi installations. If either is unavailable:
- Document as "untested" in compatibility matrix
- Defer adapter implementation until access is available
- Proceed with kiro-cli + Claude Code as primary targets

---

## S4: Eval Harness Judge Model Selection

### Hypothesis
A cross-provider judge (different model family from the subject) with temperature 0 produces reliable, reproducible scores with low variance across runs. Claude Sonnet judging kiro-cli agents (which use Claude under the hood) may have self-preference bias; a cross-family judge will be more reliable.

### What We Need to Validate

1. Score variance across 5 identical runs with the same judge
2. Score agreement between different judge models on the same output
3. Whether self-family judging (Claude judging Claude output) shows measurable bias
4. Cost per eval across different judge models
5. Whether reasoning-before-score enforcement reduces variance

### Experiment

**Setup:** Select 10 representative eval outputs (mix of clear pass, clear fail, borderline):
- 3 routing evals (dispatcher delegates correctly)
- 3 scope evals (agent refuses out-of-scope)
- 2 execution evals (worker follows protocol)
- 2 borderline cases (partial compliance)

**Judge configurations to test:**

| Config | Model | Temperature | Reasoning |
|--------|-------|-------------|-----------|
| A | Claude Sonnet 4 | 0 | Before score |
| B | GPT-4o | 0 | Before score |
| C | Gemini 1.5 Pro | 0 | Before score |
| D | Claude Sonnet 4 | 0 | Score only (no reasoning) |

**Protocol:**
1. Run each of the 10 outputs through each judge config 5 times
2. Record: score, reasoning, latency, token cost
3. Compute per-config: mean, stddev, min, max per eval
4. Compute cross-config agreement: Cohen's kappa between judge pairs

**Metrics:**

| Metric | Target | Concerning |
|--------|--------|-----------|
| Intra-judge variance (same config, 5 runs) | stddev ≤ 0.3 | stddev > 0.7 |
| Inter-judge agreement (kappa) | ≥ 0.6 | < 0.4 |
| Self-preference bias (Claude judging Claude) | No systematic +0.5 vs cross-family | Consistent inflation |
| Cost per eval | < $0.05 | > $0.20 |
| Reasoning-before-score effect | Lower variance than score-only | No difference |

### Pass Criteria (overall)
- At least one config achieves stddev ≤ 0.3 AND kappa ≥ 0.6 with another config
- Clear recommendation for default judge with documented tradeoffs

### Fail Criteria (overall)
- All configs show stddev > 0.7 → rubric design problem, not judge problem. Redesign criteria.
- No cross-config agreement (kappa < 0.4 everywhere) → criteria are ambiguous. Tighten anchors.

### Decision on Failure
- High variance → tighten criteria anchors (more concrete score definitions)
- Low agreement → run calibration session (score same outputs, discuss disagreements)
- Self-preference bias confirmed → mandate cross-family judging in spec

### Output
Documented recommendation in `tools/evals/judges/README.md`:
- Default judge model + config
- When to use multi-judge quorum (high-stakes evals)
- Cost estimates per eval type

---

## S5: Per-Project Module Customization Design (Issue #1)

### Hypothesis
A layered override system (similar to CSS cascade or Helm values) can allow projects to customize shared modules without forking them, while keeping the shared module as the upstream source of truth.

### What We Need to Validate

1. Which override mechanism is simplest while covering real use cases?
2. Can overrides be validated (detect when a shared module changes in ways that break an override)?
3. What's the resolution order when multiple layers apply?
4. Does this work at the skill level, the eager-context level, or both?

### Concrete Use Cases to Design Against

| Use Case | What's Customized | Why |
|----------|------------------|-----|
| Godot troubleshooting | `verification-protocol` skill adds Godot-specific check commands | Project uses GDScript, not TypeScript |
| Custom handoff sections | `workspace` eager-context adds "Deployment State" section to HANDOFF.md | Infra project needs deployment tracking |
| Stricter git protocol | `git-protocol` skill changes from "push immediately" to "PR required" | Team project with review requirements |
| Domain-specific reasoning | `five-whys` skill adds domain examples | Healthcare project needs HIPAA-aware examples |

### Approaches to Prototype

**A) Override files (sidecar)**
```
project/.overrides/skills/verification-protocol.yaml
```
Contains only the fields to override. Merged at generation time.

**B) Inheritance (extends)**
```yaml
# project skill
---
name: verification-protocol
extends: verification-protocol  # references shared module
---
# Only the additions/changes below
## Additional Checks (Godot)
- Run `godot --headless --script test_runner.gd`
```

**C) Parameterized templates**
```yaml
# shared skill uses variables
## Project-Specific Commands
- Build: {{project.build_command}}
- Test: {{project.test_command}}
```
Project provides values in a config file.

### Experiment Protocol

1. Implement each approach as a minimal prototype (one skill, one override)
2. Evaluate against criteria:

| Criterion | Weight | A (sidecar) | B (extends) | C (params) |
|-----------|--------|-------------|-------------|------------|
| Simplicity for skill author | High | ? | ? | ? |
| Simplicity for project customizer | High | ? | ? | ? |
| Drift detection (shared module changes) | Medium | ? | ? | ? |
| Composability (multiple overrides) | Low | ? | ? | ? |
| Works without generator | Medium | ? | ? | ? |

3. Pick the winner based on weighted score

### Pass Criteria (overall)
- One approach scores well on all High-weight criteria
- The chosen approach handles all 4 use cases above
- Can be explained in <1 page of documentation

### Fail Criteria (overall)
- No approach handles all use cases → may need hybrid (e.g., params for simple cases, extends for complex)
- All approaches require the generator → violates "modules work standalone" principle

### Decision on Failure
- If no single approach works: combine params (for simple value injection) with extends (for structural changes)
- If generator is required: accept this as a generator-only feature, document that standalone use doesn't support customization
- File findings as ADR regardless of outcome

### Output
- ADR in `.memory/adr/` documenting the decision
- Update to generator spec with customization support
- One working example (Godot troubleshooting overlay)
