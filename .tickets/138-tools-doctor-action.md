---
id: "138"
title: "Implement tools:doctor runtime health/audit action"
status: done
blocked_by: ["137"]
---

# Implement tools:doctor runtime health/audit action

## What to build

TBD

## Acceptance criteria

- [x] TBD

## Resolution (2026-08-30)

tools:doctor action: runs recall health --json + recall status, tkt doctor -o json + tkt audit --brief + tkt validate --brief. jq-optional summary (degrades gracefully when jq is Windows-side/absent). Verified via WSL interop: recall shows total_chunks=48505, tkt shows real audit/validate findings; Errors:0 Warnings:0 footer, exit 0.
