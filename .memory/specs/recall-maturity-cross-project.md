---
type: specification
title: "Recall Maturity + Cross-Project Knowledge Spec"
status: superseded
---

# Spec: Recall Maturity + Cross-Project Knowledge

**Status:** Ready
**Date:** 2026-07-04
**Depends on:** recall import (shipped), OKF frontmatter (shipped), recall-check eager-context (shipped)

---

## Objective

Two tracks, one goal: make recall a reliable, multi-project knowledge layer that agents actually use without prompting.

**Track A (Maturity):** Prove the activation fix works, integrate import into the deployment flow, harden the CLI.

**Track B (Cross-Project):** Import knowledge from real projects, validate retrieval at scale, establish the pattern for multi-project recall as a daily workflow.

---

## Track A: Recall Maturity

### A1. Validate activation fix

The `recall-check` eager-context module (deployed as steering) should bypass the skill activation bottleneck. Prove it.

**Method:**
1. Deploy recall plugin to a fresh temp workspace (including the new `recall-check.md` steering)
2. Re-run `activation-recall` eval tasks as manual kiro-cli prompts with steering present
3. Measure: does the agent call `recall search` when asked about past decisions?

**Success:** Agent calls `recall search` on ≥4/5 positive prompts (vs 0/5 before).

**If it fails:** The eager-context is too subtle. Escalate to a stronger steering rule:
- Option 1: Add to `verification-protocol` — "Before answering about past work, run recall search"
- Option 2: Inject via `recall prime` output (already in agent context at session start)

### A2. Integrate import into plugin install

When a user runs `mise run init -- --plugin recall`, auto-import `.memory/` if it exists.

**Changes:**
- `tools/generator/init.sh`: after deploying recall plugin files, run `recall import .memory/ --wing <project>` if `.memory/` exists
- Add `recall import` to `mise run doctor` checks — warn if `.memory/` exists but isn't imported

**Acceptance:**
- `mise run init -- --plugin recall` on a project with `.memory/` → prints "Imported N files"
- `mise run doctor` on a project with `.memory/` and empty recall DB → warns "run recall import"

### A3. Recall help text and docs

- `recall import --help` should show usage examples
- Update README plugin section with import workflow
- Add `recall import` to the cheatsheet skill

### A4. Multi-turn eval via Codex SDK

The `recall-improves-continuity` eval fails because the single-turn model scores 4.1/5 without recall. The eval needs multi-turn scenarios where session 1 makes a decision and session 2 must recall it.

**Method:**
- Write a 2-turn eval definition using Codex SDK `turns:` format
- Turn 1: "Let's use field-relative yards for coordinates because [reasons]" → agent acknowledges
- Turn 2 (new session): "What coordinate system should we use?" → agent must recall, not guess

**Success:** Multi-turn recall eval shows delta ≥1.0 (with skill vs without).

---

## Track B: Cross-Project Knowledge

### B1. Import real project knowledge

Import `.memory/` from the top projects in `~/code`:

| Project | Files | Wing | Value |
|---------|-------|------|-------|
| lacrosse-bosse-platform | 140 | lacrosse_bosse_platform | Largest corpus, deep specs |
| sci-phoenix | 26 | sci_phoenix | Clean structure, diverse content |
| asset-production | 69 | asset_production | Different domain (3D art) |
| shadowrun-sega | 31 | shadowrun_sega | Hardware docs, frontmatter |
| pixelrig | 21 | pixelrig | Embedded systems |

**Commands:**
```bash
recall import ~/code/lacrosse-bosse-platform/.memory/ --wing lacrosse_bosse_platform
recall import ~/code/sci-phoenix/.memory/ --wing sci_phoenix
recall import ~/code/asset-production/.memory/ --wing asset_production
recall import ~/code/shadowrun-sega/.memory/ --wing shadowrun_sega
recall import ~/code/pixelrig/.memory/ --wing pixelrig
```

**Acceptance:** `recall status` shows all wings with correct chunk counts.

### B2. Cross-project retrieval eval

Extend the existing `multi-project-import-eval.py` to test against real project data (not just fixtures).

**New queries (testing real .memory/ content):**

| Query | Expected wing | Expected file |
|-------|--------------|---------------|
| "How does PracticeExecution handle mirroring?" | lacrosse_bosse_platform | specs/ |
| "What is the PMachine bytecode VM?" | sci_phoenix | CONTEXT.md |
| "How does QUASAR quality scoring work?" | asset_production | CONTEXT.md |
| "What is the VBlank cycling mechanism?" | shadowrun_sega | CONTEXT.md |
| "What MCU does PixelRig use?" | pixelrig | CONTEXT.md |

**Success:** recall@3 ≥ 0.8 across all projects, wing_precision = 1.0.

### B3. Scale validation

After importing all 5 projects (~287 total files, est. ~2000 chunks), validate:

1. **Import speed**: all imports complete in < 60s total
2. **Search latency**: `recall search` returns in < 200ms (after embedding model warm)
3. **Wing isolation**: unscoped search still returns correct wing for domain-specific queries
4. **Storage**: DB size stays under 50MB

### B4. Daily workflow integration

Establish the pattern: when switching to a project, recall already has its knowledge indexed.

**Workflow:**
1. `cd ~/code/project-name`
2. `recall prime` → shows recent memories + relevant knowledge from `.memory/`
3. Work normally — recall-check steering triggers search on past-decision questions
4. `recall ingest ~/.kiro/sessions/` → auto-imports `.memory/` alongside sessions

**Validation:** Use this workflow for 1 week, then session-review to measure:
- How often does recall-check trigger correctly? (target: ≥80% of applicable prompts)
- Does imported knowledge appear in recall results? (target: ≥50% of searches hit imported content)
- Does the agent cite recall sources? (target: ≥60% of recall-informed answers cite source_file)

---

## Ordering

```
Phase 1 (prove activation):  A1                          [30 min]
Phase 2 (cross-project):     B1 → B2 → B3               [45 min]
Phase 3 (integration):       A2 → A3                     [30 min]
Phase 4 (multi-turn):        A4                          [60 min]
Phase 5 (daily workflow):    B4                           [ongoing]
```

Phase 1 is the critical path — if activation doesn't work, everything else is irrelevant because the agent won't use recall autonomously. If A1 fails, pivot to stronger enforcement before proceeding.

Phases 2-3 can run in parallel.
Phase 4 requires Codex SDK (separate tool).
Phase 5 is observational (run for 1 week then evaluate).

---

## Non-Goals

- ~~Graph/link extraction~~ — no use case demonstrated yet
- ~~Cross-project recall search (searching all wings at once)~~ — already works by default (no --wing = all)
- ~~OKF full conformance~~ — we adopt type/title only. Tags, timestamps, resources are overhead without proven value.
- ~~ChromaDB or vector DB migration~~ — SQLite scales fine for these sizes
- ~~Automated ingestion daemon~~ — manual `recall ingest` is sufficient; auto-import on ingest covers .memory/

---

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Eager-context recall-check still doesn't trigger | High — agent never uses recall | Escalate to verification-protocol integration or prime injection |
| Large imports (140 files) slow down search | Medium — latency | Profile; if needed, add LIMIT to SQL before vector scoring |
| Wing derivation produces bad names | Low — cosmetic | --wing override exists; standardize in import docs |
| Multi-turn eval requires Codex SDK setup | Medium — blocks A4 | A4 is independent; defer if SDK not ready |

---

## Acceptance Criteria (overall)

1. Agent autonomously calls `recall search` when asked about past decisions (≥4/5 positive prompts)
2. 5 real projects imported, recall@3 ≥ 0.8 on cross-project queries
3. `mise run init -- --plugin recall` auto-imports .memory/
4. Multi-turn eval shows delta ≥1.0 for recall skill
5. DB stays under 50MB after all imports
