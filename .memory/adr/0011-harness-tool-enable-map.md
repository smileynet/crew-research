---
type: adr
title: "Machine-wide tool enable-map layered under a deny-wins CREW_ENV floor, applied by one shared reader"
---

# ADR 0011 — Harness Tool Selection: Enable-Map Under the CREW_ENV Floor

**Date:** 2026-08-31
**Status:** Accepted (operator decision)
**Context ticket:** 144 (supersedes the reviewer-leg hard-coding of 142/143)

## Decision

A single machine-wide config declares which tools/harnesses are enabled; one shared
reader resolves a tool's participation for every harness (eval, judge, dispatch-review,
proof) by applying three ordered stages:

1. **Stage 1 — CREW_ENV policy floor (hard, deny-wins).** `CREW_ENV=corp` →
   `agy` is `policy-blocked`. Evaluated FIRST and BEFORE `command -v`. The enable-map
   below CANNOT re-enable a tool the floor blocks. (Ticket 36 invariant.)
2. **Stage 2 — enable-map.** `compositions/harness-tools.yaml`
   `tools.<name>.enabled: true|false`. A tool absent from the map or `enabled: false`
   → `disabled`. Known tools are listed `enabled: true`.
3. **Stage 3 — availability.** `command -v <tool>` → `unavailable` if not on PATH.

The reader returns a structured verdict with one of four states —
`enabled` / `policy-blocked` / `disabled` / `unavailable` — and a canonical reason
string. These are DISTINCT: they never share a code path or a coverage count. A
non-`enabled` leg degrades the job as a REPORTED gap, never a silent pass and (for a
multi-leg job) never a hard failure.

Config is **machine-wide, not per-job** (operator simplification 2026-08-31): a tool
disabled here is disabled across all harnesses. The per-(job × tool) matrix was
considered and dropped — see Rejected Alternatives.

## Why

- **One reader, not six checks.** The corp/agy conditional was duplicated in 6 code
  locations across 5 files (init.sh, doctor.sh, run-proof.sh, eval run.sh ×2,
  matrix.sh), and the duplication had already drifted — doctor.sh emitted
  `POLICY VIOLATION … forbidden on corp machines` while the other five used the
  canonical `policy-blocked (CREW_ENV=corp)` (verified 2026-08-31). Prior art on
  job/tool registries (GitHub Actions matrix, Spring strategy+registry) is unanimous:
  selection lives in one schema with one reader; the growing per-consumer `switch` is
  the documented anti-pattern.
- **Deny-wins floor, applied first.** The universal precedence rule across IAM/firewall
  systems is "explicit deny overrides any allow," order-independent. Modeling the floor
  as Stage 1 makes it structurally impossible for a lower layer to widen it — the
  enable-map can only *further* restrict. This mirrors the in-repo ★★ `layered-selection`
  pattern (frontier selection: eligibility filter → priority → order), where env
  exclusion is likewise an unbreakable first stage.
- **Reason as a first-class field.** Collapsing `disabled` (operator choice),
  `policy-blocked` (governance), and `unavailable` (meant-to-run, couldn't) into one
  status word is exactly how coverage is lost silently. Keeping them distinct — with the
  aggregate refusing "clean" when a meant-to-run leg is `unavailable` — is the
  cross-industry degradation lesson.

## Honesty: the floor is convention, not an OS lock

Industry hard floors (Snowflake CoCo, Copilot Enterprise) rely on a system-owned path
users cannot write, deployed via MDM. crew-research's steering, skills, and config are
**user-editable by design** — so this floor is enforced by the shared reader + the
harness checks + doctor's flag/prune, NOT a mechanical lock. A determined hand-edit can
bypass it (the same as today). It is still meaningfully enforced (every harness consults
the reader; doctor flags corp agy artifacts), but this ADR states plainly that it is a
convention backed by checks, not a kernel-level guarantee.

## Rejected alternatives

- **Per-(job × tool) matrix.** The original ticket 144 shape: `jobs.{eval,judge,review}.tools: [...]`.
  Rejected on simplification (operator, 2026-08-31): it introduced a granularity-vs-DRY
  tension (every job re-declaring the same tool list) for expressive power nothing
  currently needs. A flat machine-wide map removes the tension entirely. Revisit trigger:
  a concrete need to run a tool in one job but not another on the same machine.
- **Denylist / default-on.** Rejected: fails *open* — an unlisted or newly-added tool
  silently participates, making the floor the load-bearing single guard. The enable-map
  is default-off (unlisted = disabled), failing in the SAME direction as the floor
  (fewer participants, visible). Known tools are explicitly listed enabled.
- **`.mise.local.toml` as the config home.** Rejected: it is gitignored (can't be shared
  project config) and TOML is the mise/tkt-native plane. crew-authored, yq-parsed config
  is YAML in `compositions/` by repo convention (tiers, known-tools, adapters). The
  enable-map joins that plane as `compositions/harness-tools.yaml`.

## Consequences

- Adding/removing a reviewer (142/143's agy, claude) or any harness tool is now a config
  edit, not a code change — this is what supersedes the 142/143 hard-coding.
- The six enforcement sites re-point to the reader; doctor.sh's drifted string is
  corrected in the same change. `tools/evals/judges/default.yaml` stays declarative
  (models only); its ADR 0010 family/panel-floor degrade stamping composes with — does
  not conflict with — the reader's reason states.
- **Open gap:** `run-proof.sh` hardcodes per-tool model ids; only its CREW_ENV check
  moves to the reader here. Externalizing its model roster is out of scope (future ticket).
- A globally-disabled tool is absent from every harness; there is no per-job denominator
  math (the simplification removed it).
