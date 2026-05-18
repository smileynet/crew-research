# Crew Research Plan

Monorepo of independent tools that scaffold a final system for building consistent, reusable behavioral modules (agents, skills, prompts, crews, dispatchers) across multiple AI coding tools.

## Phase 1: Tool Function Proof System

Empirically validate platform assumptions about how AI coding tools behave. Proofs are declarative and portable across tools (kiro-cli, claude code, codex, oh-my-pi, pi.dev, etc.).

### Components

1. **Invocation harness** — bash runner handling timeouts, output capture, ANSI stripping, exit codes
2. **Tool adapters** — per-tool profiles mapping abstract operations to concrete CLI syntax
3. **Proof definitions** — declarative YAML specs: fixtures, query, expected presence/absence of canary strings
4. **Isolation mechanism** — mktemp workspaces, unique canary strings, fixture deployment, cleanup
5. **Result storage** — timestamped JSON per run, keyed by tool + version, enabling regression detection

### Structure

```
proofs/
├── adapters/          # per-tool CLI profiles (kiro-cli.yaml, claude-code.yaml, etc.)
├── definitions/       # declarative proof specs
├── harness/           # bash runner: isolation, invocation, output capture, grading
└── results/           # timestamped JSON per run, keyed by tool + version
```

### Proof Definition Format

```yaml
id: A4-file-resource-always-loaded
assumption: "file:// resources are always loaded into agent context"
fixtures:
  files:
    context-files/canary.md: "The canary phrase is: CANARY_FILE_7X9Q2"
  agents:
    file-resource-agent:
      tools: []
      resources: ["file://context-files/canary.md"]
      prompt: "Report the canary phrase from your pre-loaded context. Be exact."
query: "What is the canary phrase in your pre-loaded context?"
expect:
  present: ["CANARY_FILE_7X9Q2"]
  absent: []
```

### Adapter Format

```yaml
tool: kiro-cli
invoke: "kiro-cli chat --no-interactive -a --agent {agent} '{query}'"
agent_format: json
agent_location: ".kiro/agents/{name}.json"
timeout: 90
```

### Prior Art

- `agent-crews/tests/assumptions/run.sh` — imperative bash implementation validating 7 assumptions (A1–A7) against kiro-cli 2.2.2
- `agent-crews/docs/archive/build-time-context-injection.md` — assumption register and design rationale

### Design Decisions

- **Declarative over imperative** — same proof definitions run against any tool adapter without rewriting test logic
- **Canary string methodology** — unique strings planted in fixtures; presence/absence in output proves context loading behavior
- **Version-keyed results** — proofs must be re-validated when tool versions change; regression tracking is first-class

## Phase 2: Agent Behavior Evaluation System

LLM-as-judge behavioral evaluation that validates agent decisions (routing, scope, orchestration, protocol compliance). Portable across tools and judge models.

### Components

1. **Eval definitions** — declarative YAML specs: agent, input, criteria (PRIMARY + AUTOMATIC FAIL), ideal response, tags, threshold
2. **Invocation harness** — isolated mktemp environments, agent invocation via tool adapters (reuses Phase 1 adapters)
3. **Judge framework** — pluggable judge backends (starts with single LLM judge, extensible to multiple judges, majority vote, hybrid code+LLM)
4. **Reliability layer** — multi-trial pass^k, retry policy (only on infrastructure failures), majority-vote scoring
5. **Result storage** — per-run directories with meta.json (context: commit, tool version, config) + scores.jsonl (per-eval scores)

### Structure

```
evals/
├── adapters/          # reuses Phase 1 tool adapters for agent invocation
├── definitions/       # declarative eval specs (YAML)
├── judges/            # pluggable judge backends (llm-judge.yaml, code-judge.yaml, etc.)
├── harness/           # isolation, invocation, scoring pipeline
└── results/           # timestamped run directories
```

### Eval Definition Format

```yaml
- name: dispatcher-routes-augment
  agent: dispatcher
  input: "add a new agent to the general crew"
  criteria: |
    PRIMARY: Delegates to crew-augmenter.
    AUTOMATIC FAIL (score 1): Delegates to wrong agent, OR does the work itself.
    BONUS (score 5): Narrates why this agent was chosen.
  ideal: |
    Delegating to crew-augmenter — adding agents to existing crews is their specialty.
  tags: [routing]
  threshold: 4
```

### Portability Strategy

- Start with single tool + single judge (kiro-cli + default LLM)
- Tool adapters from Phase 1 enable running same evals against different tools
- Judge backends are pluggable: swap LLM model, add code-based pre-checks, use multiple judges with majority vote
- Same eval definitions work across all combinations

### Design Decisions

- **One primary signal per eval** — unambiguous pass/fail for the judge
- **Automatic-fail is mandatory** — clear "this is wrong" signal reduces scoring variance
- **Threshold matches criticality** — 4 for correctness-critical, 3 for quality-oriented
- **Retry only on infrastructure failures** — bad responses are signal, not noise
- **Countable over subjective** — "mentions 3 of [list]" beats "describes thoroughly"

### Prior Art

- `agent-crews/scripts/eval-crew.py` — Python implementation with kiro-cli invocation + LLM judge
- `agent-crews/.crews/evals.yaml` — 46 eval definitions across 4 categories
- `agent-crews/docs/adr/0010-eval-harness-design.md` — design rationale
- `agent-crews/shared/skills/eval-criteria/SKILL.md` — authoring style guide (Anthropic best practices)

## Prior Art: Workspace Conventions (loosely held)

These patterns from agent-crews represent a starting point, not an authoritative design. They should inform but not constrain the final system.

### Observed Patterns

1. **Two-root workspace contract** — ephemeral (.scratch) + durable (.memory) with lifecycle rules
2. **Standardized handoff artifact** — HANDOFF.md with frontmatter (created_at, base_commit, handoff_key) and 5 required sections
3. **Tiered steering** — universal (all agents), orchestrator, worker — each tier gets always-loaded behavioral protocols
4. **Structured signaling** — DONE/PARTIAL/BLOCKED/FAILED with required fields (Task, Result, Evidence, Remaining, Assumptions)
5. **Sanity gate** — assumption register, rubber-stamp guard after N unconfirmed decisions
6. **Verification gate** — mandatory check workflow before claiming completion
7. **Conventions layer** — project-specific norms (git hosting, task runners, what "done" means)

### Open Questions

- Are two roots the right abstraction, or should there be more/fewer?
- Is the handoff format too rigid or too loose?
- Does tiered steering (universal/orchestrator/worker) map well to other tools?
- Which of these patterns are tool-specific vs. genuinely portable?
- What conventions exist in best_practices and ai-references that complement or contradict these?

### Source

- `agent-crews/.kiro/steering/` — tiered steering files
- `agent-crews/shared/templates/handoff.md` — handoff template
- `agent-crews/docs/workspace.md` — workspace contract docs
- `agent-crews/docs/adr/0013-standardized-handoff-artifact.md` — handoff ADR

## Proposed Categories (working list, open for revision)

Based on the inventory, these categories emerge from what actually exists across the three repos. They're organized by *what the artifact does*, not by which repo it came from.

### 1. Reasoning Modes
Prompt vocabulary keywords that activate specific thinking patterns. These are the atomic behavioral units.
- Examples: socratic, five-whys, pre-mortem, red-team, steel-man, inversion, blind-spot, deep-dive, zoom-out, cause-map, rubber-duck, feynman, prior-art, working-back, progressive, tracer, spike, minimal, idempotent, contract, blackbox, gherkin, task-graph, answer-first, handoff, bpappa, idiomatic, diagnose
- Source: best_practices/docs/practices/agent-prompting.md (27 keywords, tested across models)

### 2. Protocols
Step-by-step behavioral procedures that agents follow in specific situations. Deterministic sequences.
- Examples: verification (identify→run→read→verify→claim), completion (verify→git→signal→followups→handoff→notify→memory), git (commit timing, message format), troubleshooting, signaling (DONE/BLOCKED/FAILED formats)
- Source: agent-crews/shared/skills/*-protocol/, agent-crews/.kiro/steering/, nicobailon UCP specs

### 3. Skills (knowledge packs)
On-demand reference material loaded when relevant. Factual content + procedural guidance for a domain.
- Examples: eval-criteria, kiro-cli-schema, coding-principles, adr-authoring, writing-style, diataxis-classification, diagrams, readme-writing, tutorial-authoring
- Source: agent-crews/shared/skills/, best_practices/implementations/skills/, matt-skills, indydevdan skills, nicobailon skills

### 4. Practices (documented best practices)
Standalone reference documents capturing how to do something well. Research-backed, with rationale.
- Examples: commit-messages, pull-requests, testing-philosophy, agent-prompting, skill-agent-design, autonomy-delegation, evaluation-methodology, operational-patterns
- Source: best_practices/docs/practices/ (33 practices with bpappa research backing)

### 5. Agent Archetypes
Reusable agent role definitions with specific capabilities, tools, and behavioral boundaries.
- Examples: researcher, builder, tester, reviewer, planner, architect, verifier, documenter, lead/orchestrator, dispatcher
- Source: agent-crews/base/agents/ (76 agents), indydevdan agents (~70), best_practices agents (2)

### 6. Crew Patterns (team compositions)
Predefined groupings of agents organized for a domain of work, with routing and delegation rules.
- Examples: general, bug-fix, research, infrastructure, content, writing, hygiene, onboarding, rust
- Source: agent-crews/base/crews/ (12 crew definitions)

### 7. Workspace Conventions
File/folder structures, artifact formats, and lifecycle rules that enable agent coordination.
- Examples: .scratch/.memory roots, HANDOFF.md template, YAML frontmatter requirements, AGENTS.md format
- Source: agent-crews workspace contract, best_practices templates (AGENTS.md, ADR, PR)

### 8. Steering (behavioral guardrails)
Always-loaded behavioral constraints that shape how agents operate regardless of task.
- Examples: sanity gate (assumption register), reliability rules, delegation rules, conventions, ai-generation-hygiene
- Source: agent-crews/.kiro/steering/, indydevdan CLAUDE.md files, nicobailon steering

### 9. Prompts (invocable actions)
User-triggered actions that produce specific artifacts or initiate specific workflows.
- Examples: @handoff, @read-handoff, @grill-with-docs, @release, @thunderdome, /review, /research, /adr
- Source: agent-crews/shared/prompts/, best_practices/implementations/commands/

### 10. Evaluation Definitions
Declarative specs for testing agent behavior — both platform proofs and behavioral evals.
- Examples: assumption proofs (A1-A7), routing evals, scope evals, orchestration evals, execution evals, prompt vocabulary evals
- Source: agent-crews/.crews/evals.yaml, agent-crews/tests/assumptions/, best_practices/scripts/eval-prompt-vocabulary.sh

### Open Questions

- Should "protocols" and "steering" be merged? (Both shape behavior, but protocols are situational while steering is always-on)
- Are "reasoning modes" really a subset of "skills" or are they fundamentally different? (They're more like verbs than nouns)
- Where do "components" fit? (agent-crews components generate steering + optional subagents — they're a build-time concept, not a runtime one)
- Should there be a "research" category for the bpappa docs and investigation notes?
- Is "crew patterns" a category or just a composition of agents + routing rules?
- How do tool-specific adaptations (kiro-cli agent JSON vs Claude Code CLAUDE.md vs Pi config) factor in?
