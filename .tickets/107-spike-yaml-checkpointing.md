---
id: "107"
title: "Spike: structured YAML checkpointing at phase boundaries for true resume"
status: open
blocked_by: []
env: either
priority: normal
---

# Spike: Structured YAML Checkpointing

## Hypothesis

Emitting a machine-readable YAML checkpoint at phase boundaries (not prose HANDOFF.md)
enables true session resume: a new session reads the checkpoint and knows EXACTLY where
to continue, what's done, what's pending, and what constraints are active — without
re-discovering state from handoff prose.

Inspired by mastra's durable workflow checkpointing (schema-validated suspend/resume).

## Baseline

- Current: `.scratch/HANDOFF.md` is prose — human-readable but machine-ambiguous.
  "Current State: deployed locally" doesn't tell the next session which step to execute.
- Problem: `read-handoff` works by having the agent READ prose and infer state.
  Ambiguity means re-work or missed steps.

## Spike design

```yaml
# .scratch/CHECKPOINT.yaml
schema: crew-checkpoint/v1
timestamp: 2026-08-14T09:30:00Z
phase: implementation
objective: "Build skill import protocol tooling"

completed:
  - id: schema
    description: "SKILL_MANIFEST.yaml JSON Schema"
    artifact: tools/plugin/schemas/skill-manifest.schema.yaml
  - id: validate
    description: "validate-plugin.sh"
    artifact: tools/plugin/validate-plugin.sh

pending:
  - id: doctor-integration
    description: "Integrate check-freshness into doctor.sh"
    blocked_by: ["external-repos-adopt-manifests"]
  - id: init-auto-deploy
    description: "Auto-run deploy-skills.sh in init.sh"

constraints:
  - "Skills format must stay Agent Skills compliant"
  - "No network calls in validation scripts"

decisions:
  - "Floor-only semver compat (VS Code engines pattern)"
  - "Symlink default, copy fallback for Windows"

fog:
  - "Whether cargo-dist handles the ONNX static-link"
```

**Integration:**
- `handoff` skill emits BOTH HANDOFF.md (human) and CHECKPOINT.yaml (machine)
- `read-handoff` reads CHECKPOINT.yaml first (structured) → HANDOFF.md for color
- CHECKPOINT.yaml is gitignored (ephemeral, like HANDOFF.md)

## Validation criteria

- [ ] Schema defined and documented
- [ ] handoff skill updated to emit CHECKPOINT.yaml alongside HANDOFF.md
- [ ] read-handoff skill reads CHECKPOINT.yaml and correctly identifies next step
- [ ] Resume accuracy: agent picks up at the right pending item ≥90% of the time
- [ ] Backward compatible: works without CHECKPOINT.yaml (falls back to HANDOFF.md only)

## Reject if

- Agents ignore the structured checkpoint and re-read HANDOFF.md anyway
- Schema becomes a maintenance burden (too rigid for varied task shapes)
- Checkpoint writing slows down the handoff process significantly

## References

- Mastra durable workflows: `.references/mastra/packages/core/src/agent/durable/`
- Research: `.scratch/research/overlap-workflows.md`
- Current handoff skill: `~/.kiro/skills/handoff/SKILL.md`
