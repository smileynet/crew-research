---
id: "144"
title: "Machine-wide tool enable/disable map under the CREW_ENV floor — supersedes 142/143"
status: in_progress
blocked_by: []
validation_criteria:
  - "a machine-wide config enables/disables each tool/harness, one shared reader applies the CREW_ENV policy floor (stage 1, deny-wins) then the enable-map (stage 2), the harnesses consume it, and a disabled / unavailable / policy-blocked tool each degrades as a reported gap with a DISTINCT reason"
tags: ["kiro-v3"]
---

# Machine-wide tool enable/disable map under the CREW_ENV floor

## Intent source

Session review 2026-08-30. Tickets 142/143 each added a reviewer leg by editing
code; that doesn't scale across tools. **Simplified 2026-08-31 (user decision):**
drop the per-JOB axis — make it a flat **machine-wide `tool → enabled|disabled`
map** read by every harness, NOT a per-(job×tool) matrix. One list; a tool disabled
here is disabled everywhere (eval, judge, review, proof).

## Design decision (ADR-not-pipeline)

The simplification removes the granularity tension (per-job DRY vs control) that
drove the design-gate. What remains is one durable invariant — the config sits UNDER
the CREW_ENV floor and cannot widen it — captured in **ADR 0011**. Composes with the
existing ★★ `layered-selection` pattern (staged filter → default; policy floor is an
unbreakable Stage 1). No full archwright pipeline.

Prior-art + code-review artifacts: `.scratch/research/t144/`, `.scratch/review/t144/`.
Forces: `design/forces/pf-per-job-tool-selection.md`, `single-selection-reader.md`,
existing `pf-env-policy.md`.

## Precedence (deny-wins, staged — like layered-selection)

1. **Stage 1 — CREW_ENV floor (hard):** `CREW_ENV=corp` → agy is `policy-blocked`,
   checked BEFORE the enable-map and BEFORE `command -v`. The map CANNOT re-enable it.
2. **Stage 2 — enable-map:** `harness-tools.yaml` `tools.<name>.enabled: true|false`
   (default-off for unlisted; known tools listed enabled). Disabled → `disabled` gap.
3. **Stage 3 — availability:** `command -v <tool>` → `unavailable` gap if absent.

Three DISTINCT reasons: `policy-blocked (CREW_ENV=corp)` / `disabled` / `unavailable`
— never shared code path or count (degrade-semantics research).

**Honesty:** the floor is convention + the harness checks + doctor/prune, NOT an
OS-level lock (steering/config is user-editable by design). ADR 0011 states this.

## What to build

1. **ADR 0011** — enable-map + floor precedence + single shared reader + convention-not-lock.
2. `compositions/harness-tools.yaml` — flat `tools.<name>.enabled` map (YAML, yq-parsed,
   matches repo plane split; NOT `.mise.local.toml`).
3. `tools/lib/harness-selection.sh` — ONE shared reader: `tool_verdict <tool>` →
   `enabled` | `policy-blocked` | `disabled` | `unavailable`, canonical reason strings,
   callable before `command -v`; exposes CREW_ENV unset state.
4. Re-point `matrix.sh` to the reader (replace inline CREW_ENV/POLICY_BLOCKED; add
   `disabled` as a gap distinct from `policy-blocked`).
5. Re-point the other clean CREW_ENV sites (eval run.sh ×2, run-proof.sh) to the reader;
   fix doctor.sh reason-string drift (`POLICY VIOLATION…` → canonical) — verified drift.

## Acceptance criteria

- [ ] `compositions/harness-tools.yaml` machine-wide `tools.<name>.enabled` map (YAML)
- [ ] ADR 0011 documents enable-map + CREW_ENV floor precedence (deny-wins stage 1, map cannot widen) + convention-not-lock honesty
- [ ] ONE shared reader `tools/lib/harness-selection.sh` applies floor(stage1) → enable-map(stage2) → availability(stage3); callable before `command -v`; canonical reason strings
- [ ] `disabled` / `unavailable` / `policy-blocked` each degrade as a reported gap with a DISTINCT reason
- [ ] matrix.sh consumes the reader (agy/claude/opencode legs honor enable-map + floor); dry-run regression green
- [ ] doctor.sh reason-string drift fixed to the canonical `policy-blocked (CREW_ENV=corp)`
- [ ] shellcheck + bash -n + `mise run validate` clean

## Relationship to other tickets

- **Supersedes 142/143:** agy/claude are now enable-map entries; disabling a reviewer
  is a config edit. Their matrix.sh legs already honor the floor — this generalizes it.
- Composes with ADR 0006 (`.mise.local.toml` machine plane — distinct axis), ADR 0010
  (judge panel degrade stamping — reasons must not contradict), ticket 36 (the floor).

## Out of scope

- Per-JOB tool selection (dropped by the 2026-08-31 simplification — machine-wide only)
- Changing CREW_ENV policy semantics (layers under it)
- Migrating run-proof.sh's hardcoded model ids (only its CREW_ENV check moves to the reader)
