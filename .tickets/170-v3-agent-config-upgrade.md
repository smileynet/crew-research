---
id: "170"
title: "Proof/eval agent configs need v3 upgrade — v3 ignores v2 resources/, falls back to default agent"
status: open
blocked_by: []
tags: [kiro-v3]
---

# Proof/eval agent configs need v3 upgrade

## Finding (during ticket 124 e2e, 2026-10-02, kiro-cli 2.27.0)

When a proof/eval invokes a generated v2-format agent config under `--agent-engine v3`,
kiro-cli emits:
```
[warn] agent "file-resource-agent" needs upgrading for this agent engine,
using "default" — run /upgrade-agent to convert file-resource-agent.json
```
and **falls back to the default agent** — so the agent's `resources` (e.g.
`file://canary.md` eager context) are NOT pre-loaded. Proof A4
(file-resource-always-loaded) fails its `expect.present` text grading on v3 for this
reason: the agent never saw the eager file, correctly reports it doesn't have the
canary. This is NOT a grading bug (ticket 124's stream-json path works) and NOT an
engine-selector bug (ticket 126) — it's the **v2→v3 agent-config format gap**
(documented: "V2 agent configs don't load under V3"; `.scratch/research/t168/02-trust-apikey.md`
open question 5, `.scratch/research/kiro-v3-2026-10/02-config-trust.md`).

## Scope

The proof/eval harnesses GENERATE agent configs from adapter templates:
- `tools/proofs/adapters/kiro-cli.yaml` `agent.template` (JSON: name/description/tools/
  allowedTools/resources/prompt) — the v2 shape.
- `tools/evals/harness/` deploys agents similarly.

Research 02-config-trust found v3 agent JSON is **backward-compatible for basic fields**
but the `resources` (file://, skill://) binding is where the v2 shape falls short on v3
(hence the "needs upgrading" warning + default fallback). Options to evaluate:
1. Generate v3-native agent configs (confirm the exact field/format `/upgrade-agent`
   produces — likely the `resources` array shape or the new optional fields from
   02-config-trust: permissions, expanded resources with skill://+knowledgeBase).
2. Run `kiro-cli agent migrate` / `/upgrade-agent` on generated configs before invoke
   (adds a step; `/upgrade-agent` is interactive — `agent migrate` is the CLI path but
   is "potentially destructive to global agents", so scope it to the workdir).
3. Keep v2 agent configs + v2 engine for agent-based proofs; only use v3 for
   agentless/skill-based proofs until configs are upgraded.

## Impact

- Agent-based proofs (those with an `agents:` fixture + `resources`) cannot run on v3
  until configs are v3-compatible. Agentless/skill proofs are unaffected (skills
  auto-discover on v3 — confirmed by spike 168's A/B).
- Blocks full v3 adoption of the proof/eval suite, but NOT the stream-json grading
  (124) or the engine selector (126), which both work.

## Acceptance criteria

- [ ] Determine the exact v3-compatible agent-config format (diff a `/upgrade-agent` output vs the current template)
- [ ] Update `adapters/kiro-cli.yaml` `agent.template` (and eval agent deploy) to emit v3-compatible configs, OR add a workdir-scoped migrate step
- [ ] Agent-based proof (e.g. A4) passes on `--agent-engine v3` with resources actually pre-loaded (no "needs upgrading" warning, no default fallback)
- [ ] v2 path unchanged (template still works on v2 engine)
- [ ] No global agent dir mutated (migrate scoped to workdir KIRO_HOME)
