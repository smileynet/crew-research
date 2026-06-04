---
title: Eval Methodology Improvement Plan
date: 2026-05-22
status: proposed
depends_on: [eval-findings-v1]
---

# Eval Methodology Improvement Plan

Phased plan to address limitations identified in eval-findings-v1.

## Phase 1: Activation Verification (Low effort, high value)

**Goal**: Confirm skill activation programmatically for every eval trial.

**Tasks**:
1. Add post-run activation check to harness
   - Query sqlite by workspace path after each invocation
   - Search conversation payload for skill content markers
   - Record `activated: true/false` in scores.jsonl
2. Add activation failure handling
   - If skill present but not activated: flag as `activation_failure`
   - Separate from behavioral failure (skill loaded but didn't help)
3. Report activation rate in meta.json summary

**Acceptance criteria**:
- Every scores.jsonl entry includes `"activated": true|false`
- Activation failures are distinguishable from behavioral failures
- meta.json includes `"activation_rate": 0.XX`

**Estimated effort**: 1 session

---

## Phase 2: Real Project Test Bed (Medium effort, high value)

**Goal**: Run evals against a real codebase with build/test/lint.

**Tasks**:
1. Select and prepare test project
   - Criteria: <5MB, TypeScript, has vitest/jest, has lint, <3K LOC
   - Candidates: `unjs/defu`, `sindresorhus/p-queue`, `lukeed/kleur`
   - Pin to specific commit, store as git submodule or tarball
2. Create task templates for the test project
   - Bug fix task (revert a known fix, ask agent to diagnose)
   - Feature task (add a small capability)
   - Refactor task (improve structure without changing behavior)
3. Update harness to support project fixtures
   - New eval field: `fixture: project-name` 
   - Harness clones/extracts project into temp dir before invocation
   - Project has working build/test so agent can actually verify
4. Write 3 tasks per skill (15 total) grounded in the real project
5. Run full eval suite and compare to v1 empty-workspace results

**Acceptance criteria**:
- At least one project set up with build + test passing in temp dir
- 3 tasks per skill that exercise the skill in realistic context
- Results show whether v1 findings hold in realistic conditions
- Agent can actually run `npm test` and get real feedback

**Estimated effort**: 2-3 sessions

---

## Phase 3: Multi-Dimensional Scoring (Medium effort, medium value)

**Goal**: Score agent output on multiple dimensions, not just behavioral compliance.

**Tasks**:
1. Define scoring dimensions
   - **Process**: Did the agent investigate before acting? Systematic approach?
   - **Result**: Is the output correct? Does it solve the problem?
   - **Verification**: Did it run checks and cite evidence?
   - **Communication**: Did it explain reasoning and surface assumptions?
   - **Scope**: Did it stay focused? Avoid unrelated changes?
2. Implement structured judge output (Option C from analysis)
   - Judge returns per-dimension scores in structured format
   - Single judge call, multiple scores extracted
3. Update scoring pipeline
   - Parse multi-dimensional scores from judge output
   - Store per-dimension scores in scores.jsonl
   - Compute per-dimension deltas (with vs without)
4. Generate radar chart data per skill
   - Shows WHERE each skill helps (process? result? communication?)

**Acceptance criteria**:
- Judge prompt produces 5 dimension scores per output
- scores.jsonl includes per-dimension breakdown
- Can answer: "five-whys improves process by X and communication by Y"
- Dimensions are independent (not all correlated with overall score)

**Estimated effort**: 1-2 sessions

---

## Phase 4: Task Diversity (Low effort, medium value)

**Goal**: Prove skills help consistently, not just on cherry-picked tasks.

**Tasks**:
1. Write 5 tasks per skill (25 total) covering different task shapes
   - Vary: complexity, domain, ambiguity level
   - Include tasks where the skill SHOULDN'T help (negative controls)
2. Run full matrix: 5 skills × 5 tasks × 3 trials × 2 conditions = 150 invocations
3. Analyze consistency
   - Per-skill: what % of tasks show positive delta?
   - Per-task-shape: which shapes benefit most from skills?
   - Identify failure modes: when does a skill NOT help?

**Acceptance criteria**:
- 5 tasks per skill with documented rationale
- Consistency metric: % of tasks where delta > 0
- Identified at least one task shape per skill where it doesn't help
- Results inform skill description improvements (better activation targeting)

**Estimated effort**: 2 sessions

---

## Phase 5: Process Tracing (High effort, high value)

**Goal**: Analyze the agent's work process, not just final output.

**Tasks**:
1. Extract tool call sequences from conversation data
   - Parse sqlite conversation payload for tool use events
   - Build ordered sequence: [read, read, write, shell, read, ...]
2. Define process quality heuristics
   - "Read before write" ratio
   - "Verify after change" pattern
   - "Investigation depth" (how many reads before first write)
   - "Scope discipline" (files touched vs files needed)
3. Score process independently of result
   - A correct result with bad process (lucky guess) scores differently than correct result with good process
4. Correlate process scores with skill presence
   - Does the skill change HOW the agent works, not just WHAT it produces?

**Acceptance criteria**:
- Can extract tool call sequence from any eval run
- At least 3 process heuristics implemented and scored
- Can show: "with verification-protocol, read-before-write ratio increases from X to Y"
- Process improvement is measurable independently of result quality

**Estimated effort**: 3-4 sessions

---

## Priority Order

| Phase | Value | Effort | Do When |
|-------|-------|--------|---------|
| 1. Activation Verification | High | Low | Next session |
| 2. Real Project Test Bed | High | Medium | After Phase 1 |
| 3. Multi-Dimensional Scoring | Medium | Medium | After Phase 2 |
| 4. Task Diversity | Medium | Low | Parallel with Phase 3 |
| 5. Process Tracing | High | High | After Phase 2 (depends on sqlite extraction) |

## Dependencies

```
Phase 1 (activation) ──→ Phase 2 (test bed) ──→ Phase 3 (multi-dim)
                                              ──→ Phase 4 (diversity)
                                              ──→ Phase 5 (process tracing)
```

Phase 1 is prerequisite for all others (need to confirm skills are actually loading).
Phase 2 is prerequisite for Phases 3-5 (need realistic context for meaningful multi-dimensional and process analysis).
Phases 3, 4, 5 can run in parallel after Phase 2.
