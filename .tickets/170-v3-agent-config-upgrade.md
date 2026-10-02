---
id: "170"
title: "Proof/eval agent configs need v3 upgrade — v3 ignores v2 resources/, falls back to default agent"
status: done
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

## Findings (2026-10-02, empirical on kiro-cli 2.27.0)

Root cause of the "needs upgrading → using default" fallback: v3 recognizes a config
as v3-native by the presence of the **`permissions`** field. `kiro-cli agent validate`
on the v2-shape config returns NO error (it's structurally valid) — the warning is
purely the engine deciding the config predates v3 and routing to the default agent,
which drops the named agent's `resources` (eager files). Minimal-fix experiment:
- `+ "permissions": {"rules": []}` alone → **0 upgrade warnings**, named agent loads resources.
- `+ mcpServers + toolsSettings + includeMcpJson` WITHOUT permissions → still warns.
So the fix is a single field. v3-canonical (`agent create`) also adds mcpServers/
toolAliases/toolsSettings/includeMcpJson/model/permissions, but only `permissions` is
needed to stop the fallback. Backward-compatible: v2 engine runs clean with the field present.

Fix applied to the proof harness's **inline agent JSON** (`run.sh deploy_agent`, the
actual generator) AND the adapter `agent.template` (documentation/parity). Eval harness
does not generate kiro-cli agent JSON the same way (no inline agent heredoc found); if a
future eval path adds one, apply the same field.

## Acceptance criteria

- [x] Determined the exact v3-recognition requirement: the `permissions` field (minimal `{"rules":[]}`); `agent validate` passes on v2-shape, fallback is engine-side
- [x] Updated proof `run.sh deploy_agent` inline JSON + `adapters/kiro-cli.yaml agent.template` to emit `"permissions": {"rules": []}`
- [x] Agent-based proofs pass on v3 with resources pre-loaded: **A4 and A5 PASS on `PROOF_ENGINE=v3 PROOF_OUTPUT_FORMAT=stream-json`** (no "needs upgrading" warning, canary loaded by the named agent). (A4 on v3 WITHOUT stream-json still fails only at the log_check stage = ticket 124's known limit; its text grading passes.)
- [x] v2 path unchanged (A4 default PASS; `permissions` field is backward-compatible on v2)
- [x] No global agent dir mutated (configs are generated per-proof under the workdir `KIRO_HOME`; no `agent migrate`/`/upgrade-agent` on global)

## Observation (out of scope, not a 170 regression)

Proof **A3** (skill-absence) does not complete on the v3 path within the adapter's
90s timeout (produces no verdict), while it passes on v2. A3's agent has no special
resources, so this is unrelated to the permissions fix — it looks like v3's slower cold
start vs the adapter `invoke.timeout: 90`. If v3 becomes the proof default, the adapter
timeout likely needs raising for v3. Noted for a future ticket, not fixed here.

## Resolution (2026-10-02)

v3 routes v2-shape agent configs to the DEFAULT agent ('needs upgrading' warning), which drops the named agent's resources/ (eager files) — the cause of A4/A5 failing on v3. Fix: add the permissions field ({rules:[]}) to generated agent JSON — v3 recognizes it as native and loads the named agent's resources. Minimal: permissions ALONE suffices (mcpServers/toolsSettings without it still warn); the field is backward-compatible (v2 runs clean). Applied to run.sh deploy_agent inline JSON (the real generator) + adapters/kiro-cli.yaml template. Proven: A4+A5 pass on the full v3 path (engine v3 + stream-json); v2 unchanged. Note: A4 on v3 WITHOUT stream-json still fails at the log_check stage = ticket 124's known limit (text grading passes). Separate observation (not fixed): A3 doesn't finish on v3 within adapter timeout 90s (v3 slower cold start) — raise adapter timeout for v3 if v3 becomes the proof default.
