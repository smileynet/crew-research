---
id: "164"
title: "source-authority: disclosure-mandated fallback tiers (P3 ADD-TO)"
status: in_progress
blocked_by: []
spec: "rider-followups"
---

# source-authority: disclosure-mandated fallback tiers

## Intent source

Rider review, openai-docs + imagegen (SYNTHESIS pattern #6). Proposal:
`.scratch/new-skill-proposals-from-rider.md` P3. Those skills use a live→resolver→bundled-snapshot
fallback ladder and REQUIRE the skill to state which tier it used.

## What to build

Add a "Freshness fallback tiers" section to `atomics/skills/source-authority/SKILL.md`: when the
authoritative source is unreachable, fall back in a declared order (live fetch → cached/resolver
→ bundled snapshot) and DISCLOSE which tier was used + its date. Pair it with the existing
confidence labels (a bundled snapshot is at best "reported", never "verified"). Prevents citing a
stale cached copy as if it were live docs.

## Acceptance criteria

- [x] `source-authority` gains a "Freshness fallback tiers" section (ordered ladder + mandatory disclosure of tier + date)
- [x] Tiers mapped to the existing confidence labels (snapshot ≠ verified)
- [x] Names the environments where it matters (offline, corp proxy, Bedrock)
- [x] `mise run validate` + `mise run lint` pass; section stays inline (success-path guidance, per 151 G4d)

## Out of scope

- Building a fetch tool (that's script-authoring / ticket 165 territory)
