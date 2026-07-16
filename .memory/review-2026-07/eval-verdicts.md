# R4 Eval Definition Review — 2026-07-16

75 active definitions reviewed in 4 subagent stages (detail with per-eval tables in activation.md, consolidation.md, effectiveness1.md, effectiveness2.md in this dir).

## Verdicts

| Category | Count | KEEP | FIX | RETIRE |
|----------|:-----:|:----:|:---:|:------:|
| activation-* | 24 | 24 | 0 | 0 |
| consolidation-* | 18 | 0 | 0 | **18** |
| effectiveness (batch 1) | 17 | 11 | 4 | 2 |
| effectiveness (batch 2) | 16 | 12 | 3 | 1 |
| **Total** | **75** | **47** | **7** | **21** |

## Executed: 21 retirements (75 → 54 active)

- 18 consolidation-* — one-shot merge validations; 11 have deleted baseline skills (can't run as designed), 5 were merge-rejected (purpose fulfilled), 2 speculative (no merge happened)
- part-b-enrichments — references non-existent skill `assumption-tracking`; violates one-signal-per-eval; superseded by focused evals
- content-neutrality-effectiveness — duplicates context-neutrality hypothesis AND has identical-conditions flaw
- cross-tool-planning — subsumed by cross-tool-planning-with-skills

## FIX list (7, not yet executed)

| Eval | Issue |
|------|-------|
| architecture-deepening-rubber-stamp | mode: multi-turn + turns: — unsupported by harness (input=null) — rewrite single-turn |
| agents-md-authoring-effectiveness | Task references "300-line AGENTS.md" absent from fixture |
| context-budget-effectiveness | Task references .scratch/research/set-handling.md absent from fixture |
| context-neutrality-effectiveness | Two conditions configured identically — delta measures noise |
| handoff-improves-continuity | Single task, overlaps handoff-decaying-resolution, no fixture |
| spec-validator-agent-effectiveness | Description claims subagent dispatch; conditions just add code-review skill |
| verification-protocol-improves-completion | Hello-world task has ceiling effect — delta 1.0 unreachable |

## Harness issues surfaced (→ R5)

1. **Activation defs leak into `run.sh --all`** — they lack tasks[].criteria (run-activation.sh is their harness) so they run with null criteria in the judged suite. Fix: filter `category: activation` in run.sh or move to subdirectory.
2. **threshold: field in activation defs is inert** — run-activation.sh never reads it. Cosmetic after the leak fix.
3. Two schema generations coexist (legacy `runs:` in 3 files vs `conditions:` in the rest) — both work; migrate for simplicity.
4. Tool-suffixed evals (-kiro/-codex) rely on operator memory — a `tool:` metadata key + harness warning would prevent cross-tool misruns.

## Judgment on activation evals

Keep as a fast judge-free regression suite for description edits (skills ship standalone without steering, so description-driven activation is load-bearing). Don't expand coverage for steering-reinforced skills — dual-run evals carry the real signal there.
