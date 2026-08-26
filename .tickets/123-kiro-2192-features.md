---
id: "123"
title: "Review kiro-cli 2.19.2 features for project use"
status: open
blocked_by: []
spec: "Evaluate stream-json output and local image attachment for eval harness, proofs, and workflows"
priority: high
---

# Review kiro-cli 2.19.2 features for project use

## New Features (kiro-cli 2.19.2)

### 1. `--output-format stream-json` (non-interactive mode)

Emits run events as JSON Lines on stdout. Requires v2 or v3 engine.

Potential project uses:
- **Eval harness** — structured event stream instead of parsing terminal output
- **Proof harness** — machine-readable assertions on agent behavior
- **Session analysis** — richer data than transcript parsing
- **CI integration** — programmatic pass/fail from event stream

### 2. Image path attachment in local sessions

Image paths referenced in prompts now attach images locally (previously cloud-only).

Potential project uses:
- **Visual validation** — local image review without cloud roundtrip
- **Multi-agent validation skill** — image dispatch works locally now
- **Proof harness** — visual output verification in local runs
- Simplifies the image-handling steering (no longer cloud-only caveat)

## What to do

- Review each feature's actual behavior (read release notes, test locally)
- Identify which project systems benefit most
- Prototype highest-value integration (likely stream-json for eval harness)
- Update steering/skills if capabilities change workflows (image-handling.md especially)

## Acceptance criteria

- [ ] Both features tested locally and behavior documented
- [ ] Impact assessment: which scripts/skills/steering benefit
- [ ] At least one integration prototype (eval or proof harness with stream-json)
- [ ] image-handling steering updated if local attachment changes guidance
