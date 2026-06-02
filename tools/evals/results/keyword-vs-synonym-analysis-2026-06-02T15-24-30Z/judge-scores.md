# Judge Scores: Keyword vs Synonym Analysis

**Experiment:** Two prompt conditions ('keywords' using JTBD/Decisions/Non-obvious/Prior art/Audience/Conventions vs 'synonyms' using Purpose/Architecture/Complexity/Patterns/Users/Style) applied to 4 task types analyzing the Zod TypeScript library.

**Judge:** kiro-cli, 2026-06-02

---

## Individual Scores

### 1. keyword-analysis__keywords__trial1

| Dimension | Score | Justification |
|-----------|-------|---------------|
| Depth | 5 | Surfaces non-obvious internals: ParsePayload.fallback flag interactions, deferred initializers and partial state risk, $ZodCheck.onattach mutating bag metadata, async parsing silently throwing $ZodAsyncError, the kh locale being a stub. Goes far beyond file structure. |
| Actionability | 5 | Explicitly names gotchas ("code that tries to inspect schema internals via enumeration will silently miss it"), identifies ordering dependencies (onattach), names specific failure modes (async parse on sync schema), explains the version triple lock. A contributor can directly act on every finding. |
| Insight Novelty | 5 | Reveals fallback vs default semantics in $ZSF (not documented), the "backward" direction for codecs, the trait-based constructor with Set<string> tracking, the z.v3 subpath shipping 160KB inline. None of this is in the README. |
| Why-Reasoning | 5 | Consistently explains WHY: globalThis for dual-package hazard, lazy method binding to avoid allocating closures, JIT for hot parse loops, codec direction to avoid two traversal engines. Every decision includes its rationale and tradeoff. |

**Total: 20/20**

---

### 2. keyword-analysis__synonyms__trial1

| Dimension | Score | Justification |
|-----------|-------|---------------|
| Depth | 4 | Reads source, identifies the layered architecture, $constructor trait system, JIT compilation, conditional exports, and deferred initialization. Understands the internal patterns at a code-level but doesn't surface as many edge cases or subtle interactions. |
| Actionability | 4 | Names specific files with sizes, identifies the @zod/source condition, mentions defineLazy for circular deps, and the Standard Schema interface. Less specific about failure modes or gotchas than the keywords variant. |
| Insight Novelty | 4 | Goes well beyond README: identifies the trait system, JIT fast path, lazy method binding, dual API surface. But doesn't reveal the fallback/default distinction, async error behavior, or payload interaction subtleties. |
| Why-Reasoning | 3 | Occasionally explains rationale (JIT for performance, mini for tree-shaking, immutable API for safe composition) but many items are stated as facts without explaining why that choice was made over alternatives. |

**Total: 15/20**

---

### 3. keyword-open-ended__keywords__trial1

| Dimension | Score | Justification |
|-----------|-------|---------------|
| Depth | 5 | Digs into release workflow mechanics (canary publishes silently), fail-on-console.ts test enforcement, untracked files blocking push, wiki/optionality.md documenting hard-won understanding of optional/catch/default/transform interaction. Reads CI config, scripts, hooks. |
| Actionability | 5 | Identifies 7 specific non-obvious gotchas with concrete consequences: version bump = irreversible release, console.log = test failure, untracked files block push, TypeScript 5.5 pinned for inference reasons. Each is actionable for a new contributor. |
| Insight Novelty | 5 | Reveals canary publishing on every push, the console replacement pattern, the madge circular dep check with exclusions, the wiki/optionality.md as documentation of a complex interaction. Surfaces things buried in scripts and CI config. |
| Why-Reasoning | 5 | Explains tradeoffs in a table format: single-package multi-entrypoint (benefit: one install, cost: complex exports map), mutable payload (benefit: zero allocation, cost: subtle bugs), noParameterAssign (benefit: perf, cost: reasoning difficulty). Consistently names what was traded. |

**Total: 20/20**

---

### 4. keyword-open-ended__synonyms__trial1

| Dimension | Score | Justification |
|-----------|-------|---------------|
| Depth | 5 | Also reads CI workflows, scripts, hooks. Identifies version bump = release trigger, canary publishing, console-as-error pattern, trait-based inheritance, globalThis singleton hazard mitigation. Comparable depth to the keywords variant. |
| Actionability | 5 | Enumerates 7 non-obvious gotchas with specific consequences. Names the exact scripts (check-versions.ts, fail-on-console.ts, write-stub-package-jsons.ts). Explains what triggers what and what to watch for. |
| Insight Novelty | 5 | Surfaces Standard Schema positioning, JSR hedging, arethetypeswrong testing, competitors explicitly benchmarked in devDeps. Identifies ecosystem positioning and competitive awareness not documented anywhere obvious. |
| Why-Reasoning | 4 | Good on explaining tradeoffs (performance over purity, dual CJS+ESM hazard mitigation, three version locks). Slightly less consistent than keywords variant — some items in the Conventions table are stated without rationale. |

**Total: 19/20**

---

### 5. synonym-analysis__keywords__trial1

| Dimension | Score | Justification |
|-----------|-------|---------------|
| Depth | 3 | Reads source files, identifies the layered architecture, $constructor pattern, lazy binding, conditional exports. But stays mostly at structural level — doesn't dig into edge cases, subtle interactions, or failure modes. |
| Actionability | 3 | Names files and patterns (schemas.ts 148KB, classic 97KB, parse.ts), identifies JIT compilation and discriminated union optimization. But doesn't explain what to watch out for when modifying these areas. |
| Insight Novelty | 3 | Goes beyond README (identifies trait system, lazy binding, conditional exports, defineLazy) but stays at code-structure level. Doesn't reveal design tensions or hidden constraints. |
| Why-Reasoning | 3 | Occasionally explains why (lazy binding "to avoid allocating closures per instance until used", immutable API "every method returns a new schema"). But many items just describe what exists. |

**Total: 12/20**

---

### 6. synonym-analysis__synonyms__trial1

| Dimension | Score | Justification |
|-----------|-------|---------------|
| Depth | 3 | Explores the layered architecture, reads core files, identifies the $constructor pattern, conditional exports, Standard Schema compliance. Similar structural depth to synonym-analysis__keywords but doesn't go deeper into interactions. |
| Actionability | 3 | Names specific files with sizes, identifies the trait system and lazy binding. Mentions tests co-located with source. But doesn't identify specific gotchas or failure modes for contributors. |
| Insight Novelty | 3 | Beyond README: identifies trait system, JIT, deferred initialization, dual API surface. But largely the same structural observations as other analyses without deeper insight. |
| Why-Reasoning | 3 | Some rationale provided (core/classic split for different audiences, mini for bundle size, @__PURE__ for tree-shaking). But the "Patterns" and "Style" sections mostly describe what exists without explaining why over alternatives. |

**Total: 12/20**

---

### 7. synonym-open-ended__keywords__trial1

| Dimension | Score | Justification |
|-----------|-------|---------------|
| Depth | 3 | Identifies layered architecture, monorepo structure, file sizes, $constructor pattern, conditional exports, JIT. Reads core files but doesn't dig into edge cases or interactions between components. |
| Actionability | 3 | Names packages and files, mentions llms.txt and MCP server endpoint. Lists patterns and coding conventions. But doesn't explain specific gotchas or what to watch out for when contributing. |
| Insight Novelty | 3 | Notes globalThis for CJS/ESM singleton sharing, llms.txt for AI tooling, sideEffects: false. These go beyond README but are observable from package.json without deep source reading. |
| Why-Reasoning | 2 | Mostly descriptive. "Zero external dependencies" — but why? "Biome for formatting" — but why not ESLint? "Parameter reassignment allowed" — stated as fact. The Global config bullet mentions "CJS/ESM boundaries" which is the closest to rationale. |

**Total: 11/20**

---

### 8. synonym-open-ended__synonyms__trial1

| Dimension | Score | Justification |
|-----------|-------|---------------|
| Depth | 3 | Similar structural exploration as other synonym-open-ended. Identifies monorepo layout, layered architecture, file sizes, key patterns. Reads core.ts in full but stays at descriptive level. |
| Actionability | 3 | Names files, sizes, packages. Mentions play.ts for experimentation, Husky hooks for pre-commit/pre-push. Useful orientation but no gotchas or danger zones identified. |
| Insight Novelty | 3 | Identifies trait system, conditional exports, JIT, defineLazy. Same structural observations as other outputs. Notes "any is allowed and considered a feature" which is a mild insight. |
| Why-Reasoning | 2 | Almost entirely descriptive. Lists what tools are used without explaining why they were chosen. "Performance-first tradeoffs — mutable payload objects during parse, parameter reassignment" — states the tradeoff but doesn't explain the reasoning process. |

**Total: 11/20**

---

## Summary Table

| File | Condition | Task | Depth | Action | Novel | Why | Total |
|------|-----------|------|:-----:|:------:|:-----:|:---:|:-----:|
| keyword-analysis__keywords | keywords | keyword-analysis | 5 | 5 | 5 | 5 | 20 |
| keyword-analysis__synonyms | synonyms | keyword-analysis | 4 | 4 | 4 | 3 | 15 |
| keyword-open-ended__keywords | keywords | keyword-open-ended | 5 | 5 | 5 | 5 | 20 |
| keyword-open-ended__synonyms | synonyms | keyword-open-ended | 5 | 5 | 5 | 4 | 19 |
| synonym-analysis__keywords | keywords | synonym-analysis | 3 | 3 | 3 | 3 | 12 |
| synonym-analysis__synonyms | synonyms | synonym-analysis | 3 | 3 | 3 | 3 | 12 |
| synonym-open-ended__keywords | keywords | synonym-open-ended | 3 | 3 | 3 | 2 | 11 |
| synonym-open-ended__synonyms | synonyms | synonym-open-ended | 3 | 3 | 3 | 2 | 11 |

---

## Condition Averages

| Condition | Depth | Actionability | Novelty | Why-Reasoning | Total |
|-----------|:-----:|:-------------:|:-------:|:-------------:|:-----:|
| **keywords** (n=4) | 4.00 | 4.00 | 4.00 | 3.75 | 15.75 |
| **synonyms** (n=4) | 3.75 | 3.75 | 3.75 | 3.00 | 14.25 |
| **Delta (kw − syn)** | +0.25 | +0.25 | +0.25 | +0.75 | **+1.50** |

---

## Interpretation

The **keywords condition outperforms synonyms by +1.50 total points** (15.75 vs 14.25), with the largest gap on **Why-Reasoning (+0.75)**. The power words "Decisions and tradeoffs" and "Non-obvious" appear to elicit more causal reasoning and edge-case surfacing.

However, the effect is **confounded by task type**. The "keyword-analysis" and "keyword-open-ended" tasks (which use the JTBD/Decisions/Non-obvious/Prior art/Audience/Conventions headings as their structure) produced dramatically better outputs regardless of condition. Both conditions scored 19-20 on keyword-analysis and keyword-open-ended tasks, vs 11-12 on synonym-analysis and synonym-open-ended tasks.

**Key finding:** The task prompt structure (what questions are asked) matters more than whether specific power words are used in the instructions. When both conditions were given the "keyword-style" task (asking about JTBD, decisions, gotchas, audience), both produced excellent output. When given the "synonym-style" task (asking about purpose, architecture, complexity, patterns, users, style), both produced shallower output. The power words in the condition prompt added a modest uplift (+0.75 on why-reasoning) but the task framing dominated.
