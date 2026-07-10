# PoC File Organization

## Layout

```
project/
├── proposal-plan.md             # THE MAP — living index (destination, decisions, fog, scope)
├── README.md                    # Usage instructions (created last)
├── .memory/                     # Durable reference (tracked)
│   ├── CONTEXT.md               # Project glossary
│   ├── decisions.md             # Architecture decisions with rationale
│   ├── requirements.md          # Customer/project requirements
│   ├── research-synthesis.md    # Synthesized research findings
│   ├── spike-N-findings.md      # Per-spike results
│   ├── grill/                   # Grill session outputs
│   │   └── {topic}/INDEX.md     # Per-topic grill with question files
│   └── adr/                     # Hard-to-reverse decisions only
├── .scratch/                    # Ephemeral research (gitignored)
│   └── research/                # Raw research before synthesis
├── docs/
│   └── specs/                   # Feature specs (if needed)
├── infra/                       # Infrastructure as code
└── src/                         # Application code
```

## The Map (proposal-plan.md)

The map is the single orientation document. Load it at session start.

```markdown
## Destination
<what "done" looks like — one or two lines>

## Decisions so far
- [Decision name] — one-line gist (detail: .memory/decisions.md or .memory/grill/{topic}/)

## Active work
- [ ] Current task/spike and what it resolves

## Fog (not yet specified)
- Suspected decisions not yet sharp enough to act on

## Out of scope
- What this PoC does NOT prove (and why)
```

**Rules:**
- Map is an INDEX — it links, doesn't restate
- Decisions live in `.memory/decisions.md` (one place only)
- Update the map after every resolved decision
- Fog graduates to active work when it's sharp enough to act on
- Out of scope never graduates (unless destination changes)

## Placement Rules

| Content | Location | Tracked? |
|---------|----------|----------|
| Living index/map | `proposal-plan.md` (root) | Yes |
| Architecture decisions | `.memory/decisions.md` | Yes |
| Requirements | `.memory/requirements.md` | Yes |
| Research synthesis | `.memory/research-synthesis.md` | Yes |
| Spike findings | `.memory/spike-N-findings.md` | Yes |
| Grill sessions | `.memory/grill/{topic}/` | Yes |
| Raw research output | `.scratch/research/` | No |
| Hard-to-reverse decisions | `.memory/adr/NNN-title.md` | Yes |
| Feature specs | `docs/specs/` | Yes |
| Glossary | `.memory/CONTEXT.md` | Yes |

## ADR Criteria

Create an ADR when ALL THREE are true:
- Hard to reverse
- Surprising without context
- Has a real trade-off (rejected alternatives exist)

Otherwise → `.memory/decisions.md`

## Commit Convention

```
type(scope): description

Types: feat, fix, docs, refactor, spike
Scope: research, design, plan, build, validate
```
