---
title: Follow-Up Experiments Plan
date: 2026-05-22
status: proposed
depends_on: [eval-findings-v1, eval-improvement-plan]
---

# Follow-Up Experiments Plan

Experiments to deepen understanding of skill effectiveness beyond the v1 dual-run evaluation.

## Experiment 1: Skill Activation Reliability

**Question**: How reliably do skills activate when they should? When they shouldn't?

**Design**:
- 5 skills × 10 tasks each (5 relevant, 5 irrelevant)
- Check sqlite conversation data for skill content injection
- No judge needed — binary activation detection

**Metrics**:
- True positive rate: skill activates on relevant tasks
- False positive rate: skill activates on irrelevant tasks
- Activation latency: position in conversation where skill appears

**Controls**:
- Irrelevant tasks (skill should NOT activate)
- Ambiguous tasks (borderline relevance)

**Acceptance criteria**:
- Activation rate >80% on relevant tasks
- False positive rate <20% on irrelevant tasks
- If activation is unreliable, skill descriptions need improvement before other experiments are valid

**Effort**: 1 session | **Priority**: P0 (prerequisite for all others)

---

## Experiment 2: Token Efficiency Impact

**Question**: Does loading a skill make the agent more or less token-efficient?

**Background**: SkillReducer (2026) found 60%+ of skill content is non-actionable. Compressed skills improved quality by 2.8%. The "less is more" effect suggests our skills might be bloated.

**Design**:
- 3 conditions per task: no skill (D), full skill (A), compressed skill (C)
- Compressed skill = only actionable rules, no examples/background
- Track: input tokens, output tokens, tool calls, wall-clock time

**Metrics**:
| Metric | Formula |
|--------|---------|
| Token overhead | total_tokens_A - total_tokens_D |
| Quality delta | score_A - score_D |
| Skill ROI | quality_delta / (token_overhead / 1000) |
| OckScore | score - 10·log(tokens/10000) |
| Retention | min(score_C / score_A, 1.0) |

**Key question**: Is the quality improvement worth the token cost? A skill adding 5K tokens that improves score by 0.5 may be net-negative for long tasks (Token Snowball Effect).

**Acceptance criteria**:
- Quantified token overhead per skill
- Identified which skills have positive ROI
- Tested whether compressed versions retain quality (Retention >0.95)
- Recommendation: which skills to compress

**Effort**: 2 sessions | **Priority**: P2

---

## Experiment 3: Process Quality Scoring

**Question**: Does a skill change HOW the agent works, not just WHAT it produces?

**Background**: AgentLens (2026) found 10.7% of SWE-bench passes are "Lucky Passes" with chaotic process. Graphectory shows E→I→V phase ordering predicts success.

**Design**:
- Extract tool call sequences from sqlite conversation data
- Classify each action: Exploration (read/search), Implementation (write/edit), Verification (test/run)
- Score phase ordering and process heuristics

**Heuristics to implement**:
| Heuristic | Scoring |
|-----------|---------|
| Read-before-write | Did agent read target before editing? (0/1) |
| Verify-after-change | Did agent run tests after edits? (0/1) |
| Localize-first | Did agent search/grep before editing? (0/1) |
| No regression cycles | No edit→revert→edit patterns? (0/1) |
| Phase coherence | % of transitions that are forward (E→I→V) |
| Trajectory length | Normalized step count (lower = better) |

**Metrics**:
- Process quality score (composite of heuristics)
- Process delta: process_with_skill - process_without_skill
- Lucky Pass detection: high result score + low process score
- Correlation: process quality vs. result quality

**Key question**: Does the verification-protocol skill improve the verify-after-change heuristic specifically? Does five-whys improve localize-first?

**Acceptance criteria**:
- Can extract and classify tool calls from eval conversations
- At least 3 heuristics scored per trajectory
- Demonstrated that skills change process (not just output)
- Identified any "Lucky Passes" in our v1 results

**Effort**: 3 sessions | **Priority**: P2

---

## Experiment 4: Skill Interference

**Question**: Do multiple skills loaded simultaneously help or hurt?

**Background**: IFScale (2025) shows performance degrades predictably with instruction density. Proactive interference is log-linear with semantic similarity. Effective budget is likely 3-5 simultaneous skills.

**Design**:
- Load N skills simultaneously: 1, 2, 3, 5 (all 5)
- Measure per-skill adherence at each N
- Test orthogonal vs. overlapping skill combinations

**Combinations to test**:
| Combo | Skills | Expected Interference |
|-------|--------|----------------------|
| Orthogonal | verification-protocol + eval-criteria | Low (different domains) |
| Overlapping | five-whys + situation-routing | Medium (both about diagnosis) |
| All loaded | All 5 simultaneously | Unknown |

**Metrics**:
- Per-skill adherence rate at each N
- Interference score: 1 - (adherence_at_N / adherence_alone)
- Primacy bias: does first-loaded skill get preferential treatment?
- Degradation curve: adherence vs. number of loaded skills

**Controls**:
- Single-skill baseline (each skill tested alone)
- Token-matched control (same total tokens, single skill + padding text)

**Acceptance criteria**:
- Quantified interference between specific skill pairs
- Identified the effective skill budget (N where degradation becomes significant)
- Recommendation: which skills can safely co-exist vs. which conflict
- Determined whether skill ordering matters (primacy effect)

**Effort**: 2 sessions | **Priority**: P3

---

## Experiment 5: Task Diversity & Consistency

**Question**: Does each skill help reliably across diverse tasks, or only on specific task shapes?

**Background**: Pass^k metric (SWE Atlas) measures consistency. Even best models drop 30-50% from Pass@1 to Pass³. Action Sequence Diversity shows tasks with ≥6 unique behavioral paths achieve only 25-60% accuracy.

**Design**:
- 5 task categories per skill:
  - C1: Bug fixing (skill-relevant)
  - C2: Feature implementation (skill-relevant)
  - C3: Refactoring (skill-relevant)
  - C4: Code review/Q&A (tangentially relevant)
  - C5: Unrelated domain (negative control)
- 4 tasks per category = 20 tasks per skill
- 3 trials per task per condition

**Metrics**:
| Metric | Formula |
|--------|---------|
| Consistency ratio | min(category_effects) / max(category_effects) |
| Pass^3 | fraction where ALL 3 trials pass |
| Negative control leakage | mean effect on C5 tasks (should be ~0) |
| Cohen's d per category | effect_size per task category |
| CV of effects | SD(effects) / mean(effects) across categories |

**Controls**:
- C5 irrelevant tasks (skill shouldn't help → detects eval leakage)
- Random text control (same token count, nonsense content → detects context-length effect)
- Ablated skill (structure preserved, content scrambled → isolates content value)

**Decision criteria**:
| Signal | Interpretation |
|--------|---------------|
| All categories positive, CV <0.5 | Skill is consistently beneficial |
| Some positive, some negative | Skill is task-shape-specific |
| Negative control shows effect | Eval is leaky — fix before concluding |
| Random text shows similar effect | Benefit is from context length, not content |
| Pass^3 << Pass@1 | Skill adds noise, not reliable signal |

**Acceptance criteria**:
- Consistency score computed per skill
- Negative controls show no significant effect
- Identified task shapes where each skill fails
- Random text control rules out context-length confound

**Effort**: 3 sessions | **Priority**: P2

---

## Experiment 6: Skill Compression (SkillReducer Replication)

**Question**: Can we make skills shorter without losing effectiveness?

**Background**: SkillReducer found that removing 60%+ of skill body content (background, examples, templates) actually IMPROVED quality by 2.8%. Only 38.5% of typical skill content is core actionable rules.

**Design**:
- For each of our 5 skills, create 3 versions:
  - **Full** (current): complete SKILL.md as-is
  - **Core-only**: only imperative rules and decision tables (remove examples, rationale, anti-patterns)
  - **Minimal**: single paragraph distillation of the key behavior
- Run same eval tasks across all 3 versions

**Metrics**:
- Retention: min(score_compressed / score_full, 1.0)
- Token savings: (full_tokens - compressed_tokens) / full_tokens
- Sweet spot: version with best score/token ratio

**Acceptance criteria**:
- Identified which content in each skill is load-bearing vs. filler
- At least one skill where compression improves quality (replicating "less is more")
- Recommendation: optimal skill length for our use case
- Updated skill authoring guidelines based on findings

**Effort**: 2 sessions | **Priority**: P3

---

## Experiment Dependency Graph

```
Exp 1 (Activation) ─────────────────────────────────────────────┐
    │                                                            │
    ▼                                                            │
Exp 2 (Token Efficiency) ──→ Exp 6 (Compression)                │
    │                                                            │
    ▼                                                            │
Exp 3 (Process Tracing) ←── Phase 2 (Real Project Test Bed) ←───┘
    │                                                            │
    ▼                                                            │
Exp 4 (Interference) ←── Exp 5 (Task Diversity)                  
```

- Exp 1 is prerequisite (must confirm activation works)
- Exp 2 and 3 can run in parallel after Phase 2 test bed is ready
- Exp 4 depends on understanding individual skill effects first (Exp 5)
- Exp 6 depends on token efficiency findings (Exp 2)

## Total Estimated Effort

| Experiment | Sessions | Invocations (est.) |
|------------|----------|-------------------|
| 1. Activation | 1 | 50 |
| 2. Token Efficiency | 2 | 90 |
| 3. Process Tracing | 3 | 30 (analysis-heavy) |
| 4. Interference | 2 | 120 |
| 5. Task Diversity | 3 | 300 |
| 6. Compression | 2 | 90 |
| **Total** | **13** | **~680** |

## Key References

- **Graphectory** (Liu et al., 2025): Graph-based trajectory analysis, E→I→V phase ordering
- **AgentLens** (Microsoft, 2026): Lucky Pass detection, Prefix Tree Acceptors
- **SkillReducer** (2026): Skill compression, "less is more" effect, 60% non-actionable content
- **IFScale** (Jaroslawicz et al., 2025): Instruction density scaling, threshold/linear/exponential decay
- **PI-LLM** (Wang & Sun, 2025): Proactive interference, log-linear decay with semantic similarity
- **SWE Atlas** (2026): Task categorization by workflow type, Pass^k consistency
- **OckBench** (2025): Token efficiency scoring, OckScore formula
- **SWE-Effi** (2025): Effectiveness under token/cost budgets, AUC-based scoring
