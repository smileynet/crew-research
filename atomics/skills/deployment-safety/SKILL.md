---
name: deployment-safety
description: "Safe deployment practices including rollback planning, canary patterns, and pre/post verification. Use when deploying, provisioning infrastructure, or executing any operation that changes production state."
metadata:
  type: protocol
  invocation: both
  practice: null
---

# Deployment Safety

## Pre-Deploy Checklist
1. **Rollback plan exists** — how to undo this if it fails?
2. **Dependencies ready** — downstream services, databases, configs in place?
3. **Tests pass** — build + test green before deploy
4. **Change scope known** — what exactly will change? (plan/diff output)

## Deploy Sequence
1. Verify preconditions (checklist above)
2. Execute in smallest possible increment
3. Verify health immediately after
4. Monitor for 5 minutes before declaring success

## Rollback Triggers (stop and revert immediately)
- Health check fails after deploy
- Error rate increases >2x baseline
- Latency increases >3x baseline
- Any data integrity concern

## Canary Pattern (when available)
- Deploy to 1 instance/region first
- Verify health for 5+ minutes
- Only then proceed to full rollout
- If canary fails → rollback, do NOT proceed

## Destructive Operations (extra caution)
- `terraform destroy`, `drop table`, `rm -rf`, scale-to-zero
- ALWAYS require explicit confirmation before executing
- ALWAYS verify the target (wrong environment = catastrophe)
- ALWAYS have a recovery path documented before executing

## Post-Deploy Verification
- Health endpoints responding
- Key user flows working (smoke test)
- No new errors in logs
- Resource counts match expected

## Anti-Patterns
- "Deploy and pray" — no verification after deploy
- "Fix forward" on data corruption — rollback first, investigate second
- Deploying on Friday afternoon
- Skipping canary because "it's a small change"
