---
id: "126"
title: "Add v3-engine invocation path to proof/eval harness when non-TUI v3 ships"
status: backlog
blocked_by: ["125"]
tags: ["kiro-v3"]
---

# Add v3-engine invocation path to proof/eval harness when non-TUI v3 ships

## Context

Ticket 125 confirmed empirically (kiro-cli 2.19.2) that the **v3 engine cannot run headless** on the current build:
- `--agent-engine v3 -a` → fails fast (v3 rejects `--trust-all-tools`; uses capability model)
- `--agent-engine v3` (no `-a`) → hangs (v3/KAS forwards `session/new` to the TUI; no non-TUI path)
- kiro.dev v3 "Known Gaps" confirms: "legacy non-TUI mode does not support the v3 engine. Use the TUI."

So tickets 124/125 standardize on `--agent-engine v2`. This ticket tracks the FUTURE work of adding a v3 path once kiro ships a non-TUI v3 mode.

## Trigger to activate (move off backlog)

When a kiro-cli release notes entry announces non-TUI/headless support for the v3 engine, OR when v3 becomes the default and v2 is deprecated.

## What to build (when unblocked)

- v3 trust setup for headless: capability-based `permissions.yaml` (allow-all for CI) via a **workspace-isolated `KIRO_HOME`** (NOT user-global — a user-global allow-all weakens interactive-session trust prompts; see 125 disruption analysis)
- Adapter flag: engine selector in `adapters/kiro-cli.yaml` (v2 default, v3 opt-in)
- Re-test the stream-json event schema on v3 (may differ from v2's ACP v1 shape)
- Verify no regression to v2 path

## Acceptance criteria

- [ ] v3 non-TUI headless confirmed available in a kiro-cli release (cite version)
- [ ] Harness can invoke v3 with workspace-scoped permissions.yaml (no user-global trust change)
- [ ] v3 stream-json schema documented (delta vs v2 ACP v1)
- [ ] v2 path unchanged (no regression)
