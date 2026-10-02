---
id: "174"
title: "Ship SessionStart->recall prime hook (global, opt-in with recall) to replace recall-session-start steering"
status: open
blocked_by: ["173"]
tags: [kiro-v3]
---

# SessionStart → `recall prime` hook

## Why

crew-research ships a `recall-session-start` STEERING file that *instructs* the model
to run `recall prime` at session start — an instruction the model can silently skip
(the exact failure the steering tries to prevent). A `SessionStart` command hook does
it DETERMINISTICALLY at zero context/credit cost, and no-ops cleanly without recall.

## Config (verified shape, kiro.dev/docs/hooks)

`~/.kiro/hooks/crew-recall-prime.json`:
```json
{
  "version": "v1",
  "hooks": [
    { "name": "recall-prime-on-start", "trigger": "SessionStart",
      "action": { "type": "command",
        "command": "command -v recall >/dev/null 2>&1 && recall prime 2>/dev/null || true" },
      "timeout": 15 }
  ]
}
```
command action: exit 0 → stdout added to agent context (recall prime emits recent
facts + top results — exactly right). No credits, fast.

## Open decisions (resolve during build)

- **Headless subagent spawns:** `SessionStart` fires for EVERY dispatched
  `--no-interactive` subagent too — `recall prime` on each spawn is wasted latency.
  Decide: suppress for headless (how? env check), or accept the cost.
- **Replace vs coexist with steering:** if the hook ships, retire or thin the
  `recall-session-start` steering to avoid double-priming (and deprecate per deprecated.yaml).
- Opt-in with the recall extension; respect `--skip-extension recall`.

## Acceptance criteria

- [ ] Hook deployed via the hooks class (ticket 173), opt-in with recall, `--skip-extension` honored
- [ ] No-op without recall (guarded); v2 no-op
- [ ] Headless-subagent behavior decided + documented
- [ ] `recall-session-start` steering retired or thinned to avoid double-prime (deprecated.yaml if removed)
- [ ] Verified: a fresh session primes recall deterministically (vs the skippable steering)
