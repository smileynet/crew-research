# Plan: Project-Wide Deep Dive Review

**Created:** 2026-07-16
**Goal:** Every skill has a clear purpose, is well organized, and follows best practices. Evals measure what matters. All project areas audited for health and relevance.

## Project Areas Inventory

| Area | Contents | Review status |
|------|----------|:-------------:|
| `atomics/skills/` | 53 skills | ⬜ Ticket R1 |
| `atomics/eager-context/` | 7 always-on modules | ⬜ Ticket R2 |
| `compositions/tiers/` | basic, full | ⬜ Ticket R3 |
| `compositions/agent-archetypes/` | 9 archetypes | ⬜ Ticket R3 |
| `compositions/crew-patterns/` | 9 patterns | ⬜ Ticket R3 |
| `tools/evals/` | 75 active definitions + harness | ⬜ Ticket R4, R5 |
| `tools/generator/` | init, doctor, catalog, generate | ⬜ Ticket R6 |
| `tools/proofs/` | Platform assumption tests | ⬜ Ticket R6 |
| `tools/lint/` | Cross-link validation | ⬜ Ticket R6 |
| `tools/recall/` | Extension CLI | ⬜ Ticket R6 |
| `tools/session-analyzer/` | Transcript parsing | ⬜ Ticket R6 |
| `tools/okf-bundle/` | OKF bundle generation | ⬜ Ticket R6 |
| `docs/development/` | 25 research docs | ⬜ Ticket R7 |
| `.memory/` | 8 ADRs, 19 specs | ⬜ Ticket R7 |

---

## Tickets

### R1: Skill deep-dive review (53 skills)

**Goal:** Every skill has (a) clear single purpose, (b) correct frontmatter, (c) <100 lines with references/ overflow, (d) distinctive activation description, (e) no overlap with another skill.

**Method:** Batch review via subagents (5-8 skills per stage, file-reading tasks — high reliability). Each stage produces a structured verdict per skill: KEEP / FIX (what) / MERGE (into what) / RETIRE (why).

**Checklist per skill:**
- [ ] Purpose statable in one sentence
- [ ] Description has distinctive trigger keywords (not generic)
- [ ] Frontmatter: name, description, metadata.type, metadata.invocation present
- [ ] <100 lines (or justified)
- [ ] references/ files actually referenced from SKILL.md body (no orphans)
- [ ] No content duplication with steering or other skills
- [ ] Examples/commands are current (not stale post-consolidation)

**Deliverable:** `.scratch/skill-review/verdicts.md` with per-skill table + fix list.

**Est:** 7-8 subagent stages + synthesis. ~2 hours.

### R2: Eager-context audit

**Goal:** Each always-on module earns its context cost.

- [ ] Review 7 modules: autonomy, delegation, verification, workspace, research-dispatch-mandate, permissions.yaml, hooks/
- [ ] Check: is each still deployed by generator? (some may be orphaned post-ADR-0008)
- [ ] Check overlap with tier steering (e.g., verification.md vs verification-protocol skill)
- [ ] Verify hooks/ is used by anything

**Deliverable:** Keep/retire verdict per module.

**Est:** 30 min, direct review (small corpus).

### R3: Compositions audit

**Goal:** Tiers, archetypes, and crew-patterns reference only existing skills and match post-consolidation reality.

- [ ] Validate all skill references resolve (mise run validate covers some)
- [ ] Check agent-archetypes: are they used by anything? (9 files — dispatcher, implementer, etc.)
- [ ] Check crew-patterns: same question (9 files)
- [ ] If archetypes/patterns are aspirational-but-unused, decide: document as future work or remove
- [ ] Verify tier extension blocks are consistent between basic and full

**Deliverable:** Reference integrity report + keep/remove decision for archetypes and crew-patterns.

**Est:** 45 min.

### R4: Eval definition review (75 active)

**Goal:** Every eval measures a behavior we care about, uses the correct format, and has a defensible threshold.

- [ ] Categorize: activation (24), effectiveness, consolidation (18), other
- [ ] Flag evals using unsupported features (multi-turn `turns:`, `steering_override`) — convert or retire
- [ ] Flag evals for retired/merged skills that reference old skill names
- [ ] Verify threshold + delta_threshold match the eval's intent (variance-reduction vs lift)
- [ ] Check consolidation-* evals: post-consolidation, are they one-shot (done) or regression guards (keep)?
- [ ] Confirm judge criteria follow eval-criteria style guide

**Deliverable:** Per-eval verdict table; retire list; fix list.

**Est:** 4-5 subagent stages (file reading). ~1.5 hours.

### R5: Eval harness review

**Goal:** Harness correctness and maintainability after the isolation fix.

- [ ] Review run.sh end-to-end (534+ lines): flag dead code, error handling gaps
- [ ] Document supported definition schema (input vs turns, conditions, thresholds) — currently implicit
- [ ] Add multi-turn support OR document as unsupported (2 evals retired for this)
- [ ] Fix shared outputs/ dir collision (all evals in a run write to same outputs/ with task indexes — filenames don't include eval name)
- [ ] Add `--dry-run` validation mode that checks all definitions parse correctly
- [ ] Verify consensus judging handles judge failures gracefully

**Deliverable:** Fixed harness + `tools/evals/README.md` schema documentation.

**Est:** 2-3 hours direct work.

### R6: Tooling audit (generator, proofs, lint, recall, session-analyzer, okf-bundle)

**Goal:** Each tool works, is documented, and is still needed.

- [ ] generator: init.sh reviewed post-ADR-0008 (plugin code paths fully removed?)
- [ ] doctor.sh: does it check extensions? eval steering? cron?
- [ ] proofs: harness still runs? results current?
- [ ] lint: cross-link checks match current skill structure?
- [ ] recall CLI: spike/ dir cleanup, pyproject current?
- [ ] session-analyzer: still used? parse.py works against current session format?
- [ ] okf-bundle: still needed? documented?

**Deliverable:** Health report per tool; removal proposals for dead tooling.

**Est:** 1.5 hours, mix of direct + subagent.

### R7: Knowledge cleanup (docs/development, .memory)

**Goal:** Research history is navigable; stale specs are archived.

- [ ] docs/development: 25 files — add an index README categorizing by topic and status (current/historical)
- [ ] .memory/specs: 19 specs — mark each as ACTIVE / DONE / SUPERSEDED in frontmatter
- [ ] ADRs: verify 0008 status updated from Proposed → Accepted (it shipped)
- [ ] CONTEXT.md: current with post-consolidation terms (extensions, tiers, etc.)

**Deliverable:** Indexed docs, statused specs, updated ADR statuses.

**Est:** 1 hour.

### R8: Workspace hygiene (quick win)

**Goal:** Remove accumulated junk.

- [ ] Untracked files at repo root: `debounce.ts`, `debounce-final.ts`, `fixed-code.js` (eval artifacts leaked into repo root — delete)
- [ ] Untracked: `tools/evals/experiments/bedrock-model-family-comparison.yaml`, `tools/evals/harness/run-model-comparison.sh`, `tools/proofs/adapters/closecode.yaml` — decide: commit or delete
- [ ] README.md at repo root describes "Debounce Function" — completely wrong, needs rewrite for crew-research
- [ ] Check .gitignore covers eval workdir leakage

**Deliverable:** Clean git status; correct README.

**Est:** 30 min.

---

## Sequencing

```
R8 (hygiene, quick) → R1 (skills) → R2+R3 (context/compositions, small) 
→ R4 (eval definitions) → R5 (harness) → R6 (tooling) → R7 (knowledge)
```

R1 informs R4 (skill verdicts determine which evals stay relevant).
R5 should wait for the current eval run to finish (avoid changing harness mid-run).

## Current Status Snapshot (2026-07-16)

- Full eval suite running since 2026-07-15 12:56 UTC: 83/105 complete, 27 pass / 57 fail
  - Failure count inflated by: 28 retired evals included (fixed), activation threshold 4.0 (fixed → 3.5), 2 broken multi-turn evals (fixed/retired)
  - Post-fix estimate: ~36 pass / ~39 fail equivalent on the new 75-eval suite
- Harness isolation fix shipped (baselines now clean)
- Skill consolidation complete (64 → 53 dirs)
- Extensions model shipped (ADR 0008)
- README.md is wrong (describes a debounce utility, not this project)
