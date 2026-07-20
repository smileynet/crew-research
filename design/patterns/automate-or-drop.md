---
kind: pattern
id: automate-or-drop
name: "Automate or Drop: No Unowned Ceremony"
scale: premise
confidence: "★★"
status: active
serves: [pf-tickets-as-history]
context: [intersection-contract]
completed_by: []
resolves_into:
  - "constraint:validate-reports-decay"
---

# Automate or Drop: No Unowned Ceremony

## Problem

**Trustworthy history wants rich metadata, but every metadata convention not enforced by tooling has demonstrably rotted in both repos.**

## Context

In the context of `intersection-contract`, this pattern governs what may enter the contract and who maintains each field.

## Forces

- **Desire:** Done tickets serve as trustworthy project archaeology (pf-tickets-as-history).
- **Constraint (hard):** Metadata not maintained by tooling decays and cannot be relied on (ceremony-decays).
- **Constraint (hard):** The body is prose the tool may only append to, never restructure (body-is-prose).

## Evidence

- Empirical decay, archwright: `created:` appears only on tickets 001–016, `closed:` only on 008–010 — both conventions died within days of birth; ~14 done tickets carry unchecked acceptance boxes while close-out prose carries the truth (arch extraction §1–2).
- Empirical decay, crew: 9 done tickets have unchecked AC boxes (crew extraction §4). Two independent repos, same rot pattern — the mechanism is structural (unowned ceremony has no feedback loop), not a discipline failure of one team.
- Design warning from the extraction: "ceremony beyond frontmatter + one close-out section will decay" (arch extraction §5).
- Rejected alternative — more convention/discipline: the decayed fields WERE the convention; repeating Level 4 enforcement against an observed Level 4 failure contradicts enforcement-hierarchy.
- Prior art (2026-07-20, `.scratch/research/prior-art-selection-decay.md`): the decay observation is among the best-replicated findings in empirical SE — comment/code co-evolution failure across 1,500 systems (Wen et al. 2019), 9.6M-link decay study (Hata et al. 2019), self-admitted aging debt in 21%+ of 9K repos (2025). The prescriptive arm is industry practice: data-catalog drift prevention names automation + ownership models (Atlan 2026); linter-adoption research shows mechanized enforcement beats written convention (ESLint study 2018); SRE toil doctrine (Google 2020). Novel tail on record: the mandatory DROP of unowned fields goes beyond published prior art (no source opposes it; none mandates it).

## Therefore

**Every contract field has a named owner, or it isn't in the contract.** Owner is one of: (a) the TOOL — set and maintained by a command (`status` via new/claim/close; dated Resolution stub appended on close); (b) the OPERATOR with VALIDATE as the feedback loop — hand-set but mechanically watched (`blocked_by` dangling/cycle checks; unchecked-ACs-on-done reported as findings); (c) nothing — the field is dropped from the contract (as `created:`/`closed:` are: passthrough-preserved but never required or interpreted). Ceremony with no owner is not added, however appealing.

## Consequences

- Adding a contract field now requires answering "which command maintains it, or which validate rule watches it?" — a design gate on contract growth.
- Validate findings are advisory (exit facts, not blocks) for prose-adjacent decay (unchecked ACs) — the tool surfaces, humans judge (Level 3 stays human).
- Does NOT cover: prose QUALITY (evidence richness in Resolution sections is judgment, never lintable).

## Verification

- Constraint spec `validate-reports-decay`: `tkt validate` implementation contains detections for unchecked-ACs-on-done and dangling blocked_by (the two observed decay classes).
- Heuristic (★-level) review criterion at contract changes: the owner question is answered in the change description.

## Completion

This pattern is incomplete unless it also contains:
- Nothing further — it is a governor, completed by the contract it governs.
