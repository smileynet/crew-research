# Q03 — Ticket 34: cadence/trigger + proposal artifact

**Status:** RESOLVED 2026-07-19

## Decision (user)

**Manual mise task to start.** Architecture must consider how daily AND weekly tasks could pair later.

## Paired-cadence design (recorded for ticket 34)

The daily/weekly pairing maps onto the ticket's existing cheap-prefilter / LLM-synthesis split:

| Layer | Cadence (future) | Cost | Does |
|-------|------------------|------|------|
| **Collect** | daily | cheap (heuristics, no/minimal LLM) | pattern-match candidate sessions (correction phrasings, error/retry bursts, repeated commands) → append to a rolling candidate queue |
| **Synthesize** | weekly | expensive (LLM), batched | probe queued candidates, dedupe repeated signals across the week, emit ONE digest with proposals routed project-local vs crew-research-global |

- **Now:** one manual task (`mise run session:probe` or similar) runs collect+synthesize end-to-end on demand — this is also the spike vehicle
- **Graduation path:** split the two layers onto cron only after the spike proves detection precision; weekly synthesis batching is what keeps LLM cost bounded and dedupes noise
- **Artifact:** digest file, human triages; tickets are only ever created by the human reviewing the digest, never by the pipeline (propose-don't-apply, same contract as /guidance-sync)

## Why not immediately scheduled

Detection precision unknown (spike pending); cron on this machine was patched for a crash literally today (651f54a); unreviewed auto-findings rot.
