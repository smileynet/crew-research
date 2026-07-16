# Skill Review — Batch 8 (adr-authoring, deployment-safety, enforcement-hierarchy, image-handling, multi-agent-validation, vertical-slice-planning)

Reviewed: 2026-07-16. Line counts via `wc -l`. Tier membership via `grep compositions/tiers/*.yaml`. `mise run validate` currently passes (0 errors, 0 warnings) — but it only checks files referenced by compositions, so multi-agent-validation is invisible to it.

## Verdict Table

| Skill | Verdict | Lines | Issues | Recommended Fix |
|---|---|---:|---|---|
| adr-authoring | FIX | 84 | Storage path conflicts with project conventions; stale project-specific jargon; missing `metadata.practice` | Change storage path to `.memory/adr/`; remove warlock/BPAPPA references; add `practice: null` |
| deployment-safety | KEEP | 70 | None significant | — |
| enforcement-hierarchy | FIX | 80 | `practice: null` contradicts body's "Source practice" claim; references external repos users won't have | Either set the practice slug or drop the source-practice/origin lines |
| image-handling | KEEP | 33 | None. `metadata.tool: kiro-cli` present and correct | — |
| multi-agent-validation | FIX | 177 | **No YAML frontmatter at all**; 77 lines over budget; `references/tool-invocation.md` is an orphan (never linked); duplicates its own reference file inline; not in any tier | Add frontmatter; move Invocation Details to references/ and link it; add to `full` tier |
| vertical-slice-planning | FIX (minor) | 111 | 11 lines over budget; contains a stub section | Delete the "Step 1" stub; trims to ≤100 |

## Detail

### adr-authoring — FIX (84 lines)

1. **Purpose:** Guides when and how to write Architecture Decision Records using a MADR-lite template with lifecycle and storage conventions.
2. **Triggers:** Good — "Architecture Decision Records", "selecting tools, patterns, frameworks". Could add the literal token "ADR" to the description for stronger activation.
3. **Frontmatter:** Has `name`, `description`, `metadata.type: process`, `metadata.invocation: both`. Missing `metadata.practice` (AGENTS.md lists it as part of the frontmatter contract; every other skill in this batch that has frontmatter carries `practice: null`).
4. **Length:** 84 — within budget.
5. **References dir:** None — N/A.
6. **Duplication:** Minor overlap with `knowledge-management` steering ("ADRs only when all three: hard to reverse, surprising, real trade-off") — the steering has the *when*, this skill has the *how*; acceptable split but the "When to write" sections should not drift apart.
7. **Stale content:** Two problems.
   - **Storage path contradicts project conventions.** Skill says:
     > `- Path: docs/adrs/NNNN-short-title.md`
     but AGENTS.md, `knowledge-management` steering, and 8 other skills (grill-with-docs, handoff, init-project, project-audit, project-winddown, adopt-project, docs-audit, poc-workflow) all use `.memory/adr/NNNN-slug.md`. An agent following this skill files ADRs in the wrong place.
   - **Orphaned jargon from a prior project:**
     > `If a research artifact (warlock output, BPAPPA survey) informed this decision, link it`
     "warlock" and "BPAPPA" appear nowhere else in the repo; meaningless to deployed users.

**Fix:** Update Storage section to `.memory/adr/NNNN-slug.md`; replace the jargon line with a generic "If a research artifact informed this decision, link it"; add `practice: null`.

### deployment-safety — KEEP (70 lines)

1. **Purpose:** Enforces a pre/post verification protocol for deployments, with rollback triggers, canary rollout, and a mandatory explicit deploy verdict.
2. **Triggers:** Strong and distinctive — "rollback planning", "canary patterns", "deploying, provisioning infrastructure", "production state".
3. **Frontmatter:** Complete (`name`, `description`, `type: protocol`, `invocation: both`, `practice: null`).
4. **Length:** 70 — within budget.
5. **References dir:** None — N/A.
6. **Duplication:** Slight thematic overlap with `verification-protocol` steering (both demand evidence before claiming done), but the deploy-specific content (canary, rollback triggers, verdict) is unique. No merge needed.
7. **Stale:** None found. In `full` tier ✓.

### enforcement-hierarchy — FIX (80 lines)

1. **Purpose:** Decision guide for choosing the strongest available enforcement mechanism (tool permissions > automated validation > verification gate > steering) for agent behavior rules.
2. **Triggers:** Good — "enforcement mechanism", "agent constraints", "AGENTS.md", "enforce a new rule".
3. **Frontmatter:** Complete (`name`, `description`, `type: reference`, `invocation: both`, `practice: null`). Key ordering (metadata before name) is unusual but valid.
4. **Length:** 80 — within budget.
5. **References dir:** None — N/A.
6. **Duplication:** None with other skills; complements `skill-authoring`.
7. **Stale / inconsistency:** Frontmatter declares `practice: null`, but the body twice claims a source practice:
   > `Source practice: docs/practices/enforcement-hierarchy.md (in best_practices repo)`
   > `Origin: agent-crews/shared/steering/reliability.md`
   Per AGENTS.md cross-link rules, "skill declares `practice: slug`" — either the frontmatter or the body is wrong. Also, deployed users won't have "best_practices repo" or "agent-crews", so these pointers dead-end. (Same pattern exists in the deployed `ai-generation-hygiene` steering, so this is a systemic pattern worth a repo-wide sweep.)

**Fix:** Drop the two source/origin lines and the "## References" section, or set `practice:` to the real slug if the practice doc gets vendored in.

### image-handling — KEEP (33 lines)

1. **Purpose:** kiro-cli-specific workaround for analyzing images (dispatch a fresh non-interactive session) plus image size/format/token-cost constraints.
2. **Triggers:** Adequate — "process images", "kiro-cli sessions", "context compaction". Distinctive enough for its narrow scope.
3. **Frontmatter:** `name`, `description`, `type: reference`, `invocation: agent-only`, and — as required for tool-scoped steering — `tool: kiro-cli` ✓. No `practice` key (minor; consistent-ish with adr-authoring's gap).
4. **Length:** 33 — well within budget.
5. **References dir:** None — N/A.
6. **Duplication:** `multi-agent-validation` embeds the same dispatch snippet (`kiro-cli chat --no-interactive "Analyze /path/to/image.png - criteria"`). Acceptable — one is the canonical how-to, the other lists it as one validator among three — but a one-line cross-reference from multi-agent-validation would prevent drift.
7. **Stale:** None. In `basic` and `full` tiers ✓. Deployed copy at `~/.kiro/steering/image-handling.md` matches source.

### multi-agent-validation — FIX (177 lines) — brand new, 2026-07-15

1. **Purpose:** Validate artifacts (images, code, docs) by running 2-3 independent AI tools (codex, agy, kiro) as visual inspector / technical auditor / contextual judge and resolving disagreements.
2. **Triggers:** **Cannot be evaluated — there is no description.** The file has no frontmatter, so there is nothing for the activation mechanism to match on.
3. **Frontmatter:** **MISSING ENTIRELY.** The file begins:
   > `# Multi-Agent Validation`
   No `name`, no `description`, no `metadata.type`, no `metadata.invocation`. This violates the core authoring contract ("YAML frontmatter: name, description, metadata.type, metadata.invocation, metadata.practice"; "description field doubles as activation trigger"). As-is the skill can never activate by description and would fail any frontmatter-driven tooling.
4. **Length:** 177 — 77 over the 100-line budget, with no justification. The bulk of the overage is the "### Invocation Details" section (codex/agy/kiro command examples), which near-verbatim duplicates `references/tool-invocation.md`. That is exactly what progressive-loading references exist for.
5. **Orphan check:** **`references/tool-invocation.md` (115 lines) is an orphan** — the SKILL.md body never links to it. It also contains unique content not in SKILL.md (the `validate-render.sh` combined script, `--output-last-message`, `--add-dir`, `--dangerously-skip-permissions` flags), so it must be linked, not deleted.
6. **Duplication:** (a) Internal — Invocation Details vs its own references file, as above. (b) Cross-skill — the kiro dispatch snippet duplicates `image-handling` (see above). (c) The "Lessons Learned" tool-characteristics table partially overlaps `~/.kiro/steering/references/tool-limitations.md` themes (agy/codex behavior) but from a different angle; acceptable.
7. **Integration with conventions (per review note):** **Not integrated.** `grep multi-agent-validation compositions/ tools/` returns nothing — it's in no tier, so `mise run init` will never deploy it, and `mise run validate` never inspects it (which is why validation passes despite the missing frontmatter). No `practice` cross-link either.

**Fix (ordered):**
1. Add frontmatter, e.g. `name: multi-agent-validation`, description with triggers ("validate with multiple tools, second opinion, cross-check render, independent validation, codex, agy, visual inspection"), `metadata.type: workflow`, `metadata.invocation: both`, `practice: null`.
2. Replace the "Invocation Details" section with 2-3 line summaries + `See [references/tool-invocation.md](references/tool-invocation.md)`. This alone brings it under 100 lines.
3. Move the "Lessons Learned" tables to a second reference file if still over budget.
4. Add to `compositions/tiers/full.yaml` (fits the "full lifecycle" tier; too tool-dependent for basic).
5. Cross-reference `image-handling` for the kiro dispatch pattern instead of restating it.

### vertical-slice-planning — FIX minor (111 lines)

1. **Purpose:** Routes milestone planning by uncertainty level ("fog density") to spikes, tracer bullets, or vertical slices, each with a fill-in template.
2. **Triggers:** Excellent — explicit trigger list: "plan a milestone, what should I work on next, project feels stuck, too many things to do, replan, tracer bullet".
3. **Frontmatter:** Complete (`name`, `description`, `type: workflow`, `invocation: both`, `practice: null`).
4. **Length:** 111 — 11 over budget, no recorded justification. Content is dense and mostly earns its place, but there is dead weight:
   > `## Step 1: Assess Uncertainty`
   > ``
   > `What's blocking progress?`
   This "step" adds nothing — the routing table immediately below is the real step 1. Deleting it plus the surrounding blank lines and one `---` divider gets within budget without losing meaning.
5. **References dir:** None — N/A.
6. **Duplication:** Adjacent to `planning-cycles` (phased planning) and `plan-prereqs`, but this covers methodology *selection* which neither does. Distinct; no merge.
7. **Stale:** None. In `full` tier ✓.

**Fix:** Delete the Step 1 stub section; optionally fold "Plan Hygiene" sub-rules into the Anti-Patterns table for further headroom.

## Cross-Cutting Observations

- **`metadata.practice` inconsistency:** adr-authoring and image-handling omit the key; deployment-safety, enforcement-hierarchy, vertical-slice-planning carry `practice: null`. Standardize (probably: always present, `null` when none).
- **Dead external-repo pointers** ("best_practices repo", "agent-crews/...") appear in enforcement-hierarchy and in deployed steering; worth a repo-wide sweep.
- **Validation gap:** `mise run validate` cannot catch a skill that exists on disk but is absent from every composition (multi-agent-validation slipped through with no frontmatter). Consider a lint rule: every `atomics/skills/*/SKILL.md` must have valid frontmatter, and warn on skills in no tier.
