# Archwright Survey: tkt (ticket CLI) — area-scoped run in crew-research

Run date: 2026-07-20. Target: the `tkt` tool (greenfield, will live at `tools/tkt/`).
This is an AREA run, not a full crew-research survey — scoped to ticket 40's build per
operator directive ("run archwright pipeline for tkt first").

## Domain

**general** — fallback rule (CLI tool; no game/web triggers). Per
`references/domains/detect.yaml` note: "CLI tools, libraries, pipelines" ⇒ general.

## Stack

**python** (decided in ticket 38 spike, pre-code) — **NOT in
`references/stacks/REGISTRY.yaml`** ⇒ Extension Protocol gap, pending-with-reason:

> Missing: `python` stack adapter rows (trace_emitter / ast_grammar / check_patterns).
> Unblocks: trace validation of tkt behavior specs, structural constraint checks on
> tkt source (grep fallback available meanwhile). Also unblocks checks on `tools/recall`
> (existing Python). Registration belongs in the archwright repo per its Extension
> Protocol (new INSTANCE of existing kind — no ADR needed; needs conformance corpus
> incl. one violating scenario).

Consequence: derive-phase constraint specs use **grep/script methods** (stack-agnostic);
behavior-spec trace checks will be `target_status: pending` until the adapter exists.

## Run Scope

Single area (tkt), one pipeline run. Artifacts commit to current branch (`main`).
`design/` does not exist yet — created by this run. No discovery artifacts (`design/discovery/`) exist; the ticket-38 spike functions as the discovery input and its
decisions arrive at resolve as pre-resolved.

## Destination

"Fully covered" for tkt = spike decisions formalized as patterns with force provenance;
a model of the ticket-file lifecycle state machine and the tool's actors; the frontmatter
contract as machine-checkable contract specs; constraint/behavior specs derived so that
`archwright-check --static` can gate the ticket-40 implementation from its first commit;
check integration noted in ticket 40's ACs.

## Source Quality

| Source | Present? | Richness |
|--------|----------|----------|
| README / product purpose | ✓ (ticket 40 What-to-build + spec header) | rich |
| Vision or roadmap | ✓ (tickets 40/41 phasing, COULDs R14–R16) | rich |
| Tenets / design principles | ✓ (spec UX constraints: files-are-the-DB, ceremony-decays, body-is-the-spec) | rich |
| ADRs | ○ (crew ADRs adjacent: 0007 purpose-built precedent, 0008 extensions) | thin for tkt itself |
| Grills / decision records | ✓ (ticket 38 Resolution + spike evidence trail) | rich (verdict + rejected alternatives + incident evidence) |
| Feature specs / requirements | ✓ (`.memory/specs/ticket-cli-spec.md` — R1–R16 MoSCoW + contract) | rich |
| Conventions (AGENTS.md, glossary) | ✓ (Ticket/Frontier/CREW_ENV glossary terms; validation contract) | rich |

**Mode prediction: formalization run.** Forces are latent in the spike outputs —
extraction is reading, not asking. Expect few HITL stops; resolve should be almost
entirely a batched pre-resolved confirmation.

Raw evidence corpus (regenerable): `.scratch/research/crew-ticket-needs.md`,
`archwright-ticket-needs.md`, `tk-capabilities.md`.

## Known Contradictions (audit pass, step 1b)

Docs are hours old, single-author, no implementation to contradict. One planned
divergence to track (not a lie): frontier-work steering documents the MANUAL protocol
(awk scan, claim commits, `open|done` only) while the spec adds `in_progress` and tool
commands — reconciliation is ticket 41's job. HIGH-severity: none. Force extraction
unblocked.

## Coverage Map

| Area | Forces | Tensions | Resolution | Pattern | Model | Contracts | Specs | Checks |
|------|--------|----------|-----------|---------|-------|-----------|-------|--------|
| A1 Frontmatter contract & parsing (ids-as-text, preservation, loud errors) | ○ implicit | ○ inferrable | ✓ decided (38) | ✗ | ✗ | ✗ | ✗ | ✗ |
| A2 Frontier computation (blocked_by + env + priority) | ○ implicit | ○ inferrable | ✓ decided (38) | ✗ | ✗ | ✗ | ✗ | ✗ |
| A3 Allocation & claim (git-coordinated new/claim) | ○ implicit | ○ inferrable | ✓ decided (38) | ✗ | ✗ | ✗ | ✗ | ✗ |
| A4 Lifecycle transitions (claim/close, resolution stub, AC warnings) | ○ implicit | ○ inferrable | ✓ decided (38) | ✗ | ✗ | ✗ | ✗ | ✗ |
| A5 Validation command (schema, dangling/cyclic refs) | ○ implicit | ○ inferrable | ✓ decided (38) | ✗ | ✗ | ✗ | ✗ | ✗ |
| A6 Query & output (JSON, validation contract) | ○ implicit | ○ inferrable | ✓ decided (38) | ✗ | ✗ | ✗ | ✗ | ✗ |
| A7 Distribution & install (uv tool, extension question) | ○ implicit | ○ inferrable | ○ partial (extension decision deferred to 41) | ✗ | ✗ | ✗ | ✗ | ✗ |

## Dispatch Queue (dependency order)

1. `archwright-forces` — extract from ticket 38 Resolution, spec, extraction corpus, glossary (AFK)
2. `archwright-tensions` — cluster; most arrive pre-resolved via spike (AFK)
3. `archwright-resolve` — batched confirmation of pre-resolved tensions + any open ones (**HITL gate**; known open item: A7 extension-vs-documented-install, may stay deferred)
4. `archwright-formalize` — patterns from confirmed resolutions (AFK)
5. `archwright-model` — ticket-file lifecycle FSM + tool actor map (AFK — never skip)
6. `archwright-contract` — frontmatter contract as typed contract specs (AFK)
7. `archwright-derive` — constraint/behavior specs, grep/script methods per stack gap (AFK)
8. `archwright-check --static` — spec validation pre-code; full checks activate with ticket 40's implementation (AFK)

## Already Complete

Nothing formalized yet (greenfield). Decisions themselves are complete for MVP scope:
ticket 38's four spike questions all have ratified answers with evidence.

## Fog (cannot yet specify)

- A7's extension-registration question — deliberately deferred to ticket 41 (not fog
  encountered mid-span; pre-declared). If resolve wants to settle it early, it's the one
  genuinely open tension.
- Python stack adapter absent — declared pending above; limits check KINDS, not spec
  authoring.
