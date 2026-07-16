# Development Docs Index

Research history for crew-research: eval methodology, experiment records, plans, and reviews.
Status: **CURRENT** = still guides work · **HISTORICAL** = completed experiment or record.

## Eval Methodology

| File | Status | Summary |
|------|--------|---------|
| [experiment-methodology.md](experiment-methodology.md) | CURRENT | Standard process for measuring skill value via controlled dual-run comparison (skill present vs absent, 3 trials, LLM judge). |

## Experiment Results

| File | Status | Summary |
|------|--------|---------|
| [experiment-results-summary.md](experiment-results-summary.md) | HISTORICAL | Rollup of all E7–E16 experiments: system validated, with per-experiment verdicts and key findings. |
| [eval-findings-v1.md](eval-findings-v1.md) | HISTORICAL | First dual-run evaluation of 5 skills — all showed large deltas, later found inflated by empty-workspace conditions. |
| [experiment-1-activation-results.md](experiment-1-activation-results.md) | HISTORICAL | Activation reliability across 50 tasks: 68% recall, 0% false positives, 84% accuracy. |
| [phase-2-grounded-results.md](phase-2-grounded-results.md) | HISTORICAL | Re-ran v1 evals in real project workspaces; deltas shrank dramatically, showing v1 results were inflated. |
| [phase-7-experiment-results.md](phase-7-experiment-results.md) | HISTORICAL | Token efficiency experiments — counterintuitively, loading more skills reduced tokens and duration. |
| [phase-10-e2e-results.md](phase-10-e2e-results.md) | HISTORICAL | End-to-end validation of multi-agent workflows and crews on a real TypeScript project (E8/E9 pass). |
| [e7-activation-sweep-results.md](e7-activation-sweep-results.md) | HISTORICAL | Activation sweep of all 33 skills: 81% recall, 88% accuracy; identified 3 failing skills. |
| [e10-eager-context-results.md](e10-eager-context-results.md) | HISTORICAL | Eager-context steering showed no measurable delta in single-turn mode — revealed a harness limitation. |
| [e15-cross-skill-linking-results.md](e15-cross-skill-linking-results.md) | HISTORICAL | Cross-skill links do NOT trigger progressive loading in kiro-cli; strategy ruled out. |
| [e16-description-rewriting-results.md](e16-description-rewriting-results.md) | HISTORICAL | Description rewriting fixed diagrams activation (0%→100%) but not verification-protocol; led to eager-loading decision. |
| [eval-results-2026-06-14.md](eval-results-2026-06-14.md) | HISTORICAL | Validated the steering-pointer mechanism (+1.34 delta, zero false activation) — basis for ADR 0002 tier 3. |
| [recall-experiment-results.md](recall-experiment-results.md) | HISTORICAL | Recall extension shows strong signal on decision-retrieval tasks (+1.5 avg); aggregate dragged down by eval infra failures. |
| [cross-tool-comparison-results.md](cross-tool-comparison-results.md) | HISTORICAL | kiro-cli vs codex vs agy capability comparison — competitive on small projects, kiro-cli degrades least at scale. |
| [spike-findings.md](spike-findings.md) | HISTORICAL | Answers to spikes S1–S5 (skills-vs-prompts parity, frontmatter tolerance, etc.) — no blockers found. |

## Plans / Proposals

| File | Status | Summary |
|------|--------|---------|
| [consolidation-eval-plan.md](consolidation-eval-plan.md) | CURRENT | Plan to measure whether merged skills retain effectiveness when moved into a parent skill's references/. |
| [post-deployment-analysis.md](post-deployment-analysis.md) | CURRENT | Open follow-up questions to evaluate after sustained real-world use (steering placement, skill effectiveness). |
| [task-graph.md](task-graph.md) | CURRENT | Dependency graph of project phases and spikes; S1–S5 complete, S6 (cross-tool proof abstraction) still open. |
| [eval-improvement-plan.md](eval-improvement-plan.md) | HISTORICAL | Phased plan to fix v1 eval limitations (activation verification, grounded workspaces) — since executed. |
| [eval-experiments-plan.md](eval-experiments-plan.md) | HISTORICAL | Follow-up experiment designs (activation reliability, token efficiency, etc.) — experiments since run. |
| [experiment-coverage-proposal.md](experiment-coverage-proposal.md) | HISTORICAL | Gap analysis of untested project areas with proposed experiments E7–E16 — since executed. |
| [phase-9-proposal.md](phase-9-proposal.md) | HISTORICAL | Proposal to expand from 4 to 8 crew patterns (infrastructure, content, review, onboarding). |
| [spike-plans.md](spike-plans.md) | HISTORICAL | Experiment designs for spikes S1–S5 (prompt/skill parity, frontmatter tolerance) — resolved in spike-findings. |
| [cross-skill-linking-research.md](cross-skill-linking-research.md) | HISTORICAL | Hypothesis and prior-art research for cross-skill linking as an activation fix — disproven by E15. |

## Session Reviews

| File | Status | Summary |
|------|--------|---------|
| [session-review-2026-06-14.md](session-review-2026-06-14.md) | HISTORICAL | Weekly review of Jun 8–14 sessions: 50 sessions, 8 projects, tool-usage breakdown. |

## Other

| File | Status | Summary |
|------|--------|---------|
| [inventory.md](inventory.md) | HISTORICAL | Raw inventory snapshot of all behavioral artifacts (93 agents, skills, prompts) across the three reference repos. |
