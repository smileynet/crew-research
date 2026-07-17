# Session-Log Skill & Tool Usage Analysis — 2026-07-17

Evidence-based usage report from kiro-cli session transcripts. Grounds tier composition and retirement decisions in field data instead of review judgment (ticket 10; validates R1 review assumptions).

## Method

- **Tool:** `tools/session-analyzer/skill_usage.py` (new; committed with this report)
- **Window:** 30 days, 595 kiro-cli sessions (`~/.kiro/sessions/cli/*.jsonl`), analyzed at commit 24d9691
- **Activation signals (per session, deduped):**
  1. `read`/`glob` of `.kiro/skills/<slug>/SKILL.md` (file-read activation)
  2. Native `SkillsTool` invocations (`"skillName"` in transcript)
  3. `/slug` user invocation in a prompt matching a deployed skill
- **Compliance signals:** string/regex heuristics (see caveats)

### Spike verdict (was: "can activation be detected from transcripts at all?")

**PASS.** Activation is detectable: 35/400 sampled sessions show skill-file reads, 21 show native SkillsTool calls. This resolves the handoff fog item.

## Caveats

- **Context-injection loads are invisible.** Steering and eager-loaded skills leave no per-turn marker — this measures *active* loads only. A skill with 0 activations may still shape behavior if its description was matched silently by context injection (kiro injects skill descriptions at session start).
- **crew-research dev sessions inflate counts** for skills being edited; file reads of `atomics/skills/<slug>` in crew-research cwds are filtered, but judge/eval sessions may still leak activations.
- **Compliance heuristics are approximate** (string matching, not semantic).
- Numbers below count *sessions with ≥1 activation*, not total loads.

## Findings

### Skill activations (global-tier skills, 30d / 595 sessions)

| Band | Skills (sessions) |
|------|-------------------|
| High (≥5) | code-review (19), handoff (11), spec-driven-development (6), grill-with-docs (6), research-methodology (5), writing-style (5), script-authoring (5), read-handoff (5) |
| Medium (2-4) | deployment-safety (4), skill-authoring (4), diagrams (3), presentation-writing (3), readme-writing (3), project-audit (3), changelog-discipline (3), research-output (3), testing-guide (3), cheatsheet (2), docs-audit (2), adopt-project (2), init-project (2), plan-prereqs (2), architecture-deepening (2), agents-md-authoring (2), adr-authoring (2), recall (2), ticket-planning (2), prototype-protocol (2) |
| Low (1) | tutorial-authoring, enforcement-hierarchy, git-protocol, study-reference, feedback-loop-debugging, project-winddown, eval-criteria, planning-cycles, study-all-references, project-cleanup, vertical-slice-planning, ux-walkthrough |
| **Never (0)** | **multi-agent-validation** |

Project-level skills show heavy use in their homes (pipeline-troubleshooting 12, ecs-gpu-deploy 12, comfyui-* 19 combined) — the three-tier model is working as designed.

### Tool usage (30d totals)

| Tool | Count |
|------|-------|
| recall CLI (search/add/prime/import/ingest) | 1,908 |
| web_search | 1,300 |
| subagent dispatch | 206 |
| knowledge tool | 20 |

### Steering compliance

| Signal | Rate | Reading |
|--------|------|---------|
| History questions answered with `recall search` first | 60/284 (21%) | ⚠️ recall-check steering under-followed — most "what did we decide" moments don't trigger a search |
| Eval runs using nohup/setsid pattern | 4/11 (36%) | ⚠️ eval-execution steering under-followed (2 of the misses predate the steering) |
| Sessions touching HANDOFF.md | 107/595 (18%) | Consistent with handoff being end-of-arc, not every session |

## Recommendations

1. **multi-agent-validation:** only never-activated global skill — explained by its missing frontmatter until 2026-07-16 (ticket 01) and 142-line body until today (ticket 03). Re-measure in 30 days before retirement judgment.
2. **planning-cycles (1 activation in 30d)** despite being a flagship skill: its trigger space overlaps spec-driven-development (6) and grill (6), which win the matches. Candidate: merge review in next tier revision.
3. **recall-check steering** needs a stronger gate (21% compliance): consider moving the trigger list into the always-on prime output, or an eval measuring the miss pattern.
4. **eval-execution nohup compliance (36%)** is now also mitigated mechanically: runs launched with setsid survive session kills (learned the hard way in ticket 12).
5. **Low-band skills (1 activation)** are mostly user-invoked utilities (project-winddown, study-all-references) — expected shape, no action.
6. **No retirement recommendations from this window** — every deployed skill except multi-agent-validation showed field usage.

## Reproduce

```bash
python3 tools/session-analyzer/skill_usage.py --days 30 --output usage.json
```
