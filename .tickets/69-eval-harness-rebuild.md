---
id: "69"
title: "Explore: eval harness architecture rebuild (compiled orchestrator)"
status: open
blocked_by: []
---

# Explore: eval harness architecture rebuild (compiled orchestrator)

## What to build

**Exploration ticket — deliverable is architecture decision + migration plan.**

Evaluate rebuilding the eval harness (`tools/evals/harness/run.sh`, 1000+ lines of bash)
as a compiled orchestrator. The harness has accumulated 6 incidents (live-edit crash,
leaked files, process-group kills, dry-run hang, shared-dir collisions, codex judge
death) traceable to bash limitations: no type safety, no real process management,
fragile quoting, MSYS2 performance cliffs.

**This tool may stay in crew-research** (evals test skills — tight coupling), but its
IMPLEMENTATION should be a compiled binary, not a bash script.

## Research (completed 2026-07-28)

Findings in `.scratch/research/`:
- `eval-harness-rebuild.md` — framework comparison, language choice, storage, architecture
- `rust-vs-go-cli.md` — Go recommended for eval orchestrator (goroutines, fast compile)

## Key questions

1. **Language:** Go (research recommendation: goroutines for parallel judge dispatch,
   fast compile for iteration, subprocess management) vs Rust (consistency with tkt/recall)?
2. **Keep in crew-research or extract?** Arguments for keeping: eval defs reference skill
   paths directly, tight development loop (edit skill → run eval). Arguments for extract:
   clean binary, separate CI, installable tool.
3. **Architecture (from research):**
   - Three-layer: Orchestrator → Agent subprocess → Judge subprocess
   - SQLite for result storage (replaces scores.jsonl — queryable, atomic)
   - Content-hash staleness tracking (already designed: ticket 33 identity hashes)
   - Proper process isolation (temp workdirs, process groups, timeout management)
4. **Migration path:** Can the new tool read existing YAML definitions unchanged? Can it
   produce scores.jsonl for backward compat while migrating to SQLite?
5. **What to steal from Inspect AI:** Task/Solver/Scorer primitives, sandbox isolation,
   log viewer, concurrent evaluation, sample limits.
6. **Bash incidents to address:** live-edit crash (script re-read), leaked files (no
   workdir isolation), process-group death (no setsid equiv), MSYS2 performance (fork
   overhead), shared output dir collisions.

## Challenge existing decisions

- **YAML definitions:** Are they the right format? Or should definitions be code
  (Python/Rust) like Inspect AI's `@task` decorator?
- **Dual-run with/without skill:** Is this the right methodology, or should we move to
  single-run with criteria-based scoring (like Inspect)?
- **Consensus judging:** Is multi-model judging worth its cost? What does the data show?
- **Trial repetition:** Is 3 trials sufficient? What's the actual inter-trial variance?

## Acceptance criteria

- [ ] Decision: keep in crew-research vs extract (with reasoning)
- [ ] Decision: Go vs Rust for the orchestrator (with reasoning)
- [ ] Architecture sketch: modules, subprocess management, storage, staleness
- [ ] Definition format decision: keep YAML or migrate to code-based
- [ ] Migration plan: phases to move from bash → compiled without losing run history
- [ ] Session/usage audit: which harness features are actually used, which are dead code
- [ ] Incident post-mortem: which of the 6 bash incidents are architecturally prevented

## Ordering rationale

Blocked by ticket 67 (tkt extraction): tkt is the simplest rebuild and proves the
Rust toolchain + cross-platform distribution + test strategy. Lessons learned there
inform whether to use Rust or Go for the eval orchestrator (if consistency wins → Rust;
if goroutines/speed-of-iteration wins → Go).

## Out of scope

- Full implementation
- Changing the dual-run eval methodology (challenge it, but changing it is a separate decision)
- Rebuilding the activation eval harness (simpler, may not need rebuild)
